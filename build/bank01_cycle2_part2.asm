; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 2)
; Advanced Sound Effect Processing and Graphics Animation
; ==============================================================================

; ==============================================================================
; Primary Sound Effect Processing System
; Complex sound channel management with battle coordination and timing
; ==============================================================================

CODE_01A2A6:
                       PHB                                 ;01A2A6|8B      |      ;
                       PHP                                 ;01A2A7|08      |      ;
                       PHD                                 ;01A2A8|0B      |      ;
                       SEP #$20                           ;01A2A9|E220    |      ;
                       REP #$10                           ;01A2AB|C210    |      ;
                       LDA.W $19DF                        ;01A2AD|ADDF19  |0119DF;
                       CMP.B #$FF                         ;01A2B0|C9FF    |      ;
                       BEQ CODE_01A2C9                     ;01A2B2|F015    |01A2C9;
                       PEA.W $1CD7                        ;01A2B4|F4D71C  |011CD7;
                       PLD                                 ;01A2B7|2B      |      ;
                       LDY.W #$0007                       ;01A2B8|A00700  |      ;
                       STY.B $06                          ;01A2BB|8406    |001CDD;
                       LDX.W #$0000                       ;01A2BD|A20000  |      ;
                       STX.B $00                          ;01A2C0|8600    |001CD7;
                       LDX.W $19DE                        ;01A2C2|AEDE19  |0119DE;
                       STX.B $02                          ;01A2C5|8602    |001CD9;
                       BPL CODE_01A2CD                     ;01A2C7|1004    |01A2CD;

CODE_01A2C9:
                       PLD                                 ;01A2C9|2B      |      ;
                       PLP                                 ;01A2CA|28      |      ;
                       PLB                                 ;01A2CB|AB      |      ;
                       RTS                                 ;01A2CC|60      |      ;

; ==============================================================================
; Sound Data Processing Loop
; Main audio processing routine with data validation and channel management
; ==============================================================================

CODE_01A2CD:
                       SEP #$20                           ;01A2CD|E220    |      ;
                       REP #$10                           ;01A2CF|C210    |      ;
                       LDX.B $02                          ;01A2D1|A602    |001CD9;
                       LDA.L DATA8_0CD694,X                ;01A2D3|BF94D60C|0CD694;
                       CMP.B #$FF                         ;01A2D7|C9FF    |      ;
                       BEQ CODE_01A32E                     ;01A2D9|F053    |01A32E;
                       STA.B $04                          ;01A2DB|8504    |001CDB;
                       LDX.B $00                          ;01A2DD|A600    |001CD7;
                       LDA.L $7FCED8,X                    ;01A2DF|BFD8CE7F|7FCED8;
                       CMP.B $04                          ;01A2E3|C504    |001CDB;
                       BCC CODE_01A32E                     ;01A2E5|9047    |01A32E;
                       LDA.B #$00                         ;01A2E7|A900    |      ;
                       STA.L $7FCED8,X                    ;01A2E9|9FD8CE7F|7FCED8;
                       XBA                                 ;01A2ED|EB      |      ;
                       LDA.L $7FCED9,X                    ;01A2EE|BFD9CE7F|7FCED9;
                       REP #$30                           ;01A2F2|C230    |      ;
                       CLC                                 ;01A2F4|18      |      ;
                       ADC.B $02                          ;01A2F5|6502    |001CD9;
                       INC A                               ;01A2F7|1A      |      ;
                       INC A                               ;01A2F8|1A      |      ;
                       TAX                                 ;01A2F9|AA      |      ;
                       LDA.L DATA8_0CD694,X                ;01A2FA|BF94D60C|0CD694;
                       AND.W #$00FF                       ;01A2FE|29FF00  |      ;
                       ASL A                               ;01A301|0A      |      ;
                       TAX                                 ;01A302|AA      |      ;
                       LDA.L DATA8_058A80,X                ;01A303|BF808A05|058A80;
                       LDX.B $00                          ;01A307|A600    |001CD7;
                       STA.L $7FC5FA,X                    ;01A309|9FFAC57F|7FC5FA;
                       SEP #$20                           ;01A30D|E220    |      ;
                       REP #$10                           ;01A30F|C210    |      ;
                       LDX.B $00                          ;01A311|A600    |001CD7;
                       LDA.L $7FCED9,X                    ;01A313|BFD9CE7F|7FCED9;
                       INC A                               ;01A317|1A      |      ;
                       STA.B $04                          ;01A318|8504    |001CDB;
                       PHX                                 ;01A31A|DA      |      ;
                       LDX.B $02                          ;01A31B|A602    |001CD9;
                       LDA.L DATA8_0CD695,X                ;01A31D|BF95D60C|0CD695;
                       CMP.B $04                          ;01A321|C504    |001CDB;
                       BCS CODE_01A327                     ;01A323|B002    |01A327;
                       STZ.B $04                          ;01A325|6404    |001CDB;

CODE_01A327:
                       PLX                                 ;01A327|FA      |      ;
                       LDA.B $04                          ;01A328|A504    |001CDB;
                       STA.L $7FCED9,X                    ;01A32A|9FD9CE7F|7FCED9;

; ==============================================================================
; Audio Channel Iterator and Data Validation
; Advances to next sound channel and validates data integrity
; ==============================================================================

CODE_01A32E:
                       DEC.B $06                          ;01A32E|C606    |001CDD;
                       BNE CODE_01A335                     ;01A330|D003    |01A335;
                       JMP.W CODE_01A2C9                   ;01A332|4CC9A2  |01A2C9;

CODE_01A335:
                       LDX.B $00                          ;01A335|A600    |001CD7;
                       INX                                 ;01A337|E8      |      ;
                       INX                                 ;01A338|E8      |      ;
                       STX.B $00                          ;01A339|8600    |001CD7;
                       LDX.B $02                          ;01A33B|A602    |001CD9;

CODE_01A33D:
                       LDA.L DATA8_0CD694,X                ;01A33D|BF94D60C|0CD694;
                       INX                                 ;01A341|E8      |      ;
                       CMP.B #$FF                         ;01A342|C9FF    |      ;
                       BNE CODE_01A33D                     ;01A344|D0F7    |01A33D;
                       STX.B $02                          ;01A346|8602    |001CD9;
                       JMP.W CODE_01A2CD                   ;01A348|4CCDA2  |01A2CD;

; ==============================================================================
; Secondary Sound Effect Processing System
; Alternate sound channel processing for complex multi-layer audio
; ==============================================================================

CODE_01A34B:
                       PHB                                 ;01A34B|8B      |      ;
                       PHP                                 ;01A34C|08      |      ;
                       PHD                                 ;01A34D|0B      |      ;
                       SEP #$20                           ;01A34E|E220    |      ;
                       REP #$10                           ;01A350|C210    |      ;
                       LDA.W $19E1                        ;01A352|ADE119  |0119E1;
                       CMP.B #$FF                         ;01A355|C9FF    |      ;
                       BEQ CODE_01A36E                     ;01A357|F015    |01A36E;
                       PEA.W $1CD7                        ;01A359|F4D71C  |011CD7;
                       PLD                                 ;01A35C|2B      |      ;
                       LDY.W #$0007                       ;01A35D|A00700  |      ;
                       STY.B $06                          ;01A360|8406    |001CDD;
                       LDX.W #$0000                       ;01A362|A20000  |      ;
                       STX.B $00                          ;01A365|8600    |001CD7;
                       LDX.W $19E0                        ;01A367|AEE019  |0119E0;
                       STX.B $02                          ;01A36A|8602    |001CD9;
                       BPL CODE_01A372                     ;01A36C|1004    |01A372;

CODE_01A36E:
                       PLD                                 ;01A36E|2B      |      ;
                       PLP                                 ;01A36F|28      |      ;
                       PLB                                 ;01A370|AB      |      ;
                       RTS                                 ;01A371|60      |      ;

; ==============================================================================
; Secondary Audio Data Processing
; Mirror of primary system for layered audio effects during battle
; ==============================================================================

CODE_01A372:
                       SEP #$20                           ;01A372|E220    |      ;
                       REP #$10                           ;01A374|C210    |      ;
                       LDX.B $02                          ;01A376|A602    |001CD9;
                       LDA.L DATA8_0CD72F,X                ;01A378|BF2FD70C|0CD72F;
                       CMP.B #$FF                         ;01A37C|C9FF    |      ;
                       BEQ CODE_01A3D3                     ;01A37E|F053    |01A3D3;
                       STA.B $04                          ;01A380|8504    |001CDB;
                       LDX.B $00                          ;01A382|A600    |001CD7;
                       LDA.L $7FCEE6,X                    ;01A384|BFE6CE7F|7FCEE6;
                       CMP.B $04                          ;01A388|C504    |001CDB;
                       BCC CODE_01A3D3                     ;01A38A|9047    |01A3D3;
                       LDA.B #$00                         ;01A38C|A900    |      ;
                       STA.L $7FCEE6,X                    ;01A38E|9FE6CE7F|7FCEE6;
                       XBA                                 ;01A392|EB      |      ;
                       LDA.L $7FCEE7,X                    ;01A393|BFE7CE7F|7FCEE7;
                       REP #$30                           ;01A397|C230    |      ;
                       CLC                                 ;01A399|18      |      ;
                       ADC.B $02                          ;01A39A|6502    |001CD9;
                       INC A                               ;01A39C|1A      |      ;
                       INC A                               ;01A39D|1A      |      ;
                       TAX                                 ;01A39E|AA      |      ;
                       LDA.L DATA8_0CD72F,X                ;01A39F|BF2FD70C|0CD72F;
                       AND.W #$00FF                       ;01A3A3|29FF00  |      ;
                       ASL A                               ;01A3A6|0A      |      ;
                       TAX                                 ;01A3A7|AA      |      ;
                       LDA.L DATA8_058A80,X                ;01A3A8|BF808A05|058A80;
                       LDX.B $00                          ;01A3AC|A600    |001CD7;
                       STA.L $7FC52A,X                    ;01A3AE|9F2AC57F|7FC52A;
                       SEP #$20                           ;01A3B2|E220    |      ;
                       REP #$10                           ;01A3B4|C210    |      ;
                       LDX.B $00                          ;01A3B6|A600    |001CD7;
                       LDA.L $7FCEE7,X                    ;01A3B8|BFE7CE7F|7FCEE7;
                       INC A                               ;01A3BC|1A      |      ;
                       STA.B $04                          ;01A3BD|8504    |001CDB;
                       PHX                                 ;01A3BF|DA      |      ;
                       LDX.B $02                          ;01A3C0|A602    |001CD9;
                       LDA.L DATA8_0CD730,X                ;01A3C2|BF30D70C|0CD730;
                       CMP.B $04                          ;01A3C6|C504    |001CDB;
                       BCS CODE_01A3CC                     ;01A3C8|B002    |01A3CC;
                       STZ.B $04                          ;01A3CA|6404    |001CDB;

CODE_01A3CC:
                       PLX                                 ;01A3CC|FA      |      ;
                       LDA.B $04                          ;01A3CD|A504    |001CDB;
                       STA.L $7FCEE7,X                    ;01A3CF|9FE7CE7F|7FCEE7;

; ==============================================================================
; Secondary Audio Channel Processing
; Iterator and validation for second audio layer
; ==============================================================================

CODE_01A3D3:
                       DEC.B $06                          ;01A3D3|C606    |001CDD;
                       BNE CODE_01A3DA                     ;01A3D5|D003    |01A3DA;
                       JMP.W CODE_01A36E                   ;01A3D7|4C6EA3  |01A36E;

CODE_01A3DA:
                       LDX.B $00                          ;01A3DA|A600    |001CD7;
                       INX                                 ;01A3DC|E8      |      ;
                       INX                                 ;01A3DD|E8      |      ;
                       STX.B $00                          ;01A3DE|8600    |001CD7;
                       LDX.B $02                          ;01A3E0|A602    |001CD9;

CODE_01A3E2:
                       LDA.L DATA8_0CD72F,X                ;01A3E2|BF2FD70C|0CD72F;
                       INX                                 ;01A3E6|E8      |      ;
                       CMP.B #$FF                         ;01A3E7|C9FF    |      ;
                       BNE CODE_01A3E2                     ;01A3E9|D0F7    |01A3E2;
                       STX.B $02                          ;01A3EB|8602    |001CD9;
                       JMP.W CODE_01A372                   ;01A3ED|4C72A3  |01A372;

; ==============================================================================
; Main Battle Animation Controller
; Coordinates all sprite animation and graphics updates during battle
; ==============================================================================

CODE_01A3F0:
                       PHP                                 ;01A3F0|08      |      ;
                       PHB                                 ;01A3F1|8B      |      ;
                       REP #$30                           ;01A3F2|C230    |      ;
                       LDA.W $19B9                        ;01A3F4|ADB919  |0119B9;
                       BMI CODE_01A401                     ;01A3F7|3008    |01A401;
                       SEP #$20                           ;01A3F9|E220    |      ;
                       JSR.W CODE_01A423                   ;01A3FB|2023A4  |01A423;
                       JSR.W CODE_01A9EE                   ;01A3FE|20EEA9  |01A9EE;

CODE_01A401:
                       PLB                                 ;01A401|AB      |      ;
                       PLP                                 ;01A402|28      |      ;
                       RTS                                 ;01A403|60      |      ;

; ==============================================================================
; Extended Battle Animation Handler
; Enhanced animation processing with additional graphics coordination
; ==============================================================================

CODE_01A404:
                       PHP                                 ;01A404|08      |      ;
                       PHB                                 ;01A405|8B      |      ;
                       REP #$30                           ;01A406|C230    |      ;
                       LDA.W $19B9                        ;01A408|ADB919  |0119B9;
                       BMI CODE_01A420                     ;01A40B|3013    |01A420;
                       SEP #$20                           ;01A40D|E220    |      ;
                       JSR.W CODE_01A423                   ;01A40F|2023A4  |01A423;
                       JSR.W CODE_01A692                   ;01A412|2092A6  |01A692;
                       JSR.W CODE_01A947                   ;01A415|2047A9  |01A947;
                       JSR.W CODE_01A9EE                   ;01A418|20EEA9  |01A9EE;
                       SEP #$20                           ;01A41B|E220    |      ;
                       STZ.W $1A71                        ;01A41D|9C711A  |001A71;

CODE_01A420:
                       PLB                                 ;01A420|AB      |      ;
                       PLP                                 ;01A421|28      |      ;
                       RTS                                 ;01A422|60      |      ;

; ==============================================================================
; Graphics Preparation and Memory Management
; Major graphics loading system with memory initialization and data transfer
; ==============================================================================

CODE_01A423:
                       REP #$30                           ;01A423|C230    |      ;
                       PHD                                 ;01A425|0B      |      ;
                       PEA.W $192B                        ;01A426|F42B19  |01192B;
                       PLD                                 ;01A429|2B      |      ;
                       PHB                                 ;01A42A|8B      |      ;
                       LDA.W #$0000                       ;01A42B|A90000  |      ;
                       STA.L $7F0000                      ;01A42E|8F00007F|7F0000;
                       LDX.W #$0000                       ;01A432|A20000  |      ;
                       LDY.W #$0001                       ;01A435|A00100  |      ;
                       LDA.W #$3DFF                       ;01A438|A9FF3D  |      ;
                       MVN $7F,$7F                       ;01A43B|547F7F  |      ;
                       PLB                                 ;01A43E|AB      |      ;
                       SEP #$20                           ;01A43F|E220    |      ;
                       REP #$10                           ;01A441|C210    |      ;
                       LDA.B #$06                         ;01A443|A906    |      ;
                       STA.B $0A                          ;01A445|850A    |001935;
                       STZ.B $0C                          ;01A447|640C    |001937;
                       LDA.B #$0C                         ;01A449|A90C    |      ;
                       STA.B $0B                          ;01A44B|850B    |001936;
                       LDX.W #$C488                       ;01A44D|A288C4  |      ;
                       STX.B $00                          ;01A450|8600    |00192B;
                       LDY.W #$0006                       ;01A452|A00600  |      ;
                       LDX.W $19B9                        ;01A455|AEB919  |0119B9;
                       REP #$30                           ;01A458|C230    |      ;

; ==============================================================================
; Graphics Data Loading Loop
; Processes character graphics and transfers to VRAM with complex addressing
; ==============================================================================

CODE_01A45A:
                       LDA.L DATA8_0B88FC,X                ;01A45A|BFFC880B|0B88FC;
                       AND.W #$00FF                       ;01A45E|29FF00  |      ;
                       ASL A                               ;01A461|0A      |      ;
                       ASL A                               ;01A462|0A      |      ;
                       ASL A                               ;01A463|0A      |      ;
                       ASL A                               ;01A464|0A      |      ;
                       CLC                                 ;01A465|18      |      ;
                       ADC.W #$D824                       ;01A466|6924D8  |      ;
                       PHX                                 ;01A469|DA      |      ;
                       PHY                                 ;01A46A|5A      |      ;
                       PHB                                 ;01A46B|8B      |      ;
                       LDY.B $00                          ;01A46C|A400    |00192B;
                       TAX                                 ;01A46E|AA      |      ;
                       LDA.W #$000F                       ;01A46F|A90F00  |      ;
                       MVN $7F,$07                       ;01A472|547F07  |      ;
                       PLB                                 ;01A475|AB      |      ;
                       PLY                                 ;01A476|7A      |      ;
                       PLX                                 ;01A477|FA      |      ;
                       INX                                 ;01A478|E8      |      ;
                       LDA.B $00                          ;01A479|A500    |00192B;
                       CLC                                 ;01A47B|18      |      ;
                       ADC.W #$0020                       ;01A47C|692000  |      ;
                       STA.B $00                          ;01A47F|8500    |00192B;
                       DEY                                 ;01A481|88      |      ;
                       BNE CODE_01A45A                     ;01A482|D0D6    |01A45A;
                       REP #$30                           ;01A484|C230    |      ;
                       PEA.W $0004                        ;01A486|F40400  |010004;
                       PLB                                 ;01A489|AB      |      ;
                       LDA.W #$0010                       ;01A48A|A91000  |      ;
                       STA.B $14                          ;01A48D|8514    |00193F;
                       LDY.W #$E520                       ;01A48F|A020E5  |      ;
                       LDX.W #$0000                       ;01A492|A20000  |      ;
