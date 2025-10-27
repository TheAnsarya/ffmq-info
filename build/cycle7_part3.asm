; ==============================================================================
; Screen Setup and Sprite Systems - CODE_00C675+
; ==============================================================================

CODE_00C675:
    LDY.W #$521D                         ;00C675|A01D52  |      ;
    PHB                                  ;00C678|8B      |      ;
    PHY                                  ;00C679|5A      |      ;
    JSR.W CODE_00C576                    ;00C67A|2076C5  |00C576;
    PLY                                  ;00C67D|7A      |      ;
    LDX.W #$C686                         ;00C67E|A286C6  |      ;
    JSR.W CODE_00C75B                    ;00C681|205BC7  |00C75B;
    PLB                                  ;00C684|AB      |      ;
    RTS                                  ;00C685|60      |      ;

DATA_00C686:
    db $0C,$04,$18,$08,$00               ;00C686|        |      ;

CODE_00C68B:
    PHB                                  ;00C68B|8B      |      ;
    JSR.W CODE_00C576                    ;00C68C|2076C5  |00C576;
    LDX.W #$C6A6                         ;00C68F|A2A6C6  |      ;
    LDY.W #$522D                         ;00C692|A02D52  |      ;
    JSR.W CODE_00C75B                    ;00C695|205BC7  |00C75B;
    JSR.W CODE_00C5A0                    ;00C698|20A0C5  |00C5A0;
    LDX.W #$C6B3                         ;00C69B|A2B3C6  |      ;
    LDY.W #$5634                         ;00C69E|A03456  |      ;
    JSR.W CODE_00C75B                    ;00C6A1|205BC7  |00C75B;
    PLB                                  ;00C6A4|AB      |      ;
    RTS                                  ;00C6A5|60      |      ;

DATA_00C6A6:
    db $0C,$04,$0C,$08,$1C,$0C,$1C,$10,$1C,$14,$10,$18,$00 ;00C6A6|        |      ;

DATA_00C6B3:
    db $1C,$04,$10,$08,$00               ;00C6B3|        |      ;

CODE_00C6B8:
    PHB                                  ;00C6B8|8B      |      ;
    JSR.W CODE_00C576                    ;00C6B9|2076C5  |00C576;
    LDX.W #$C6D3                         ;00C6BC|A2D3C6  |      ;
    LDY.W #$528D                         ;00C6BF|A08D52  |      ;
    JSR.W CODE_00C75B                    ;00C6C2|205BC7  |00C75B;
    JSR.W CODE_00C5A0                    ;00C6C5|20A0C5  |00C5A0;
    LDX.W #$C6D6                         ;00C6C8|A2D6C6  |      ;
    LDY.W #$5574                         ;00C6CB|A07455  |      ;
    JSR.W CODE_00C75B                    ;00C6CE|205BC7  |00C75B;
    PLB                                  ;00C6D1|AB      |      ;
    RTS                                  ;00C6D2|60      |      ;

DATA_00C6D3:
    db $0C,$04,$00                       ;00C6D3|        |      ;

DATA_00C6D6:
    db $0C,$04,$14,$08,$0C,$0C,$34,$10,$0C,$14,$0C,$18,$0C ;00C6D6|        |      ;
    db $1C,$08,$20,$00                   ;00C6E3|        |      ;

CODE_00C6E7:
    PHB                                  ;00C6E7|8B      |      ;
    JSR.W CODE_00C576                    ;00C6E8|2076C5  |00C576;
    LDX.W #$C73F                         ;00C6EB|A23FC7  |      ;
    LDY.W #$527D                         ;00C6EE|A07D52  |      ;
    JSR.W CODE_00C75B                    ;00C6F1|205BC7  |00C75B;
    JSR.W CODE_00C5A0                    ;00C6F4|20A0C5  |00C5A0;
    LDX.W #$C744                         ;00C6F7|A244C7  |      ;
    LDY.W #$55B4                         ;00C6FA|A0B455  |      ;
    JSR.W CODE_00C75B                    ;00C6FD|205BC7  |00C75B;
    LDX.W #$55B4                         ;00C700|A2B455  |      ;
    LDY.W #$0000                         ;00C703|A00000  |      ;
    LDA.L $000101                        ;00C706|AF010100|000101;
    JSR.W CODE_00C729                    ;00C70A|2029C7  |00C729;
    LDX.W #$562C                         ;00C70D|A22C56  |      ;
    LDY.W #$000C                         ;00C710|A00C00  |      ;
    LDA.L $000102                        ;00C713|AF020100|000102;
    JSR.W CODE_00C729                    ;00C717|2029C7  |00C729;
    LDX.W #$56A4                         ;00C71A|A2A456  |      ;
    LDY.W #$0018                         ;00C71D|A01800  |      ;
    LDA.L $000103                        ;00C720|AF030100|000103;
    JSR.W CODE_00C729                    ;00C724|2029C7  |00C729;
    PLB                                  ;00C727|AB      |      ;
    RTS                                  ;00C728|60      |      ;

CODE_00C729:
    AND.W #$0080                         ;00C729|298000  |      ;
    BEQ CODE_00C73E                      ;00C72C|F010    |00C73E;
    db $E2,$20,$98,$9D,$00,$00,$9B,$C8,$C8,$A9,$15,$54,$7F,$7F,$C2,$30 ;00C72E|        |      ;

CODE_00C73E:
    RTS                                  ;00C73E|60      |      ;

DATA_00C73F:
    db $3C,$04,$38,$08,$00               ;00C73F|        |      ;

DATA_00C744:
    db $06,$04,$06,$06,$0C,$08,$24,$0C,$06,$10,$06,$12,$0C,$14,$24,$18 ;00C744|        |      ;
    db $06,$1C,$06,$1E,$08,$20,$00       ;00C754|        |      ;
