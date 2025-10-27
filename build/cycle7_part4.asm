; ==============================================================================
; Sprite Display System and Save/Load Operations - CODE_00C75B+
; ==============================================================================

CODE_00C75B:
    PHB                                  ;00C75B|8B      |      ;
    PHB                                  ;00C75C|8B      |      ;
    PLA                                  ;00C75D|68      |      ;
    STA.L $000031                        ;00C75E|8F310000|000031;
    SEP #$20                             ;00C762|E220    |      ;

CODE_00C764:
    LDA.L $000000,X                      ;00C764|BF000000|000000;
    BEQ CODE_00C78A                      ;00C768|F020    |00C78A;
    XBA                                  ;00C76A|EB      |      ;
    LDA.L $000001,X                      ;00C76B|BF010000|000001;
    STA.W $0000,Y                        ;00C76F|990000  |7F0000;
    LDA.B #$00                           ;00C772|A900    |      ;
    XBA                                  ;00C774|EB      |      ;
    DEC A                                ;00C775|3A      |      ;
    BEQ UNREACH_00C784                   ;00C776|F00C    |00C784;
    PHX                                  ;00C778|DA      |      ;
    ASL A                                ;00C779|0A      |      ;
    DEC A                                ;00C77A|3A      |      ;
    TYX                                  ;00C77B|BB      |      ;
    INY                                  ;00C77C|C8      |      ;
    INY                                  ;00C77D|C8      |      ;
    JSR.W $0030                          ;00C77E|203000  |000030;
    PLX                                  ;00C781|FA      |      ;
    BRA CODE_00C786                      ;00C782|8002    |00C786;

UNREACH_00C784:
    db $C8,$C8                           ;00C784|        |      ;

CODE_00C786:
    INX                                  ;00C786|E8      |      ;
    INX                                  ;00C787|E8      |      ;
    BRA CODE_00C764                      ;00C788|80DA    |00C764;

CODE_00C78A:
    REP #$30                             ;00C78A|C230    |      ;
    RTS                                  ;00C78C|60      |      ;

CODE_00C78D:
    SEP #$20                             ;00C78D|E220    |      ;
    LDA.B #$C0                           ;00C78F|A9C0    |      ;
    TRB.W $0111                          ;00C791|1C1101  |000111;
    RTS                                  ;00C794|60      |      ;

CODE_00C795:
    PHP                                  ;00C795|08      |      ;
    SEP #$20                             ;00C796|E220    |      ;
    LDA.B #$80                           ;00C798|A980    |      ;
    TRB.W $00D6                          ;00C79A|1CD600  |0000D6;
    LDA.W $00AA                          ;00C79D|ADAA00  |0000AA;
    AND.B #$F0                           ;00C7A0|29F0    |      ;
    STA.W $0110                          ;00C7A2|8D1001  |000110;
    LDA.W $00AA                          ;00C7A5|ADAA00  |0000AA;

CODE_00C7A8:
    CMP.W $0110                          ;00C7A8|CD1001  |000110;
    BEQ CODE_00C7B6                      ;00C7AB|F009    |00C7B6;
    INC.W $0110                          ;00C7AD|EE1001  |000110;
    JSL.L CODE_0C8000                    ;00C7B0|2200800C|0C8000;
    BRA CODE_00C7A8                      ;00C7B4|80F2    |00C7A8;

CODE_00C7B6:
    PLP                                  ;00C7B6|28      |      ;
    RTL                                  ;00C7B7|6B      |      ;

CODE_00C7B8:
    PHP                                  ;00C7B8|08      |      ;
    SEP #$20                             ;00C7B9|E220    |      ;
    LDA.W $0110                          ;00C7BB|AD1001  |010110;
    STA.W $00AA                          ;00C7BE|8DAA00  |0100AA;

CODE_00C7C1:
    BIT.B #$0F                           ;00C7C1|890F    |      ;
    BEQ CODE_00C7CF                      ;00C7C3|F00A    |00C7CF;
    DEC A                                ;00C7C5|3A      |      ;
    STA.W $0110                          ;00C7C6|8D1001  |010110;
    JSL.L CODE_0C8000                    ;00C7C9|2200800C|0C8000;
    BRA CODE_00C7C1                      ;00C7CD|80F2    |00C7C1;

CODE_00C7CF:
    LDA.B #$80                           ;00C7CF|A980    |      ;
    TSB.W $00D6                          ;00C7D1|0CD600  |0100D6;
    LDA.B #$80                           ;00C7D4|A980    |      ;
    STA.W $2100                          ;00C7D6|8D0021  |012100;
    STA.W $0110                          ;00C7D9|8D1001  |010110;
    PLP                                  ;00C7DC|28      |      ;
    RTL                                  ;00C7DD|6B      |      ;

CODE_00C7DE:
    JSR.W CODE_00C618                    ;00C7DE|2018C6  |00C618;
    JSR.W CODE_00C58B                    ;00C7E1|208BC5  |00C58B;
    LDX.W #$C8EC                         ;00C7E4|A2ECC8  |      ;
    JSR.W CODE_009BC4                    ;00C7E7|20C49B  |009BC4;
    LDX.W #$C8E3                         ;00C7EA|A2E3C8  |      ;
    JMP.W CODE_009BC4                    ;00C7ED|4CC49B  |009BC4;

CODE_00C7F0:
    LDA.W $010D                          ;00C7F0|AD0D01  |00010D;
    BPL CODE_00C7F8                      ;00C7F3|1003    |00C7F8;
    LDA.W #$0000                         ;00C7F5|A90000  |      ;

CODE_00C7F8:
    AND.W #$FF00                         ;00C7F8|2900FF  |      ;
    STA.B $01                            ;00C7FB|8501    |000001;
    SEP #$20                             ;00C7FD|E220    |      ;
    LDA.B #$18                           ;00C7FF|A918    |      ;
    STA.W $00AB                          ;00C801|8DAB00  |0000AB;
    JSR.W CODE_00CBEC                    ;00C804|20ECCB  |00CBEC;
    REP #$30                             ;00C807|C230    |      ;
    LDX.W #$C922                         ;00C809|A222C9  |      ;
    JSR.W CODE_009BC4                    ;00C80C|20C49B  |009BC4;
    PHB                                  ;00C80F|8B      |      ;
    LDX.W #$016F                         ;00C810|A26F01  |      ;
    LDY.W #$0E04                         ;00C813|A0040E  |      ;
    LDA.W #$0005                         ;00C816|A90500  |      ;
    MVN $00,$00                          ;00C819|540000  |      ;
    LDA.W #$0020                         ;00C81C|A92000  |      ;
    TSB.W $00D2                          ;00C81F|0CD200  |0000D2;
    JSR.W CODE_00C607                    ;00C822|2007C6  |00C607;
    LDX.W #$51C5                         ;00C825|A2C551  |      ;
    LDY.W #$5015                         ;00C828|A01550  |      ;
    LDA.W #$019F                         ;00C82B|A99F01  |      ;
    MVN $7F,$7F                          ;00C82E|547F7F  |      ;
    LDX.W #$552C                         ;00C831|A22C55  |      ;
    LDY.W #$537C                         ;00C834|A07C53  |      ;
    LDA.W #$019F                         ;00C837|A99F01  |      ;
    MVN $7F,$7F                          ;00C83A|547F7F  |      ;
    PLB                                  ;00C83D|AB      |      ;
    LDX.W #$C8E3                         ;00C83E|A2E3C8  |      ;
    JSR.W CODE_009BC4                    ;00C841|20C49B  |009BC4;
    LDA.W #$0600                         ;00C844|A90006  |      ;
    STA.B $01                            ;00C847|8501    |000001;
    STA.B $05                            ;00C849|8505    |000005;
    RTS                                  ;00C84B|60      |      ;

; Menu initialization and game state management
    LDA.W #$0040                         ;00C84C|A94000  |      ;
    TSB.W $00DB                          ;00C84F|0CDB00  |0000DB;
    BRA CODE_00C85A                      ;00C852|8006    |00C85A;

    LDA.W #$0001                         ;00C854|A90100  |      ;
    TSB.W $00DA                          ;00C857|0CDA00  |0000DA;

CODE_00C85A:
    JSR.W CODE_00C623                    ;00C85A|2023C6  |00C623;
    JSR.W CODE_00C5A0                    ;00C85D|20A0C5  |00C5A0;
    LDX.W #$C8EC                         ;00C860|A2ECC8  |      ;
    BRA CODE_00C89D                      ;00C863|8038    |00C89D;

    LDX.W #$C90A                         ;00C865|A20AC9  |      ;
    BRA CODE_00C89D                      ;00C868|8033    |00C89D;

    LDX.W #$C910                         ;00C86A|A210C9  |      ;
    BRA CODE_00C89D                      ;00C86D|802E    |00C89D;

    LDA.W #$0080                         ;00C86F|A98000  |      ;
    TRB.W $00D9                          ;00C872|1CD900  |0000D9;
    LDX.W #$C916                         ;00C875|A216C9  |      ;
    BRA CODE_00C89D                      ;00C878|8023    |00C89D;

    LDA.W #$0080                         ;00C87A|A98000  |      ;
    TSB.W $00DB                          ;00C87D|0CDB00  |0000DB;
    LDX.W #$C91C                         ;00C880|A21CC9  |      ;
    BRA CODE_00C89D                      ;00C883|8018    |00C89D;

    LDA.W $010D                          ;00C885|AD0D01  |00010D;
    BPL CODE_00C88D                      ;00C888|1003    |00C88D;
    LDA.W #$0000                         ;00C88A|A90000  |      ;

CODE_00C88D:
    AND.W #$FF00                         ;00C88D|2900FF  |      ;
    STA.B $01                            ;00C890|8501    |000001;
    STA.B $05                            ;00C892|8505    |000005;
    LDA.W #$0002                         ;00C894|A90200  |      ;
    TSB.W $00DA                          ;00C897|0CDA00  |0000DA;
    LDX.W #$C922                         ;00C89A|A222C9  |      ;

CODE_00C89D:
    PHX                                  ;00C89D|DA      |      ;
    JSR.W CODE_009BC4                    ;00C89E|20C49B  |009BC4;
    PLX                                  ;00C8A1|FA      |      ;
    INX                                  ;00C8A2|E8      |      ;
    INX                                  ;00C8A3|E8      |      ;
    INX                                  ;00C8A4|E8      |      ;
    LDY.W #$0017                         ;00C8A5|A01700  |      ;
    LDA.W #$0002                         ;00C8A8|A90200  |      ;
    MVN $00,$00                          ;00C8AB|540000  |      ;
    JSR.W CODE_00CAB9                    ;00C8AE|20B9CA  |00CAB9;
    LDX.W #$C8E3                         ;00C8B1|A2E3C8  |      ;
    JMP.W CODE_009BC4                    ;00C8B4|4CC49B  |009BC4;

; Animation and screen effect handlers
    LDX.W #$C8F2                         ;00C8B7|A2F2C8  |      ;
    BRA CODE_00C8C9                      ;00C8BA|800D    |00C8C9;

    LDX.W #$C8F8                         ;00C8BC|A2F8C8  |      ;
    BRA CODE_00C8C9                      ;00C8BF|8008    |00C8C9;

    LDX.W #$C8FE                         ;00C8C1|A2FEC8  |      ;
    BRA CODE_00C8C9                      ;00C8C4|8003    |00C8C9;

    LDX.W #$C904                         ;00C8C6|A204C9  |      ;

CODE_00C8C9:
    PHX                                  ;00C8C9|DA      |      ;
    JSR.W CODE_009BC4                    ;00C8CA|20C49B  |009BC4;
    PLX                                  ;00C8CD|FA      |      ;
    INX                                  ;00C8CE|E8      |      ;
    INX                                  ;00C8CF|E8      |      ;
    INX                                  ;00C8D0|E8      |      ;
    LDA.W #$000C                         ;00C8D1|A90C00  |      ;

CODE_00C8D4:
    JSL.L CODE_0C8000                    ;00C8D4|2200800C|0C8000;
    PHA                                  ;00C8D8|48      |      ;
    PHX                                  ;00C8D9|DA      |      ;
    JSR.W CODE_009BC4                    ;00C8DA|20C49B  |009BC4;
    PLX                                  ;00C8DD|FA      |      ;
    PLA                                  ;00C8DE|68      |      ;
    DEC A                                ;00C8DF|3A      |      ;
    BNE CODE_00C8D4                      ;00C8E0|D0F2    |00C8D4;
    RTS                                  ;00C8E2|60      |      ;
