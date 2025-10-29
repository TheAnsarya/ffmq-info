; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 3)
; Advanced Graphics Memory Transfer and Animation Processing
; ==============================================================================

; ==============================================================================
; Main Graphics Memory Transfer Loop
; Large-scale graphics processing with dual memory bank coordination
; ==============================================================================

CODE_01A495:
                       REP #$30                           ;01A495|C230    |      ;
                       LDA.W #$0002                       ;01A497|A90200  |      ;
                       STA.B $16                          ;01A49A|8516    |001941;

; ==============================================================================
; Dual Memory Block Transfer Engine
; Processes 4x 16-byte blocks in parallel with complex bank switching
; ==============================================================================

CODE_01A49C:
                       LDA.W $0000,Y                      ;01A49C|B90000  |040000;
                       STA.L $7F0000,X                    ;01A49F|9F00007F|7F0000;
                       LDA.W $0002,Y                      ;01A4A3|B90200  |040002;
                       STA.L $7F0002,X                    ;01A4A6|9F02007F|7F0002;
                       LDA.W $0004,Y                      ;01A4AA|B90400  |040004;
                       STA.L $7F0004,X                    ;01A4AD|9F04007F|7F0004;
                       LDA.W $0006,Y                      ;01A4B1|B90600  |040006;
                       STA.L $7F0006,X                    ;01A4B4|9F06007F|7F0006;
                       TYA                                 ;01A4B8|98      |      ;
                       CLC                                 ;01A4B9|18      |      ;
                       ADC.W #$0008                       ;01A4BA|690800  |      ;
                       TAY                                 ;01A4BD|A8      |      ;
                       TXA                                 ;01A4BE|8A      |      ;
                       CLC                                 ;01A4BF|18      |      ;
                       ADC.W #$0008                       ;01A4C0|690800  |      ;
                       TAX                                 ;01A4C3|AA      |      ;
                       DEC.B $16                          ;01A4C4|C616    |001941;
                       BNE CODE_01A49C                     ;01A4C6|D0D4    |01A49C;
                       SEP #$20                           ;01A4C8|E220    |      ;
                       REP #$10                           ;01A4CA|C210    |      ;
                       LDA.B #$08                         ;01A4CC|A908    |      ;
                       STA.B $18                          ;01A4CE|8518    |001943;

; ==============================================================================
; Secondary Graphics Transfer with Format Conversion
; Single-byte transfer loop with automatic format conversion
; ==============================================================================

CODE_01A4D0:
                       LDA.W $0000,Y                      ;01A4D0|B90000  |040000;
                       STA.L $7F0000,X                    ;01A4D3|9F00007F|7F0000;
                       LDA.B #$00                         ;01A4D7|A900    |      ;
                       STA.L $7F0001,X                    ;01A4D9|9F01007F|7F0001;
                       INX                                 ;01A4DD|E8      |      ;
                       INX                                 ;01A4DE|E8      |      ;
                       INY                                 ;01A4DF|C8      |      ;
                       DEC.B $18                          ;01A4E0|C618    |001943;
                       BNE CODE_01A4D0                     ;01A4E2|D0EC    |01A4D0;
                       REP #$30                           ;01A4E4|C230    |      ;
                       DEC.B $14                          ;01A4E6|C614    |00193F;
                       BNE CODE_01A495                     ;01A4E8|D0AB    |01A495;
                       PLB                                 ;01A4EA|AB      |      ;

; ==============================================================================
; Character Graphics Processing Loop
; Complex sprite data processing with 16-tile character animation
; ==============================================================================

CODE_01A4EB:
                       SEP #$20                           ;01A4EB|E220    |      ;
                       REP #$10                           ;01A4ED|C210    |      ;
                       LDA.B #$80                         ;01A4EF|A980    |      ;
                       STA.B $0E                          ;01A4F1|850E    |001939;
                       LDY.W #$0008                       ;01A4F3|A00800  |      ;

CODE_01A4F6:
                       LDA.B #$00                         ;01A4F6|A900    |      ;
                       XBA                                 ;01A4F8|EB      |      ;
                       LDA.B $0A                          ;01A4F9|A50A    |001935;
                       REP #$30                           ;01A4FB|C230    |      ;
                       CLC                                 ;01A4FD|18      |      ;
                       ADC.W $19B9                        ;01A4FE|6DB919  |0119B9;
                       TAX                                 ;01A501|AA      |      ;
                       SEP #$20                           ;01A502|E220    |      ;
                       REP #$10                           ;01A504|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A506|BFFC880B|0B88FC;
                       STA.B $0D                          ;01A50A|850D    |001938;

; ==============================================================================
; Bit-Level Sprite Processing
; Processes individual sprite bits with complex masking and animation
; ==============================================================================

CODE_01A50C:
                       PHY                                 ;01A50C|5A      |      ;
                       LDA.B $0D                          ;01A50D|A50D    |001938;
                       AND.B $0E                          ;01A50F|250E    |001939;
                       BEQ CODE_01A52C                     ;01A511|F019    |01A52C;
                       LDA.B #$00                         ;01A513|A900    |      ;
                       XBA                                 ;01A515|EB      |      ;
                       LDA.B $0B                          ;01A516|A50B    |001936;
                       INC.B $0B                          ;01A518|E60B    |001936;
                       REP #$30                           ;01A51A|C230    |      ;
                       CLC                                 ;01A51C|18      |      ;
                       ADC.W $19B9                        ;01A51D|6DB919  |0119B9;
                       TAX                                 ;01A520|AA      |      ;
                       SEP #$20                           ;01A521|E220    |      ;
                       REP #$10                           ;01A523|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A525|BFFC880B|0B88FC;
                       JSR.W CODE_01A865                   ;01A529|2065A8  |01A865;

CODE_01A52C:
                       SEP #$20                           ;01A52C|E220    |      ;
                       REP #$10                           ;01A52E|C210    |      ;
                       INC.B $0C                          ;01A530|E60C    |001937;
                       LDA.B $0E                          ;01A532|A50E    |001939;
                       LSR A                               ;01A534|4A      |      ;
                       STA.B $0E                          ;01A535|850E    |001939;
                       PLY                                 ;01A537|7A      |      ;
                       DEY                                 ;01A538|88      |      ;
                       BNE CODE_01A50C                     ;01A539|D0D1    |01A50C;
                       INC.B $0A                          ;01A53B|E60A    |001935;
                       LDA.B $0A                          ;01A53D|A50A    |001935;
                       CMP.B #$0C                         ;01A53F|C90C    |      ;
                       BEQ CODE_01A550                     ;01A541|F00D    |01A550;
                       CMP.B #$0B                         ;01A543|C90B    |      ;
                       BNE CODE_01A4EB                     ;01A545|D0A4    |01A4EB;
                       LDA.B #$80                         ;01A547|A980    |      ;
                       STA.B $0E                          ;01A549|850E    |001939;
                       LDY.W #$0004                       ;01A54B|A00400  |      ;
                       BRA CODE_01A4F6                     ;01A54E|80A6    |01A4F6;

; ==============================================================================
; Final Graphics Processing and Validation
; Completes character processing with special effect integration
; ==============================================================================

CODE_01A550:
                       REP #$30                           ;01A550|C230    |      ;
                       LDA.W #$000B                       ;01A552|A90B00  |      ;
                       CLC                                 ;01A555|18      |      ;
                       ADC.W $19B9                        ;01A556|6DB919  |0119B9;
                       TAX                                 ;01A559|AA      |      ;
                       SEP #$20                           ;01A55A|E220    |      ;
                       REP #$10                           ;01A55C|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A55E|BFFC880B|0B88FC;
                       BIT.B #$01                         ;01A562|8901    |      ;
                       BEQ CODE_01A573                     ;01A564|F00D    |01A573;
                       LDA.B #$F2                         ;01A566|A9F2    |      ;
                       JSL.L CODE_009776                   ;01A568|22769700|009776;
                       BNE CODE_01A571                     ;01A56C|D003    |01A571;
                       JSR.W CODE_01A5AA                   ;01A56E|20AAA5  |01A5AA;

CODE_01A571:
                       BRA CODE_01A5A8                     ;01A571|8035    |01A5A8;

; ==============================================================================
; Standard Graphics Transfer Mode
; Handles normal character display without special effects
; ==============================================================================

CODE_01A573:
                       LDX.W #$ADA0                       ;01A573|A2A0AD  |      ;
                       STX.B $02                          ;01A576|8602    |00192D;
                       LDA.B #$04                         ;01A578|A904    |      ;
                       STA.B $06                          ;01A57A|8506    |001931;
                       LDA.B #$7F                         ;01A57C|A97F    |      ;
                       STA.B $07                          ;01A57E|8507    |001932;
                       LDA.B #$00                         ;01A580|A900    |      ;
                       XBA                                 ;01A582|EB      |      ;
                       LDA.B $0C                          ;01A583|A50C    |001937;
                       ASL A                               ;01A585|0A      |      ;
                       TAX                                 ;01A586|AA      |      ;
                       REP #$30                           ;01A587|C230    |      ;
                       LDA.L DATA8_01A5E0,X                ;01A589|BFE0A501|01A5E0;
                       STA.B $04                          ;01A58D|8504    |00192F;
                       LDY.W #$0060                       ;01A58F|A06000  |      ;

; ==============================================================================
; Graphics Transfer Coordination Loop
; Coordinates 96 transfer operations with memory management
; ==============================================================================

CODE_01A592:
                       JSR.W CODE_01A901                   ;01A592|2001A9  |01A901;
                       LDA.B $02                          ;01A595|A502    |00192D;
                       CLC                                 ;01A597|18      |      ;
                       ADC.W #$0018                       ;01A598|691800  |      ;
                       STA.B $02                          ;01A59B|8502    |00192D;
                       LDA.B $04                          ;01A59D|A504    |00192F;
                       CLC                                 ;01A59F|18      |      ;
                       ADC.W #$0020                       ;01A5A0|692000  |      ;
                       STA.B $04                          ;01A5A3|8504    |00192F;
                       DEY                                 ;01A5A5|88      |      ;
                       BNE CODE_01A592                     ;01A5A6|D0EA    |01A592;

CODE_01A5A8:
                       PLD                                 ;01A5A8|2B      |      ;
                       RTS                                 ;01A5A9|60      |      ;

; ==============================================================================
; Special Effects Graphics Handler
; Extended graphics processing for special battle effects
; ==============================================================================

CODE_01A5AA:
                       PHP                                 ;01A5AA|08      |      ;
                       PHD                                 ;01A5AB|0B      |      ;
                       PEA.W $192B                        ;01A5AC|F42B19  |00192B;
                       PLD                                 ;01A5AF|2B      |      ;
                       LDX.W #$BE20                       ;01A5B0|A220BE  |      ;
                       STX.B $02                          ;01A5B3|8602    |00192D;
                       LDA.B #$04                         ;01A5B5|A904    |      ;
                       STA.B $06                          ;01A5B7|8506    |001931;
                       LDA.B #$7F                         ;01A5B9|A97F    |      ;
                       STA.B $07                          ;01A5BB|8507    |001932;
                       REP #$30                           ;01A5BD|C230    |      ;
                       LDA.W #$1E00                       ;01A5BF|A9001E  |      ;
                       STA.B $04                          ;01A5C2|8504    |00192F;
                       LDY.W #$0080                       ;01A5C4|A08000  |      ;

; ==============================================================================
; Extended Graphics Transfer Loop (128 Operations)
; Larger transfer cycle for complex special effects
; ==============================================================================

CODE_01A5C7:
                       JSR.W CODE_01A901                   ;01A5C7|2001A9  |01A901;
                       LDA.B $02                          ;01A5CA|A502    |00192D;
                       CLC                                 ;01A5CC|18      |      ;
                       ADC.W #$0018                       ;01A5CD|691800  |      ;
                       STA.B $02                          ;01A5D0|8502    |00192D;
                       LDA.B $04                          ;01A5D2|A504    |00192F;
                       CLC                                 ;01A5D4|18      |      ;
                       ADC.W #$0020                       ;01A5D5|692000  |      ;
                       STA.B $04                          ;01A5D8|8504    |00192F;
                       DEY                                 ;01A5DA|88      |      ;
                       BNE CODE_01A5C7                     ;01A5DB|D0EA    |01A5C7;
                       PLD                                 ;01A5DD|2B      |      ;
                       PLP                                 ;01A5DE|28      |      ;
                       RTS                                 ;01A5DF|60      |      ;

; ==============================================================================
; Graphics Configuration Data Tables
; Complex addressing tables for multi-bank graphics coordination
; ==============================================================================

DATA8_01A5E0:
                       db $00,$02,$80,$02,$00,$03,$80,$03,$00,$04,$00,$06,$00,$0E,$00,$16 ; 01A5E0
                       db $00,$08,$80,$08,$00,$09,$80,$09,$00,$0A,$80,$0A,$00,$0B,$80,$0B ; 01A5F0
                       db $00,$0C                        ; 01A600
                       db $80,$0C,$00,$0D,$80,$0D    ; 01A602
                       db $00,$10,$80,$10,$00,$11,$80,$11,$00,$12,$80,$12,$00,$13,$80,$13 ; 01A608
                       db $00,$14                        ; 01A618
                       db $80,$14,$00,$15,$80,$15    ; 01A61A
                       db $00,$18,$80,$18,$00,$19,$80,$19,$00,$1A ; 01A620
                       db $80,$1A,$00,$1B              ; 01A62A
                       db $80,$1B,$00,$1C              ; 01A62E
                       db $80,$1C,$00,$1D,$80,$1D    ; 01A632
                       db $00,$1E                        ; 01A638

; ==============================================================================
; OAM Configuration Tables
; Sprite positioning and attribute data for battle system
; ==============================================================================

DATA8_01A63A:
                       db $80,$00                        ; 01A63A

DATA8_01A63C:
                       db $08,$02,$90,$00,$09,$02,$A0,$00,$0A,$02,$B0,$00,$0B,$02,$E0,$00 ; 01A63C
                       db $0E,$02,$F0,$00,$0F,$02,$00,$01,$10,$02,$10,$01,$11,$02,$20,$01 ; 01A64C
                       db $12,$02,$30,$01,$13,$02,$40,$01,$14,$02,$50,$01,$15,$02,$60,$01 ; 01A65C
                       db $16,$02,$70,$01,$17,$02,$80,$01,$18,$02,$90,$01,$19,$02,$A0,$01 ; 01A66C
                       db $1A,$02,$B0,$01,$1B,$02,$C0,$01,$1C,$02,$D0,$01,$1D,$02,$E0,$01 ; 01A67C
                       db $1E,$02,$F0,$01,$1F,$02    ; 01A68C

; ==============================================================================
; Main Sprite Engine Initialization
; Sets up sprite management system with memory allocation and coordination
; ==============================================================================

CODE_01A692:
                       SEP #$20                           ;01A692|E220    |      ;
                       REP #$10                           ;01A694|C210    |      ;
                       PHD                                 ;01A696|0B      |      ;
                       PEA.W $1A72                        ;01A697|F4721A  |001A72;
                       PLD                                 ;01A69A|2B      |      ;
                       LDX.W #$0000                       ;01A69B|A20000  |      ;
                       STX.W $1939                        ;01A69E|8E3919  |001939;
                       JSR.W CODE_01AF56                   ;01A6A1|2056AF  |01AF56;
                       SEP #$20                           ;01A6A4|E220    |      ;
                       REP #$10                           ;01A6A6|C210    |      ;
                       LDA.B #$FF                         ;01A6A8|A9FF    |      ;
                       STA.W $193B                        ;01A6AA|8D3B19  |00193B;
                       LDA.B #$08                         ;01A6AD|A908    |      ;
                       STA.W $1935                        ;01A6AF|8D3519  |001935;

; ==============================================================================
; Sprite Data Processing Loop
; Processes all active sprites with validation and coordinate processing
; ==============================================================================

CODE_01A6B2:
                       SEP #$20                           ;01A6B2|E220    |      ;
                       REP #$10                           ;01A6B4|C210    |      ;
                       INC.W $193B                        ;01A6B6|EE3B19  |00193B;
                       LDA.W $1935                        ;01A6B9|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A6BC|20DD90  |0190DD;
                       CMP.B #$FF                         ;01A6BF|C9FF    |      ;
                       BEQ CODE_01A6F0                     ;01A6C1|F02D    |01A6F0;
                       JSR.W CODE_01A6F2                   ;01A6C3|20F2A6  |01A6F2;
                       BCS CODE_01A6E1                     ;01A6C6|B019    |01A6E1;
                       REP #$30                           ;01A6C8|C230    |      ;
                       LDX.W $1939                        ;01A6CA|AE3919  |001939;
                       LDA.B $01,X                        ;01A6CD|B501    |001A73;
                       STA.B $03,X                        ;01A6CF|9503    |001A75;
                       STA.B $05,X                        ;01A6D1|9505    |001A77;
                       STA.B $07,X                        ;01A6D3|9507    |001A79;
                       LDA.W $1939                        ;01A6D5|AD3919  |001939;
                       CLC                                 ;01A6D8|18      |      ;
                       ADC.W #$001A                       ;01A6D9|691A00  |      ;
                       STA.W $1939                        ;01A6DC|8D3919  |001939;
                       BRA CODE_01A6B2                     ;01A6DF|80D1    |01A6B2;

CODE_01A6E1:
                       SEP #$20                           ;01A6E1|E220    |      ;
                       REP #$10                           ;01A6E3|C210    |      ;
                       LDA.W $1935                        ;01A6E5|AD3519  |001935;
                       CLC                                 ;01A6E8|18      |      ;
                       ADC.B #$07                         ;01A6E9|6907    |      ;
                       STA.W $1935                        ;01A6EB|8D3519  |001935;
                       BRA CODE_01A6B2                     ;01A6EE|80C2    |01A6B2;

CODE_01A6F0:
                       PLD                                 ;01A6F0|2B      |      ;
                       RTS                                 ;01A6F1|60      |      ;
