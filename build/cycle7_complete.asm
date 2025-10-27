; ==============================================================================
; Screen Color Management and Final Systems - CODE_00CB11+
; ==============================================================================

CODE_00CB11:
    JSR.W CODE_00CD22                    ;00CB11|2022CD  |00CD22;
    REP #$30                             ;00CB14|C230    |      ;
    LDX.W #$016F                         ;00CB16|A26F01  |      ;
    LDY.W #$0E04                         ;00CB19|A0040E  |      ;
    LDA.W #$0005                         ;00CB1C|A90500  |      ;
    MVN $00,$00                          ;00CB1F|540000  |      ;
    SEP #$20                             ;00CB22|E220    |      ;
    LDA.B #$80                           ;00CB24|A980    |      ;
    TSB.W $00DE                          ;00CB26|0CDE00  |0000DE;
    JSR.W CODE_00CD60                    ;00CB29|2060CD  |00CD60;
    JSR.W CODE_00CBC6                    ;00CB2C|20C6CB  |00CBC6;
    JSL.L CODE_0C8000                    ;00CB2F|2200800C|0C8000;
    LDA.B #$E0                           ;00CB33|A9E0    |      ;
    STA.L $7F56D8                        ;00CB35|8FD8567F|7F56D8;
    STA.L $7F56D8,X                      ;00CB39|9FD8567F|7F56D8;
    JSL.L CODE_0C8000                    ;00CB3D|2200800C|0C8000;
    LDA.B #$02                           ;00CB41|A902    |      ;
    TRB.W $00DA                          ;00CB43|1CDA00  |0000DA;
    LDA.B #$08                           ;00CB46|A908    |      ;
    TRB.W $00D4                          ;00CB48|1CD400  |0000D4;
    JMP.W CODE_00981B                    ;00CB4B|4C1B98  |00981B;

CODE_00CB4E:
    JSR.W CODE_00CD22                    ;00CB4E|2022CD  |00CD22;
    JSR.W CODE_00CD60                    ;00CB51|2060CD  |00CD60;
    JSR.W CODE_00CC6E                    ;00CB54|206ECC  |00CC6E;
    JSL.L CODE_0C8000                    ;00CB57|2200800C|0C8000;
    LDA.B #$E0                           ;00CB5B|A9E0    |      ;
    STA.L $7F56DA                        ;00CB5D|8FDA567F|7F56DA;
    STA.L $7F56DE                        ;00CB61|8FDE567F|7F56DE;
    JSL.L CODE_0C8000                    ;00CB65|2200800C|0C8000;
    LDA.B #$80                           ;00CB69|A980    |      ;
    TRB.W $00DB                          ;00CB6B|1CDB00  |0000DB;
    LDA.B #$08                           ;00CB6E|A908    |      ;
    TRB.W $00D4                          ;00CB70|1CD400  |0000D4;
    JMP.W CODE_00981B                    ;00CB73|4C1B98  |00981B;

CODE_00CB76:
    JSR.W CODE_00CD22                    ;00CB76|2022CD  |00CD22;

CODE_00CB79:
    JSR.W CODE_00CD60                    ;00CB79|2060CD  |00CD60;
    JSR.W CODE_00CD42                    ;00CB7C|2042CD  |00CD42;
    JSL.L CODE_0C8000                    ;00CB7F|2200800C|0C8000;
    LDA.B #$E0                           ;00CB83|A9E0    |      ;
    STA.W SNES_COLDATA                   ;00CB85|8D3221  |002132;
    LDX.W #$0000                         ;00CB88|A20000  |      ;
    STX.W SNES_CGSWSEL                   ;00CB8B|8E3021  |002130;
    JMP.W CODE_00981B                    ;00CB8E|4C1B98  |00981B;

CODE_00CB91:
    REP #$30                             ;00CB91|C230    |      ;
    PHB                                  ;00CB93|8B      |      ;
    LDX.W #$CBBD                         ;00CB94|A2BDCB  |      ;
    LDY.W #$56D7                         ;00CB97|A0D756  |      ;
    LDA.W #$0008                         ;00CB9A|A90800  |      ;
    MVN $7F,$00                          ;00CB9D|547F00  |      ;
    PLB                                  ;00CBA0|AB      |      ;
    LDA.W #$0080                         ;00CBA1|A98000  |      ;
    TSB.W $00DA                          ;00CBA4|0CDA00  |0000DA;
    LDA.W #$0020                         ;00CBA7|A92000  |      ;
    TSB.W $0111                          ;00CBAA|0C1101  |000111;
    LDA.B $02                            ;00CBAD|A502    |000002;
    AND.W #$00FF                         ;00CBAF|29FF00  |      ;
    INC A                                ;00CBB2|1A      |      ;
    ASL A                                ;00CBB3|0A      |      ;
    TAX                                  ;00CBB4|AA      |      ;
    SEP #$20                             ;00CBB5|E220    |      ;
    LDA.B #$08                           ;00CBB7|A908    |      ;
    TSB.W $00D4                          ;00CBB9|0CD400  |0000D4;
    RTS                                  ;00CBBC|60      |      ;

DATA_00CBBD:
    db $27,$EC,$3C,$EC,$3C,$EC,$38,$EC,$00 ;00CBBD|        |      ;

CODE_00CBC6:
    JSR.W CODE_00CB91                    ;00CBC6|2091CB  |00CB91;
    LDA.B #$E9                           ;00CBC9|A9E9    |      ;

CODE_00CBCB:
    LDY.B $17                            ;00CBCB|A417    |000017;
    JSR.W CODE_009D75                    ;00CBCD|20759D  |009D75;
    STY.B $17                            ;00CBD0|8417    |000017;
    JSL.L CODE_0C8000                    ;00CBD2|2200800C|0C8000;
    STA.L $7F56D8                        ;00CBD6|8FD8567F|7F56D8;
    STA.L $7F56D8,X                      ;00CBDA|9FD8567F|7F56D8;
    DEC A                                ;00CBDE|3A      |      ;
    DEC A                                ;00CBDF|3A      |      ;
    CMP.B #$E1                           ;00CBE0|C9E1    |      ;
    BNE CODE_00CBCB                      ;00CBE2|D0E7    |00CBCB;
    LDY.B $17                            ;00CBE4|A417    |000017;
    JSR.W CODE_009D75                    ;00CBE6|20759D  |009D75;
    STY.B $17                            ;00CBE9|8417    |000017;
    RTS                                  ;00CBEB|60      |      ;

CODE_00CBEC:
    LDY.W #$9300                         ;00CBEC|A00093  |      ;
    STY.W SNES_CGSWSEL                   ;00CBEF|8C3021  |002130;
    JSR.W CODE_00CB91                    ;00CBF2|2091CB  |00CB91;
    LDA.B #$E0                           ;00CBF5|A9E0    |      ;
    STA.L $7F56D8                        ;00CBF7|8FD8567F|7F56D8;
    STA.L $7F56D8,X                      ;00CBFB|9FD8567F|7F56D8;
    JSL.L CODE_0C8000                    ;00CBFF|2200800C|0C8000;
    LDA.B #$08                           ;00CC03|A908    |      ;
    TRB.W $00D4                          ;00CC05|1CD400  |0000D4;
    RTS                                  ;00CC08|60      |      ;

CODE_00CC09:
    LDA.B #$08                           ;00CC09|A908    |      ;
    TSB.W $00D4                          ;00CC0B|0CD400  |0000D4;
    LDX.W #$0007                         ;00CC0E|A20700  |      ;

CODE_00CC11:
    JSL.L CODE_0C8000                    ;00CC11|2200800C|0C8000;
    LDA.L $7F56D8                        ;00CC15|AFD8567F|7F56D8;
    JSR.W CODE_00CC5B                    ;00CC19|205BCC  |00CC5B;
    STA.L $7F56D8                        ;00CC1C|8FD8567F|7F56D8;
    LDA.L $7F56DA                        ;00CC20|AFDA567F|7F56DA;
    JSR.W CODE_00CC5B                    ;00CC24|205BCC  |00CC5B;
    STA.L $7F56DA                        ;00CC27|8FDA567F|7F56DA;
    LDA.L $7F56DC                        ;00CC2B|AFDC567F|7F56DC;
    JSR.W CODE_00CC5B                    ;00CC2F|205BCC  |00CC5B;
    STA.L $7F56DC                        ;00CC32|8FDC567F|7F56DC;
    LDA.L $7F56DE                        ;00CC36|AFDE567F|7F56DE;
    JSR.W CODE_00CC5B                    ;00CC3A|205BCC  |00CC5B;
    STA.L $7F56DE                        ;00CC3D|8FDE567F|7F56DE;
    LDY.B $17                            ;00CC41|A417    |000017;
    JSR.W CODE_009D75                    ;00CC43|20759D  |009D75;
    STY.B $17                            ;00CC46|8417    |000017;
    DEX                                  ;00CC48|CA      |      ;
    BNE CODE_00CC11                      ;00CC49|D0C6    |00CC11;
    LDA.B #$08                           ;00CC4B|A908    |      ;
    TRB.W $00D4                          ;00CC4D|1CD400  |0000D4;
    LDA.B #$20                           ;00CC50|A920    |      ;
    TRB.W $0111                          ;00CC52|1C1101  |000111;
    LDA.B #$80                           ;00CC55|A980    |      ;
    TRB.W $00DA                          ;00CC57|1CDA00  |0000DA;
    RTS                                  ;00CC5A|60      |      ;

CODE_00CC5B:
    CLC                                  ;00CC5B|18      |      ;
    ADC.L CODE_00CC66,X                  ;00CC5C|7F66CC00|00CC66;
    CMP.B #$F0                           ;00CC60|C9F0    |      ;
    BCC CODE_00CC66                      ;00CC62|9002    |00CC66;
    LDA.B #$EF                           ;00CC64|A9EF    |      ;

CODE_00CC66:
    RTS                                  ;00CC66|60      |      ;

DATA_00CC67:
    db $03,$02,$02,$02,$02,$01,$03       ;00CC67|        |      ;

; ==============================================================================
; BANK $00 COMPLETE - FINAL STUB SECTION
; ==============================================================================

; Final stub definitions for any remaining external routines
CODE_00CF3F:
    = $CF3F
CODE_00CF62:
    = $CF62

; ==============================================================================
; END OF BANK $00 - 100% COMPLETE
; ==============================================================================
