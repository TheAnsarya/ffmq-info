; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 3, Part 2)  
; Battle Menu Management and Advanced Data Processing
; ==============================================================================

; ==============================================================================
; Battle Menu Control System
; Advanced menu handling for battle interface
; ==============================================================================

CODE_01ABAB:
                       PHP                                 ;01ABAB|08      |      ;
                       SEP #$20                           ;01ABAC|E220    |      ;
                       REP #$10                           ;01ABAE|C210    |      ;
                       LDX.W $1939                        ;01ABB0|AE3919  |001939;
                       LDA.B #$00                         ;01ABB3|A900    |      ;
                       STA.B $00,X                        ;01ABB5|7400    |001A72;
                       STA.B $01,X                        ;01ABB7|7401    |001A73;
                       STA.B $02,X                        ;01ABB9|7402    |001A74;
                       STA.B $03,X                        ;01ABBB|7403    |001A75;
                       STA.B $04,X                        ;01ABBD|7404    |001A76;
                       STA.B $05,X                        ;01ABBF|7405    |001A77;
                       STA.B $06,X                        ;01ABC1|7406    |001A78;
                       STA.B $07,X                        ;01ABC3|7407    |001A79;
                       STA.B $08,X                        ;01ABC5|7408    |001A7A;
                       STA.B $09,X                        ;01ABC7|7409    |001A7B;
                       STA.B $0A,X                        ;01ABC9|740A    |001A7C;
                       STA.B $0B,X                        ;01ABCB|740B    |001A7D;
                       STA.B $0C,X                        ;01ABCD|740C    |001A7E;
                       STA.B $0D,X                        ;01ABCF|740D    |001A7F;
                       STA.B $0E,X                        ;01ABD1|740E    |001A80;
                       STA.B $0F,X                        ;01ABD3|740F    |001A81;
                       STA.B $10,X                        ;01ABD5|7410    |001A82;
                       STA.B $11,X                        ;01ABD7|7411    |001A83;
                       STA.B $12,X                        ;01ABD9|7412    |001A84;
                       STA.B $13,X                        ;01ABDB|7413    |001A85;
                       STA.B $14,X                        ;01ABDD|7414    |001A86;
                       STA.B $15,X                        ;01ABDF|7415    |001A87;
                       STA.B $16,X                        ;01ABE1|7416    |001A88;
                       STA.B $17,X                        ;01ABE3|7417    |001A89;
                       STA.B $18,X                        ;01ABE5|7418    |001A8A;
                       STA.B $19,X                        ;01ABE7|7419    |001A8B;
                       PLP                                 ;01ABE9|28      |      ;
                       RTS                                 ;01ABEA|60      |      ;

; ==============================================================================
; Character Data Table Management
; Manages character data tables for battle system
; ==============================================================================

                       db $FE,$FF,$02,$00,$00,$00,$00,$00,$02,$00,$FE,$FF,$00,$00 ; 01ABEB

DATA8_01ABF9:
                       db $10                              ;01ABF9|        |      ;

CODE_01ABFA:
                       LDA.B #$1C                         ;01ABFA|A91C    |      ;
                       JSR.W CODE_01D0BB                   ;01ABFC|20BBD0  |01D0BB;
                       RTS                                 ;01ABFF|60      |      ;

; ==============================================================================  
; Battle Character Validation System
; Validates and processes battle character data structures
; ==============================================================================

CODE_01AC00:
                       LDA.W $19EE                        ;01AC00|ADEE19  |0119EE;
                       JSR.W CODE_01C589                   ;01AC03|2089C5  |01C589;
                       RTS                                 ;01AC06|60      |      ;

; ==============================================================================
; Battle Character Data Loading Engine  
; Complex character data loading with bank switching and validation
; ==============================================================================

CODE_01AC07:
                       PHB                                 ;01AC07|8B      |      ;
                       LDA.W $19EE                        ;01AC08|ADEE19  |0119EE;
                       AND.W #$00FF                       ;01AC0B|29FF00  |      ;
                       ASL A                               ;01AC0E|0A      |      ;
                       TAX                                 ;01AC0F|AA      |      ;
                       LDA.L DATA8_06BD62,X                ;01AC10|BF62BD06|06BD62;
                       TAX                                 ;01AC14|AA      |      ;
                       PHP                                 ;01AC15|08      |      ;
                       SEP #$20                           ;01AC16|E220    |      ;
                       REP #$10                           ;01AC18|C210    |      ;
                       PEA.W $7F00                        ;01AC1A|F4007F  |017F00;
                       PLB                                 ;01AC1D|AB      |      ;
                       PLB                                 ;01AC1E|AB      |      ;

; ==============================================================================
; Character Data Processing Loop
; Iterates through character data with complex validation
; ==============================================================================

CODE_01AC1F:
                       PHX                                 ;01AC1F|DA      |      ;
                       LDA.B #$00                         ;01AC20|A900    |      ;
                       XBA                                 ;01AC22|EB      |      ;
                       LDA.L DATA8_06BD78,X                ;01AC23|BF78BD06|06BD78;
                       CMP.B #$FF                         ;01AC27|C9FF    |      ;
                       BEQ CODE_01AC58                     ;01AC29|F02D    |01AC58;
                       TAY                                 ;01AC2B|A8      |      ;
                       LDA.L DATA8_06BD79,X                ;01AC2C|BF79BD06|06BD79;
                       TAX                                 ;01AC30|AA      |      ;
                       LDA.W $D0F4,X                      ;01AC31|BDF4D0  |7FD0F4;
                       STA.W $D0F4,Y                      ;01AC34|99F4D0  |7FD0F4;
                       PHP                                 ;01AC37|08      |      ;
                       REP #$30                           ;01AC38|C230    |      ;
                       JSR.W CODE_01AC5C                   ;01AC3A|205CAC  |01AC5C;
                       LDA.W $D174,X                      ;01AC3D|BD74D1  |7FD174;
                       STA.W $D174,Y                      ;01AC40|9974D1  |7FD174;
                       JSR.W CODE_01AC5C                   ;01AC43|205CAC  |01AC5C;
                       LDA.W $CEF4,X                      ;01AC46|BDF4CE  |7FCEF4;
                       STA.W $CEF4,Y                      ;01AC49|99F4CE  |7FCEF4;
                       LDA.W $CEF6,X                      ;01AC4C|BDF6CE  |7FCEF6;
                       STA.W $CEF6,Y                      ;01AC4F|99F6CE  |7FCEF6;
                       PLP                                 ;01AC52|28      |      ;
                       PLX                                 ;01AC53|FA      |      ;
                       INX                                 ;01AC54|E8      |      ;
                       INX                                 ;01AC55|E8      |      ;
                       BRA CODE_01AC1F                     ;01AC56|80C7    |01AC1F;

CODE_01AC58:
                       PLX                                 ;01AC58|FA      |      ;
                       PLP                                 ;01AC59|28      |      ;
                       PLB                                 ;01AC5A|AB      |      ;
                       RTS                                 ;01AC5B|60      |      ;

; ==============================================================================
; Character Index Transformation
; Transforms character indices for data table access
; ==============================================================================

CODE_01AC5C:
                       TYA                                 ;01AC5C|98      |      ;
                       ASL A                               ;01AC5D|0A      |      ;
                       TAY                                 ;01AC5E|A8      |      ;
                       TXA                                 ;01AC5F|8A      |      ;
                       ASL A                               ;01AC60|0A      |      ;
                       TAX                                 ;01AC61|AA      |      ;
                       RTS                                 ;01AC62|60      |      ;

; ==============================================================================
; Advanced Character System Dispatcher
; Central dispatcher for character-based battle operations
; ==============================================================================

                       db $AD,$EE,$19,$29,$FF,$00,$E2,$20,$C2,$10,$8D,$19,$19,$60 ; 01AC63

CODE_01AC71:
                       LDA.W $19EE                        ;01AC71|ADEE19  |0119EE;
                       AND.W #$00FF                       ;01AC74|29FF00  |      ;
                       ASL A                               ;01AC77|0A      |      ;
                       TAX                                 ;01AC78|AA      |      ;
                       JSR.W (UNREACH_01AC7D,X)            ;01AC79|FC7DAC  |01AC7D;
                       RTS                                 ;01AC7C|60      |      ;

; ==============================================================================
; Character System Jump Table
; Jump table for various character-based operations
; ==============================================================================

UNREACH_01AC7D:
                       db $15,$F6,$4A,$F8,$17,$B8,$29,$B8,$A5,$C3,$A5,$C3,$A5,$C3,$7D,$DA ; 01AC7D
                       db $D6,$D6,$A5,$C3,$A5,$C3,$A5,$C3,$A5,$C3,$A5,$C3,$E1,$D6,$A5,$C3 ; 01AC8D
                       db $A5,$C3,$A5,$C3,$4A,$B8,$2D,$D8,$C6,$B8,$A5,$D9,$DC,$B8,$A5,$C3 ; 01AC9D
                       db $95,$D9,$3B,$DC,$A5,$C3,$36,$F9,$0A,$F7,$E5,$B8,$0D,$B9,$35,$B9 ; 01ACAD
                       db $5D,$B9,$22,$DA,$85,$B9,$94,$B9,$A3,$B9,$B2,$B9,$1B,$D9,$86,$F6 ; 01ACBD
                       db $CE,$F7,$A5,$C3,$46,$F6,$C1,$B9,$71,$BA,$95,$F5,$D5,$F5          ; 01ACCD

; ==============================================================================
; Special Battle System Handler
; Handles special battle operations and state management
; ==============================================================================

CODE_01ACDB:
                       SEP #$20                           ;01ACDB|E220    |      ;
                       REP #$10                           ;01ACDD|C210    |      ;
                       LDA.B #$03                         ;01ACDF|A903    |      ;
                       STA.W $19F6                        ;01ACE1|8DF619  |0119F6;
                       STA.W $050B                        ;01ACE4|8D0B05  |01050B;
                       LDA.B #$F5                         ;01ACE7|A9F5    |      ;
                       STA.W $050A                        ;01ACE9|8D0A05  |01050A;
                       RTS                                 ;01ACEC|60      |      ;

; ==============================================================================
; Battle Graphics Loading System
; Complex graphics loading for battle scenes and characters
; ==============================================================================

CODE_01ACED:
                       PHB                                 ;01ACED|8B      |      ;
                       LDX.W #$02F0                       ;01ACEE|A2F002  |      ;
                       LDY.W #$C508                       ;01ACF1|A008C5  |      ;
                       PEA.W $7F00                        ;01ACF4|F4007F  |017F00;
                       PLB                                 ;01ACF7|AB      |      ;
                       PLB                                 ;01ACF8|AB      |      ;
                       LDA.W #$0008                       ;01ACF9|A90800  |      ;

; ==============================================================================
; Graphics Data Transfer Loop
; Transfers graphics data blocks with address management
; ==============================================================================

CODE_01ACFC:
                       PHA                                 ;01ACFC|48      |      ;
                       LDA.L DATA8_07D824,X                ;01ACFD|BF24D807|07D824;
                       STA.W $0000,Y                      ;01AD01|990000  |7F0000;
                       INX                                 ;01AD04|E8      |      ;
                       INX                                 ;01AD05|E8      |      ;
                       INY                                 ;01AD06|C8      |      ;
                       INY                                 ;01AD07|C8      |      ;
                       PLA                                 ;01AD08|68      |      ;
                       DEC A                               ;01AD09|3A      |      ;
                       BNE CODE_01ACFC                     ;01AD0A|D0F0    |01ACFC;
                       PLB                                 ;01AD0C|AB      |      ;
                       RTS                                 ;01AD0D|60      |      ;

; ==============================================================================
; Battle Scene Setup and Management
; Coordinates battle scene initialization and state management
; ==============================================================================

CODE_01AD0E:
                       LDX.W #$0005                       ;01AD0E|A20500  |      ;
                       STX.W $192B                        ;01AD11|8E2B19  |01192B;

CODE_01AD14:
                       JSR.W CODE_01ACED                   ;01AD14|20EDAC  |01ACED;
                       JSR.W CODE_01AD78                   ;01AD17|2078AD  |01AD78;
                       LDA.W #$0004                       ;01AD1A|A90400  |      ;
                       JSR.W CODE_01D6C4                   ;01AD1D|20C4D6  |01D6C4;
                       LDY.W #$0008                       ;01AD20|A00800  |      ;
                       LDX.W #$0000                       ;01AD23|A20000  |      ;
                       LDA.W #$FFFF                       ;01AD26|A9FFFF  |      ;

; ==============================================================================
; Memory Initialization Loop
; Initializes memory regions for battle data
; ==============================================================================

CODE_01AD29:
                       STA.L $7FC508,X                    ;01AD29|9F08C57F|7FC508;
                       INX                                 ;01AD2D|E8      |      ;
                       INX                                 ;01AD2E|E8      |      ;
                       DEY                                 ;01AD2F|88      |      ;
                       BNE CODE_01AD29                     ;01AD30|D0F7    |01AD29;
                       JSR.W CODE_01AD78                   ;01AD32|2078AD  |01AD78;
                       LDA.W #$0004                       ;01AD35|A90400  |      ;
                       JSR.W CODE_01D6C4                   ;01AD38|20C4D6  |01D6C4;
                       DEC.W $192B                        ;01AD3B|CE2B19  |01192B;
                       BNE CODE_01AD14                     ;01AD3E|D0D4    |01AD14;
                       LDX.W #$001F                       ;01AD40|A21F00  |      ;
                       STX.W $1935                        ;01AD43|8E3519  |011935;

; ==============================================================================
; Advanced Data Processing Loop
; Complex data processing with mathematical operations
; ==============================================================================

CODE_01AD46:
                       LDX.W #$0000                       ;01AD46|A20000  |      ;
                       LDY.W #$0008                       ;01AD49|A00800  |      ;

CODE_01AD4C:
                       LDA.L $7FC508,X                    ;01AD4C|BF08C57F|7FC508;
                       STA.W $192B                        ;01AD50|8D2B19  |01192B;
                       LDA.L DATA8_07DB14,X                ;01AD53|BF14DB07|07DB14;
                       STA.W $192D                        ;01AD57|8D2D19  |01192D;
                       JSR.W CODE_01D23C                   ;01AD5A|203CD2  |01D23C;
                       LDA.W $192F                        ;01AD5D|AD2F19  |01192F;
                       STA.L $7FC508,X                    ;01AD60|9F08C57F|7FC508;
                       INX                                 ;01AD64|E8      |      ;
                       INX                                 ;01AD65|E8      |      ;
                       DEY                                 ;01AD66|88      |      ;
                       BNE CODE_01AD4C                     ;01AD67|D0E3    |01AD4C;
                       JSR.W CODE_01AD78                   ;01AD69|2078AD  |01AD78;
                       LDA.W #$0004                       ;01AD6C|A90400  |      ;
                       JSR.W CODE_01D6BD                   ;01AD6F|20BDD6  |01D6BD;
                       DEC.W $1935                        ;01AD72|CE3519  |011935;
                       BNE CODE_01AD46                     ;01AD75|D0CF    |01AD46;
                       RTS                                 ;01AD77|60      |      ;

; ==============================================================================
; Battle System State Handler
; Manages battle system state transitions and timing
; ==============================================================================

CODE_01AD78:
                       PHP                                 ;01AD78|08      |      ;
                       SEP #$20                           ;01AD79|E220    |      ;
                       REP #$10                           ;01AD7B|C210    |      ;
                       JSR.W CODE_018DF3                   ;01AD7D|20F38D  |018DF3;
                       LDA.B #$01                         ;01AD80|A901    |      ;
                       STA.W $1A46                        ;01AD82|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01AD85|20F38D  |018DF3;
                       PLP                                 ;01AD88|28      |      ;
                       RTS                                 ;01AD89|60      |      ;

; ==============================================================================
; Special Effect Coordination System
; Coordinates special effects and timing for battle scenes
; ==============================================================================

CODE_01AD8A:
                       PHP                                 ;01AD8A|08      |      ;
                       SEP #$20                           ;01AD8B|E220    |      ;
                       REP #$10                           ;01AD8D|C210    |      ;
                       LDA.B #$80                         ;01AD8F|A980    |      ;
                       STA.W $050B                        ;01AD91|8D0B05  |01050B;
                       LDA.B #$81                         ;01AD94|A981    |      ;
                       STA.W $050A                        ;01AD96|8D0A05  |01050A;
                       LDA.B #$14                         ;01AD99|A914    |      ;
                       JSR.W CODE_01D6BD                   ;01AD9B|20BDD6  |01D6BD;
                       PLP                                 ;01AD9E|28      |      ;
                       RTS                                 ;01AD9F|60      |      ;

; ==============================================================================
; Battle Command Processing Hub  
; Central hub for processing battle commands and actions
; ==============================================================================

                       db $AD,$09,$06,$8D,$EE,$19,$4C,$92,$BA          ; 01ADA0

CODE_01ADA9:
                       SEP #$20                           ;01ADA9|E220    |      ;
                       REP #$10                           ;01ADAB|C210    |      ;
                       JSR.W CODE_01D2DF                   ;01ADAD|20DFD2  |01D2DF;
                       JSR.W CODE_01D35D                   ;01ADB0|205DD3  |01D35D;
                       JSR.W CODE_01D3A6                   ;01ADB3|20A6D3  |01D3A6;
                       LDX.W #$463C                       ;01ADB6|A23C46  |      ;
                       STX.W $19EE                        ;01ADB9|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADBC|20B2BE  |01BEB2;
                       LDX.W #$463D                       ;01ADBF|A23D46  |      ;
                       STX.W $19EE                        ;01ADC2|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADC5|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01ADC8|20CDD3  |01D3CD;
                       LDA.B #$0C                         ;01ADCB|A90C    |      ;
                       JSR.W CODE_01D49B                   ;01ADCD|209BD4  |01D49B;
                       RTS                                 ;01ADD0|60      |      ;
