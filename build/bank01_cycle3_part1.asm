; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 3, Part 1)
; Advanced Battle Menu and Data Management Systems
; ==============================================================================

; ==============================================================================
; Character Data Verification System
; Validates character structures and sprite data integrity
; ==============================================================================

CODE_01A947:
                       PHP                                 ;01A947|08      |      ;
                       SEP #$20                           ;01A948|E220    |      ;
                       REP #$10                           ;01A94A|C210    |      ;
                       LDA.W $1948                        ;01A94C|AD4819  |001948;
                       BNE CODE_01A957                     ;01A94F|D006    |01A957;
                       JSR.W CODE_019168                   ;01A951|206891  |019168;
                       JMP.W CODE_01A95A                   ;01A954|4C5AA9  |01A95A;

CODE_01A957:
                       JSR.W CODE_0192AC                   ;01A957|20AC92  |0192AC;

CODE_01A95A:
                       PLP                                 ;01A95A|28      |      ;
                       RTS                                 ;01A95B|60      |      ;

; ==============================================================================
; Sprite Data Block Validation
; Ensures sprite data integrity across memory banks
; ==============================================================================

CODE_01A95C:
                       PHB                                 ;01A95C|8B      |      ;
                       PHY                                 ;01A95D|5A      |      ;
                       PHP                                 ;01A95E|08      |      ;
                       PHD                                 ;01A95F|0B      |      ;
                       PEA.W $192B                        ;01A960|F42B19  |00192B;
                       PLD                                 ;01A963|2B      |      ;
                       REP #$30                           ;01A964|C230    |      ;
                       PHB                                 ;01A966|8B      |      ;
                       LDX.B $02                          ;01A967|A602    |00192D;
                       LDY.B $04                          ;01A969|A404    |00192F;
                       LDA.W #$000F                       ;01A96B|A90F00  |      ;
                       MVN $7F,$04                       ;01A96E|547F04  |      ;
                       PLB                                 ;01A971|AB      |      ;
                       SEP #$20                           ;01A972|E220    |      ;
                       REP #$10                           ;01A974|C210    |      ;
                       LDA.B #$08                         ;01A976|A908    |      ;
                       STA.B $01                          ;01A978|8501    |00192C;

; ==============================================================================
; Byte-Level Data Validation Loop
; Validates individual sprite data bytes with format checking
; ==============================================================================

CODE_01A97A:
                       PHB                                 ;01A97A|8B      |      ;
                       LDA.B $06                          ;01A97B|A506    |001931;
                       PHA                                 ;01A97D|48      |      ;
                       PLB                                 ;01A97E|AB      |      ;
                       LDA.W $0000,X                      ;01A97F|BD0000  |040000;
                       INX                                 ;01A982|E8      |      ;
                       PHA                                 ;01A983|48      |      ;
                       LDA.B $07                          ;01A984|A507    |001932;
                       PHA                                 ;01A986|48      |      ;
                       PLB                                 ;01A987|AB      |      ;
                       PLA                                 ;01A988|68      |      ;
                       XBA                                 ;01A989|EB      |      ;
                       LDA.B #$00                         ;01A98A|A900    |      ;
                       XBA                                 ;01A98C|EB      |      ;
                       REP #$30                           ;01A98D|C230    |      ;
                       STA.W $0000,Y                      ;01A98F|990000  |7F0000;
                       INY                                 ;01A992|C8      |      ;
                       INY                                 ;01A993|C8      |      ;
                       SEP #$20                           ;01A994|E220    |      ;
                       REP #$10                           ;01A996|C210    |      ;
                       PLB                                 ;01A998|AB      |      ;
                       DEC.B $01                          ;01A999|C601    |00192C;
                       BNE CODE_01A97A                     ;01A99B|D0DD    |01A97A;
                       PLD                                 ;01A99D|2B      |      ;
                       PLP                                 ;01A99E|28      |      ;
                       PLY                                 ;01A99F|7A      |      ;
                       PLB                                 ;01A9A0|AB      |      ;
                       RTS                                 ;01A9A1|60      |      ;

; ==============================================================================
; Character Graphics Validation Engine
; Advanced validation of character sprite and animation data
; ==============================================================================

CODE_01A988:
                       PHP                                 ;01A988|08      |      ;
                       SEP #$20                           ;01A989|E220    |      ;
                       REP #$10                           ;01A98B|C210    |      ;
                       LDX.W $1939                        ;01A98D|AE3919  |001939;
                       LDA.B #$00                         ;01A990|A900    |      ;
                       STA.B $00,X                        ;01A992|7400    |001A72;
                       STA.B $01,X                        ;01A994|7401    |001A73;
                       STA.B $02,X                        ;01A996|7402    |001A74;
                       STA.B $03,X                        ;01A998|7403    |001A75;
                       STA.B $04,X                        ;01A99A|7404    |001A76;
                       STA.B $05,X                        ;01A99C|7405    |001A77;
                       STA.B $06,X                        ;01A99E|7406    |001A78;
                       STA.B $07,X                        ;01A9A0|7407    |001A79;
                       STA.B $08,X                        ;01A9A2|7408    |001A7A;
                       STA.B $09,X                        ;01A9A4|7409    |001A7B;
                       STA.B $0A,X                        ;01A9A6|740A    |001A7C;
                       STA.B $0B,X                        ;01A9A8|740B    |001A7D;
                       STA.B $0C,X                        ;01A9AA|740C    |001A7E;
                       STA.B $0D,X                        ;01A9AC|740D    |001A7F;
                       STA.B $0E,X                        ;01A9AE|740E    |001A80;
                       STA.B $0F,X                        ;01A9B0|740F    |001A81;
                       STA.B $10,X                        ;01A9B2|7410    |001A82;
                       STA.B $11,X                        ;01A9B4|7411    |001A83;
                       STA.B $12,X                        ;01A9B6|7412    |001A84;
                       STA.B $13,X                        ;01A9B8|7413    |001A85;
                       STA.B $14,X                        ;01A9BA|7414    |001A86;
                       STA.B $15,X                        ;01A9BC|7415    |001A87;
                       STA.B $16,X                        ;01A9BE|7416    |001A88;
                       STA.B $17,X                        ;01A9C0|7417    |001A89;
                       STA.B $18,X                        ;01A9C2|7418    |001A8A;
                       STA.B $19,X                        ;01A9C4|7419    |001A8B;
                       PLP                                 ;01A9C6|28      |      ;
                       RTS                                 ;01A9C7|60      |      ;

; ==============================================================================
; Character State Initialization
; Sets up initial character states for battle system
; ==============================================================================

CODE_01A9C8:
                       PHP                                 ;01A9C8|08      |      ;
                       SEP #$20                           ;01A9C9|E220    |      ;
                       REP #$10                           ;01A9CB|C210    |      ;
                       LDA.W $1935                        ;01A9CD|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9D0|20DD90  |0190DD;
                       LDX.W $1939                        ;01A9D3|AE3919  |001939;
                       STA.B $00,X                        ;01A9D6|7400    |001A72;
                       INC.W $1935                        ;01A9D8|EE3519  |001935;
                       LDA.W $1935                        ;01A9DB|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9DE|20DD90  |0190DD;
                       STA.B $01,X                        ;01A9E1|7401    |001A73;
                       INC.W $1935                        ;01A9E3|EE3519  |001935;
                       LDA.W $1935                        ;01A9E6|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9E9|20DD90  |0190DD;
                       STA.B $02,X                        ;01A9EC|7402    |001A74;
                       INC.W $1935                        ;01A9EE|EE3519  |001935;
                       LDA.W $1935                        ;01A9F1|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9F4|20DD90  |0190DD;
                       STA.B $03,X                        ;01A9F7|7403    |001A75;
                       INC.W $1935                        ;01A9F9|EE3519  |001935;
                       PLP                                 ;01A9FC|28      |      ;
                       RTS                                 ;01A9FD|60      |      ;

; ==============================================================================
; Character Animation Data Setup
; Configures animation parameters for battle characters
; ==============================================================================

CODE_01A9FE:
                       PHP                                 ;01A9FE|08      |      ;
                       SEP #$20                           ;01A9FF|E220    |      ;
                       REP #$10                           ;01AA01|C210    |      ;
                       LDA.W $1935                        ;01AA03|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA06|20DD90  |0190DD;
                       LDX.W $1939                        ;01AA09|AE3919  |001939;
                       STA.B $04,X                        ;01AA0C|7404    |001A76;
                       INC.W $1935                        ;01AA0E|EE3519  |001935;
                       LDA.W $1935                        ;01AA11|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA14|20DD90  |0190DD;
                       STA.B $05,X                        ;01AA17|7405    |001A77;
                       INC.W $1935                        ;01AA19|EE3519  |001935;
                       LDA.W $1935                        ;01AA1C|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA1F|20DD90  |0190DD;
                       STA.B $06,X                        ;01AA22|7406    |001A78;
                       INC.W $1935                        ;01AA24|EE3519  |001935;
                       LDA.W $1935                        ;01AA27|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA2A|20DD90  |0190DD;
                       STA.B $07,X                        ;01AA2D|7407    |001A79;
                       INC.W $1935                        ;01AA2F|EE3519  |001935;
                       LDA.W $1935                        ;01AA32|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA35|20DD90  |0190DD;
                       STA.B $08,X                        ;01AA38|7408    |001A7A;
                       INC.W $1935                        ;01AA3A|EE3519  |001935;
                       PLP                                 ;01AA3D|28      |      ;
                       RTS                                 ;01AA3E|60      |      ;

; ==============================================================================
; Advanced Character Parameter Setup
; Complex character data initialization with multiple parameter blocks
; ==============================================================================

CODE_01AA3B:
                       PHP                                 ;01AA3B|08      |      ;
                       SEP #$20                           ;01AA3C|E220    |      ;
                       REP #$10                           ;01AA3E|C210    |      ;
                       LDX.W $1939                        ;01AA40|AE3919  |001939;
                       LDA.W $193B                        ;01AA43|AD3B19  |00193B;
                       STA.B $19,X                        ;01AA46|9519    |001A8B;
                       LDA.B #$02                         ;01AA48|A902    |      ;
                       STA.B $00,X                        ;01AA4A|7400    |001A72;
                       LDA.B #$FF                         ;01AA4C|A9FF    |      ;
                       STA.B $01,X                        ;01AA4E|7401    |001A73;
                       STA.B $02,X                        ;01AA50|7402    |001A74;
                       STA.B $03,X                        ;01AA52|7403    |001A75;
                       STA.B $04,X                        ;01AA54|7404    |001A76;
                       STA.B $05,X                        ;01AA56|7405    |001A77;
                       STA.B $06,X                        ;01AA58|7406    |001A78;
                       STA.B $07,X                        ;01AA5A|7407    |001A79;
                       STA.B $08,X                        ;01AA5C|7408    |001A7A;
                       STA.B $09,X                        ;01AA5E|7409    |001A7B;
                       STA.B $0A,X                        ;01AA60|740A    |001A7C;
                       STA.B $0B,X                        ;01AA62|740B    |001A7D;
                       STA.B $0C,X                        ;01AA64|740C    |001A7E;
                       STA.B $0D,X                        ;01AA66|740D    |001A7F;
                       STA.B $0E,X                        ;01AA68|740E    |001A80;
                       STA.B $0F,X                        ;01AA6A|740F    |001A81;
                       STA.B $10,X                        ;01AA6C|7410    |001A82;
                       STA.B $11,X                        ;01AA6E|7411    |001A83;
                       STA.B $12,X                        ;01AA70|7412    |001A84;
                       STA.B $13,X                        ;01AA72|7413    |001A85;
                       STA.B $14,X                        ;01AA74|7414    |001A86;
                       STA.B $15,X                        ;01AA76|7415    |001A87;
                       STA.B $16,X                        ;01AA78|7416    |001A88;
                       STA.B $17,X                        ;01AA7A|7417    |001A89;
                       STA.B $18,X                        ;01AA7C|7418    |001A8A;
                       PLP                                 ;01AA7E|28      |      ;
                       RTS                                 ;01AA7F|60      |      ;

; ==============================================================================
; Sprite Coordinate Transformation Engine
; Complex coordinate mapping for battle sprite positioning
; ==============================================================================

CODE_01AA80:
                       PHP                                 ;01AA80|08      |      ;
                       SEP #$20                           ;01AA81|E220    |      ;
                       REP #$10                           ;01AA83|C210    |      ;
                       LDA.B #$00                         ;01AA85|A900    |      ;
                       XBA                                 ;01AA87|EB      |      ;
                       LDA.W $1935                        ;01AA88|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA8B|20DD90  |0190DD;
                       TAY                                 ;01AA8E|A8      |      ;
                       INC.W $1935                        ;01AA8F|EE3519  |001935;
                       LDA.W $1935                        ;01AA92|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA95|20DD90  |0190DD;
                       XBA                                 ;01AA98|EB      |      ;
                       REP #$30                           ;01AA99|C230    |      ;
                       TYA                                 ;01AA9B|98      |      ;
                       AND.W #$00FF                       ;01AA9C|29FF00  |      ;
                       ORA.W #$7F00                       ;01AA9F|097F00  |      ;
                       STA.W $192B                        ;01AAA2|8D2B19  |00192B;
                       INC.W $1935                        ;01AAA5|EE3519  |001935;
                       LDA.W $1935                        ;01AAA8|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAAB|20DD90  |0190DD;
                       AND.W #$00FF                       ;01AAAE|29FF00  |      ;
                       ASL A                               ;01AAB1|0A      |      ;
                       TAY                                 ;01AAB2|A8      |      ;
                       LDA.W $192B                        ;01AAB3|AD2B19  |00192B;
                       STA.W $0000,Y                      ;01AAB6|990000  |7F0000;
                       INC.W $1935                        ;01AAB9|EE3519  |001935;
                       PLP                                 ;01AABC|28      |      ;
                       RTS                                 ;01AABD|60      |      ;

; ==============================================================================
; Character Battle Data Loading
; Comprehensive character data loading with validation and setup
; ==============================================================================

CODE_01AABE:
                       PHP                                 ;01AABE|08      |      ;
                       SEP #$20                           ;01AABF|E220    |      ;
                       REP #$10                           ;01AAC1|C210    |      ;
                       LDA.W $1935                        ;01AAC3|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAC6|20DD90  |0190DD;
                       LDX.W $1939                        ;01AAC9|AE3919  |001939;
                       STA.B $09,X                        ;01AACC|7409    |001A7B;
                       INC.W $1935                        ;01AACE|EE3519  |001935;
                       LDA.W $1935                        ;01AAD1|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAD4|20DD90  |0190DD;
                       STA.B $0A,X                        ;01AAD7|740A    |001A7C;
                       INC.W $1935                        ;01AAD9|EE3519  |001935;
                       LDA.W $1935                        ;01AADC|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AADF|20DD90  |0190DD;
                       STA.B $0B,X                        ;01AAE2|740B    |001A7D;
                       INC.W $1935                        ;01AAE4|EE3519  |001935;
                       LDA.W $1935                        ;01AAE7|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAEA|20DD90  |0190DD;
                       STA.B $0C,X                        ;01AAED|740C    |001A7E;
                       INC.W $1935                        ;01AAEF|EE3519  |001935;
                       LDA.W $1935                        ;01AAF2|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAF5|20DD90  |0190DD;
                       STA.B $0D,X                        ;01AAF8|740D    |001A7F;
                       INC.W $1935                        ;01AAFA|EE3519  |001935;
                       LDA.W $1935                        ;01AAFD|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB00|20DD90  |0190DD;
                       STA.B $0E,X                        ;01AB03|740E    |001A80;
                       INC.W $1935                        ;01AB05|EE3519  |001935;
                       LDA.W $1935                        ;01AB08|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB0B|20DD90  |0190DD;
                       STA.B $0F,X                        ;01AB0E|740F    |001A81;
                       INC.W $1935                        ;01AB10|EE3519  |001935;
                       LDA.W $1935                        ;01AB13|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB16|20DD90  |0190DD;
                       STA.B $10,X                        ;01AB19|7410    |001A82;
                       INC.W $1935                        ;01AB1B|EE3519  |001935;
                       LDA.W $1935                        ;01AB1E|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB21|20DD90  |0190DD;
                       STA.B $11,X                        ;01AB24|7411    |001A83;
                       INC.W $1935                        ;01AB26|EE3519  |001935;
                       LDA.W $1935                        ;01AB29|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB2C|20DD90  |0190DD;
                       STA.B $12,X                        ;01AB2F|7412    |001A84;
                       INC.W $1935                        ;01AB31|EE3519  |001935;
                       LDA.W $1935                        ;01AB34|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB37|20DD90  |0190DD;
                       STA.B $13,X                        ;01AB3A|7413    |001A85;
                       INC.W $1935                        ;01AB3C|EE3519  |001935;
                       LDA.W $1935                        ;01AB3F|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB42|20DD90  |0190DD;
                       STA.B $14,X                        ;01AB45|7414    |001A86;
                       INC.W $1935                        ;01AB47|EE3519  |001935;
                       LDA.W $1935                        ;01AB4A|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB4D|20DD90  |0190DD;
                       STA.B $15,X                        ;01AB50|7415    |001A87;
                       INC.W $1935                        ;01AB52|EE3519  |001935;
                       LDA.W $1935                        ;01AB55|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB58|20DD90  |0190DD;
                       STA.B $16,X                        ;01AB5B|7416    |001A88;
                       INC.W $1935                        ;01AB5D|EE3519  |001935;
                       LDA.W $1935                        ;01AB60|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB63|20DD90  |0190DD;
                       STA.B $17,X                        ;01AB66|7417    |001A89;
                       INC.W $1935                        ;01AB68|EE3519  |001935;
                       LDA.W $1935                        ;01AB6B|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB6E|20DD90  |0190DD;
                       STA.B $18,X                        ;01AB71|7418    |001A8A;
                       INC.W $1935                        ;01AB73|EE3519  |001935;
                       PLP                                 ;01AB76|28      |      ;
                       RTS                                 ;01AB77|60      |      ;

; ==============================================================================
; Battle System Coordination Hub
; Main coordination point for battle system data management
; ==============================================================================

CODE_01AB78:
                       PHP                                 ;01AB78|08      |      ;
                       SEP #$20                           ;01AB79|E220    |      ;
                       REP #$10                           ;01AB7B|C210    |      ;
                       LDY.W $193B                        ;01AB7D|AC3B19  |00193B;
                       LDA.W $F0F0,Y                      ;01AB80|B9F0F0  |00F0F0;
                       BEQ CODE_01AB89                     ;01AB83|F004    |01AB89;
                       STA.W $1948                        ;01AB85|8D4819  |001948;
                       BRA CODE_01AB8C                     ;01AB88|8002    |01AB8C;

CODE_01AB89:
                       STZ.W $1948                        ;01AB89|9C4819  |001948;

CODE_01AB8C:
                       JSR.W CODE_01A6FC                   ;01AB8C|20FCA6  |01A6FC;
                       BCS CODE_01AB93                     ;01AB8F|B002    |01AB93;
                       PLP                                 ;01AB91|28      |      ;
                       RTS                                 ;01AB92|60      |      ;

CODE_01AB93:
                       JSR.W CODE_01A988                   ;01AB93|2088A9  |01A988;
                       JSR.W CODE_01A9C8                   ;01AB96|20C8A9  |01A9C8;
                       JSR.W CODE_01A9FE                   ;01AB99|20FEA9  |01A9FE;
                       JSR.W CODE_01AABE                   ;01AB9C|20BEAA  |01AABE;
                       JSR.W CODE_01AA80                   ;01AB9F|2080AA  |01AA80;
                       LDX.W $1939                        ;01ABA2|AE3919  |001939;
                       LDA.B #$01                         ;01ABA5|A901    |      ;
                       STA.B $00,X                        ;01ABA7|7400    |001A72;
                       PLP                                 ;01ABA9|28      |      ;
                       RTS                                 ;01ABAA|60      |      ;
