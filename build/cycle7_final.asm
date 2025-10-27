; ==============================================================================
; Save System Data Tables and Checksum Validation - Final Systems
; ==============================================================================

; Save file data table pointers
DATA_00C8E3:
    db $A7,$8F,$03,$F2,$AA,$03,$55,$AB,$03,$AA,$92,$03,$14,$93,$03,$19 ;00C8E3|        |      ;
    db $93,$03,$1F,$93,$03,$28,$93,$03,$33,$93,$03,$3C,$93,$03,$42,$93 ;00C8F3|        |      ;
    db $03,$4B,$93,$03,$57,$93,$03,$60,$93,$03,$A9,$93,$03,$AE,$93,$03 ;00C903|        |      ;
    db $F7,$93,$03,$FC,$93,$03,$74,$94,$03,$79,$94,$03,$DD,$94,$03,$E2 ;00C913|        |      ;
    db $94,$03,$EA,$97,$03                                               ;00C923|        |      ;

; Save slot address calculation
    LDA.W $015F                          ;00C928|AD5F01  |00015F;

CODE_00C92B:
    AND.W #$00FF                         ;00C92B|29FF00  |      ;
    STA.B $98                            ;00C92E|8598    |000098;
    LDA.W #$038C                         ;00C930|A98C03  |      ;
    STA.B $9C                            ;00C933|859C    |00009C;
    JSL.L CODE_0096B3                    ;00C935|22B39600|0096B3;
    LDA.B $9E                            ;00C939|A59E    |00009E;
    CLC                                  ;00C93B|18      |      ;
    ADC.W #$0000                         ;00C93C|690000  |      ;
    STA.B $0B                            ;00C93F|850B    |00000B;
    RTS                                  ;00C941|60      |      ;

CODE_00C942:
    PHP                                  ;00C942|08      |      ;
    SEP #$20                             ;00C943|E220    |      ;
    REP #$10                             ;00C945|C210    |      ;
    PHA                                  ;00C947|48      |      ;
    LDA.B #$7F                           ;00C948|A97F    |      ;
    STA.B $61                            ;00C94A|8561    |000061;
    PLA                                  ;00C94C|68      |      ;
    PLP                                  ;00C94D|28      |      ;
    RTS                                  ;00C94E|60      |      ;

CODE_00C94F:
    PHP                                  ;00C94F|08      |      ;
    SEP #$20                             ;00C950|E220    |      ;
    REP #$10                             ;00C952|C210    |      ;
    PHA                                  ;00C954|48      |      ;
    LDA.B #$70                           ;00C955|A970    |      ;
    STA.B $61                            ;00C957|8561    |000061;
    PLA                                  ;00C959|68      |      ;
    PLP                                  ;00C95A|28      |      ;
    RTS                                  ;00C95B|60      |      ;

CODE_00C95C:
    PHA                                  ;00C95C|48      |      ;
    PHX                                  ;00C95D|DA      |      ;
    LDA.W #$4646                         ;00C95E|A94646  |      ;
    STA.B $0E                            ;00C961|850E    |00000E;
    LDA.W #$2130                         ;00C963|A93021  |      ;
    STA.B $10                            ;00C966|8510    |000010;
    LDX.W #$01C3                         ;00C968|A2C301  |      ;
    LDA.W #$0000                         ;00C96B|A90000  |      ;
    CLC                                  ;00C96E|18      |      ;

CODE_00C96F:
    ADC.B [$5F]                          ;00C96F|675F    |00005F;
    INC.B $5F                            ;00C971|E65F    |00005F;
    INC.B $5F                            ;00C973|E65F    |00005F;
    DEX                                  ;00C975|CA      |      ;
    BNE CODE_00C96F                      ;00C976|D0F7    |00C96F;
    STA.B $12                            ;00C978|8512    |000012;
    PLX                                  ;00C97A|FA      |      ;
    PLA                                  ;00C97B|68      |      ;
    RTS                                  ;00C97C|60      |      ;

CODE_00C97D:
    LDX.W #$0000                         ;00C97D|A20000  |      ;

CODE_00C980:
    LDA.B $0E,X                          ;00C980|B50E    |00000E;
    CMP.B [$0B]                          ;00C982|C70B    |00000B;
    BNE CODE_00C991                      ;00C984|D00B    |00C991;
    INC.B $0B                            ;00C986|E60B    |00000B;
    INC.B $0B                            ;00C988|E60B    |00000B;
    INX                                  ;00C98A|E8      |      ;
    INX                                  ;00C98B|E8      |      ;
    CPX.W #$0006                         ;00C98C|E00600  |      ;
    BNE CODE_00C980                      ;00C98F|D0EF    |00C980;

CODE_00C991:
    RTS                                  ;00C991|60      |      ;

CODE_00C992:
    PHB                                  ;00C992|8B      |      ;
    PHX                                  ;00C993|DA      |      ;
    PHY                                  ;00C994|5A      |      ;
    PHA                                  ;00C995|48      |      ;
    LDX.W #$3000                         ;00C996|A20030  |      ;
    STX.B $5F                            ;00C999|865F    |00005F;
    JSR.W CODE_00C942                    ;00C99B|2042C9  |00C942;
    JSR.W CODE_00C95C                    ;00C99E|205CC9  |00C95C;
    JSR.W CODE_00C92B                    ;00C9A1|202BC9  |00C92B;
    LDY.B $0B                            ;00C9A4|A40B    |00000B;
    LDX.W #$000E                         ;00C9A6|A20E00  |      ;
    LDA.W #$0005                         ;00C9A9|A90500  |      ;
    MVN $70,$00                          ;00C9AC|547000  |      ;
    STY.B $5F                            ;00C9AF|845F    |00005F;
    LDX.W #$3000                         ;00C9B1|A20030  |      ;
    LDA.W #$0385                         ;00C9B4|A98503  |      ;
    MVN $70,$7F                          ;00C9B7|54707F  |      ;
    LDA.B $12                            ;00C9BA|A512    |000012;
    JSR.W CODE_00C94F                    ;00C9BC|204FC9  |00C94F;
    JSR.W CODE_00C95C                    ;00C9BF|205CC9  |00C95C;
    CMP.B $12                            ;00C9C2|C512    |000012;
    BNE UNREACH_00C9CB                   ;00C9C4|D005    |00C9CB;
    JSR.W CODE_00C97D                    ;00C9C6|207DC9  |00C97D;
    BEQ CODE_00C9CE                      ;00C9C9|F003    |00C9CE;

UNREACH_00C9CB:
    db $68,$80,$C7                       ;00C9CB|        |      ;

CODE_00C9CE:
    PLA                                  ;00C9CE|68      |      ;
    PLY                                  ;00C9CF|7A      |      ;
    PLX                                  ;00C9D0|FA      |      ;
    PLB                                  ;00C9D1|AB      |      ;
    RTS                                  ;00C9D2|60      |      ;

CODE_00C9D3:
    PHP                                  ;00C9D3|08      |      ;
    REP #$30                             ;00C9D4|C230    |      ;
    PHB                                  ;00C9D6|8B      |      ;
    PHA                                  ;00C9D7|48      |      ;
    PHD                                  ;00C9D8|0B      |      ;
    PHX                                  ;00C9D9|DA      |      ;
    PHY                                  ;00C9DA|5A      |      ;
    PHA                                  ;00C9DB|48      |      ;
    STZ.B $8E                            ;00C9DC|648E    |00008E;
    PHB                                  ;00C9DE|8B      |      ;
    LDX.W #$1000                         ;00C9DF|A20010  |      ;
    LDY.W #$3000                         ;00C9E2|A00030  |      ;
    LDA.W #$004F                         ;00C9E5|A94F00  |      ;
    MVN $7F,$00                          ;00C9E8|547F00  |      ;
    LDX.W #$1080                         ;00C9EB|A28010  |      ;
    LDA.W #$004F                         ;00C9EE|A94F00  |      ;
    MVN $7F,$00                          ;00C9F1|547F00  |      ;
    LDX.W #$0E84                         ;00C9F4|A2840E  |      ;
    LDA.W #$017B                         ;00C9F7|A97B01  |      ;
    MVN $7F,$00                          ;00C9FA|547F00  |      ;
    PLB                                  ;00C9FD|AB      |      ;
    PLA                                  ;00C9FE|68      |      ;
    LDX.W #$0003                         ;00C9FF|A20300  |      ;

CODE_00CA02:
    JSR.W CODE_00C992                    ;00CA02|2092C9  |00C992;
    CLC                                  ;00CA05|18      |      ;
    ADC.W #$0003                         ;00CA06|690300  |      ;
    DEX                                  ;00CA09|CA      |      ;
    BNE CODE_00CA02                      ;00CA0A|D0F6    |00CA02;
    LDA.W #$FFF0                         ;00CA0C|A9F0FF  |      ;
    STA.B $8E                            ;00CA0F|858E    |00008E;
    JMP.W CODE_00981B                    ;00CA11|4C1B98  |00981B;

CODE_00CA14:
    PHX                                  ;00CA14|DA      |      ;
    PHY                                  ;00CA15|5A      |      ;
    PHA                                  ;00CA16|48      |      ;

CODE_00CA17:
    LDA.B $01,S                          ;00CA17|A301    |000001;
    JSR.W CODE_00C92B                    ;00CA19|202BC9  |00C92B;
    CLC                                  ;00CA1C|18      |      ;
    ADC.W #$0006                         ;00CA1D|690600  |      ;
    STA.B $5F                            ;00CA20|855F    |00005F;
    JSR.W CODE_00C94F                    ;00CA22|204FC9  |00C94F;
    JSR.W CODE_00C95C                    ;00CA25|205CC9  |00C95C;
    JSR.W CODE_00C97D                    ;00CA28|207DC9  |00C97D;
    BNE CODE_00CA54                      ;00CA2B|D027    |00CA54;
    LDA.B $01,S                          ;00CA2D|A301    |000001;
    JSR.W CODE_00C92B                    ;00CA2F|202BC9  |00C92B;
    CLC                                  ;00CA32|18      |      ;
    ADC.W #$0006                         ;00CA33|690600  |      ;
    TAX                                  ;00CA36|AA      |      ;
    LDY.W #$3000                         ;00CA37|A00030  |      ;
    LDA.W #$0385                         ;00CA3A|A98503  |      ;
    MVN $7F,$70                          ;00CA3D|547F70  |      ;
    LDA.B $12                            ;00CA40|A512    |000012;
    LDX.W #$3000                         ;00CA42|A20030  |      ;
    STX.B $5F                            ;00CA45|865F    |00005F;
    JSR.W CODE_00C942                    ;00CA47|2042C9  |00C942;
    JSR.W CODE_00C95C                    ;00CA4A|205CC9  |00C95C;
    CMP.B $12                            ;00CA4D|C512    |000012;
    BNE CODE_00CA17                      ;00CA4F|D0C6    |00CA17;
    CLC                                  ;00CA51|18      |      ;
    BRA CODE_00CA5F                      ;00CA52|800B    |00CA5F;

CODE_00CA54:
    LDA.B $01,S                          ;00CA54|A301    |000001;
    JSR.W CODE_00C92B                    ;00CA56|202BC9  |00C92B;
    LDA.W #$0000                         ;00CA59|A90000  |      ;
    STA.B [$0B]                          ;00CA5C|870B    |00000B;
    SEC                                  ;00CA5E|38      |      ;

CODE_00CA5F:
    PLA                                  ;00CA5F|68      |      ;
    PLY                                  ;00CA60|7A      |      ;
    PLX                                  ;00CA61|FA      |      ;
    RTS                                  ;00CA62|60      |      ;

CODE_00CA63:
    PEA.W LOOSE_OP_00CAB5                ;00CA63|F4B5CA  |00CAB5;
    PHP                                  ;00CA66|08      |      ;
    REP #$30                             ;00CA67|C230    |      ;
    PHB                                  ;00CA69|8B      |      ;
    PHA                                  ;00CA6A|48      |      ;
    PHD                                  ;00CA6B|0B      |      ;
    PHX                                  ;00CA6C|DA      |      ;
    PHY                                  ;00CA6D|5A      |      ;
    PHA                                  ;00CA6E|48      |      ;
    STZ.B $8E                            ;00CA6F|648E    |00008E;
    LDA.B $01,S                          ;00CA71|A301    |000001;
    LDX.W #$0003                         ;00CA73|A20300  |      ;

CODE_00CA76:
    JSR.W CODE_00CA14                    ;00CA76|2014CA  |00CA14;
    BCC CODE_00CA87                      ;00CA79|900C    |00CA87;
    ADC.W #$0002                         ;00CA7B|690200  |      ;
    DEX                                  ;00CA7E|CA      |      ;
    BNE CODE_00CA76                      ;00CA7F|D0F5    |00CA76;
    PLA                                  ;00CA81|68      |      ;
    LDA.W #$FFFF                         ;00CA82|A9FFFF  |      ;
    BRA CODE_00CAAC                      ;00CA85|8025    |00CAAC;

CODE_00CA87:
    LDX.W #$3000                         ;00CA87|A20030  |      ;
    LDY.W #$1000                         ;00CA8A|A00010  |      ;
    LDA.W #$004F                         ;00CA8D|A94F00  |      ;
    MVN $00,$7F                          ;00CA90|54007F  |      ;
    LDY.W #$1080                         ;00CA93|A08010  |      ;
    LDA.W #$004F                         ;00CA96|A94F00  |      ;
    MVN $00,$7F                          ;00CA99|54007F  |      ;
    LDY.W #$0E84                         ;00CA9C|A0840E  |      ;
    LDA.W #$017B                         ;00CA9F|A97B01  |      ;
    MVN $00,$7F                          ;00CAA2|54007F  |      ;
    PLA                                  ;00CAA5|68      |      ;
    JSR.W CODE_00C9D3                    ;00CAA6|20D3C9  |00C9D3;
    LDA.W #$0000                         ;00CAA9|A90000  |      ;

CODE_00CAAC:
    STA.B $64                            ;00CAAC|8564    |000064;
    LDA.W #$FFF0                         ;00CAAE|A9F0FF  |      ;
    STA.B $8E                            ;00CAB1|858E    |00008E;
    JMP.W CODE_00981B                    ;00CAB3|4C1B98  |00981B;

LOOSE_OP_00CAB5:
    LDA.B $64                            ;00CAB6|A564    |000064;
    RTS                                  ;00CAB8|60      |      ;

CODE_00CAB9:
    PHP                                  ;00CAB9|08      |      ;
    REP #$30                             ;00CABA|C230    |      ;
    PHB                                  ;00CABC|8B      |      ;
    PHA                                  ;00CABD|48      |      ;
    PHD                                  ;00CABE|0B      |      ;
    PHX                                  ;00CABF|DA      |      ;
    PHY                                  ;00CAC0|5A      |      ;
    LDA.W #$0000                         ;00CAC1|A90000  |      ;
    TCD                                  ;00CAC4|5B      |      ;
    SEP #$20                             ;00CAC5|E220    |      ;
    LDA.B #$01                           ;00CAC7|A901    |      ;
    AND.W $00DA                          ;00CAC9|2DDA00  |0000DA;
    BNE CODE_00CAEC                      ;00CACC|D01E    |00CAEC;
    LDA.B #$40                           ;00CACE|A940    |      ;
    AND.W $00DB                          ;00CAD0|2DDB00  |0000DB;
    BNE CODE_00CB07                      ;00CAD3|D032    |00CB07;
    LDX.W #$9300                         ;00CAD5|A20093  |      ;
    STX.W SNES_CGSWSEL                   ;00CAD8|8E3021  |002130;
    LDA.B #$02                           ;00CADB|A902    |      ;
    AND.W $00DA                          ;00CADD|2DDA00  |0000DA;
    BNE CODE_00CB11                      ;00CAE0|D02F    |00CB11;
    LDA.B #$80                           ;00CAE2|A980    |      ;
    AND.W $00DB                          ;00CAE4|2DDB00  |0000DB;
    BNE CODE_00CB4E                      ;00CAE7|D065    |00CB4E;
    JMP.W CODE_00CB76                    ;00CAE9|4C76CB  |00CB76;

CODE_00CAEC:
    LDA.B #$01                           ;00CAEC|A901    |      ;
    TRB.W $00DA                          ;00CAEE|1CDA00  |0000DA;
    JSR.W CODE_00CC09                    ;00CAF1|2009CC  |00CC09;
    LDX.W #$5555                         ;00CAF4|A25555  |      ;
    STX.W $0E04                          ;00CAF7|8E040E  |000E04;
    STX.W $0E06                          ;00CAFA|8E060E  |000E06;
    STX.W $0E08                          ;00CAFD|8E080E  |000E08;
    LDA.B #$80                           ;00CB00|A980    |      ;
    TRB.W $00DE                          ;00CB02|1CDE00  |0000DE;
    BRA CODE_00CB79                      ;00CB05|8072    |00CB79;

CODE_00CB07:
    LDA.B #$40                           ;00CB07|A940    |      ;
    TRB.W $00DB                          ;00CB09|1CDB00  |0000DB;
    JSR.W CODE_00CCBD                    ;00CB0C|20BDCC  |00CCBD;
    BRA CODE_00CB79                      ;00CB0F|8068    |00CB79;
