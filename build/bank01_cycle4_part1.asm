; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 4, Part 1)
; Advanced Battle UI and Special Effects Management
; ==============================================================================

; ==============================================================================
; Battle UI State Management System
; Manages battle interface states and user input processing
; ==============================================================================

CODE_01ADD1:
                       SEP #$20                           ;01ADD1|E220    |      ;
                       REP #$10                           ;01ADD3|C210    |      ;
                       JSR.W CODE_01D2DF                   ;01ADD5|20DFD2  |01D2DF;
                       JSR.W CODE_01D35D                   ;01ADD8|205DD3  |01D35D;
                       JSR.W CODE_01D3C2                   ;01ADDB|20C2D3  |01D3C2;
                       LDX.W #$4636                       ;01ADDE|A23646  |      ;
                       STX.W $19EE                        ;01ADE1|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADE4|20B2BE  |01BEB2;
                       LDX.W #$4637                       ;01ADE7|A23746  |      ;
                       STX.W $19EE                        ;01ADEA|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADED|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01ADF0|20CDD3  |01D3CD;
                       LDA.B #$06                         ;01ADF3|A906    |      ;
                       JSR.W CODE_01D49B                   ;01ADF5|209BD4  |01D49B;
                       RTS                                 ;01ADF8|60      |      ;

; ==============================================================================
; Special Battle Effects Coordinator
; Coordinates special visual effects and animations for battle
; ==============================================================================

CODE_01ADF9:
                       SEP #$20                           ;01ADF9|E220    |      ;
                       REP #$10                           ;01ADFB|C210    |      ;
                       JSR.W CODE_01D2DF                   ;01ADFD|20DFD2  |01D2DF;
                       JSR.W CODE_01D35D                   ;01AE00|205DD3  |01D35D;
                       JSR.W CODE_01D3C2                   ;01AE03|20C2D3  |01D3C2;
                       LDX.W #$4635                       ;01AE06|A23546  |      ;
                       STX.W $19EE                        ;01AE09|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE0C|20B2BE  |01BEB2;
                       LDX.W #$4636                       ;01AE0F|A23646  |      ;
                       STX.W $19EE                        ;01AE12|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE15|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01AE18|20CDD3  |01D3CD;
                       LDA.B #$05                         ;01AE1B|A905    |      ;
                       JSR.W CODE_01D49B                   ;01AE1D|209BD4  |01D49B;
                       RTS                                 ;01AE20|60      |      ;

; ==============================================================================
; Battle Victory Sequence Manager
; Handles victory animations and state transitions
; ==============================================================================

                       db $E2,$20,$C2,$10,$20,$DF,$D2,$20,$5D,$D3,$20,$A6,$D3,$A2,$34,$46 ; 01AE21

CODE_01AE31:
                       STX.W $19EE                        ;01AE31|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE34|20B2BE  |01BEB2;
                       LDX.W #$4635                       ;01AE37|A23546  |      ;
                       STX.W $19EE                        ;01AE3A|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE3D|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01AE40|20CDD3  |01D3CD;
                       LDA.B #$04                         ;01AE43|A904    |      ;
                       JSR.W CODE_01D49B                   ;01AE45|209BD4  |01D49B;
                       RTS                                 ;01AE48|60      |      ;

; ==============================================================================
; Battle Scene Transition System
; Complex scene transition management for battle flow
; ==============================================================================

CODE_01AE49:
                       LDX.W #$0004                       ;01AE49|A20400  |      ;
                       STX.W $1935                        ;01AE4C|8E3519  |011935;
                       LDA.W #$0005                       ;01AE4F|A90500  |      ;
                       STA.W $1937                        ;01AE52|8D3719  |011937;
                       JMP.W CODE_01CCE8                   ;01AE55|4CE8CC  |01CCE8;

CODE_01AE58:
                       LDX.W #$0602                       ;01AE58|A20206  |      ;
                       STX.W $1935                        ;01AE5B|8E3519  |011935;
                       LDA.W #$0003                       ;01AE5E|A90300  |      ;
                       STA.W $1937                        ;01AE61|8D3719  |011937;
                       JMP.W CODE_01CCE8                   ;01AE64|4CE8CC  |01CCE8;

                       db $A2,$03,$07,$8E,$35,$19,$A9,$05,$00,$8D,$37,$19,$4C,$E8,$CC ; 01AE67

; ==============================================================================
; Battle Animation Control Hub
; Central hub for coordinating battle animations and timing
; ==============================================================================

CODE_01AE76:
                       SEP #$20                           ;01AE76|E220    |      ;
                       REP #$10                           ;01AE78|C210    |      ;
                       JSR.W CODE_01D120                   ;01AE7A|2020D1  |01D120;
                       BCC CODE_01AE9F                     ;01AE7D|9020    |01AE9F;
                       STZ.W $192B                        ;01AE7F|9C2B19  |01192B;
                       LDY.W #$000C                       ;01AE82|A00C00  |      ;
                       JSR.W CODE_01AEB3                   ;01AE85|20B3AE  |01AEB3;
                       LDA.B #$01                         ;01AE88|A901    |      ;
                       STA.W $192B                        ;01AE8A|8D2B19  |01192B;
                       LDY.W #$0004                       ;01AE8D|A00400  |      ;
                       JSR.W CODE_01AEB3                   ;01AE90|20B3AE  |01AEB3;
                       JSR.W CODE_01AEA0                   ;01AE93|20A0AE  |01AEA0;
                       LDX.W #$4420                       ;01AE96|A22044  |      ;
                       STX.W $19EE                        ;01AE99|8EEE19  |0119EE;
                       JSR.W CODE_01BC1B                   ;01AE9C|201BBC  |01BC1B;

CODE_01AE9F:
                       RTS                                 ;01AE9F|60      |      ;

; ==============================================================================
; Battle State Synchronization
; Synchronizes battle states between different systems
; ==============================================================================

CODE_01AEA0:
                       LDX.W $1935                        ;01AEA0|AE3519  |001935;
                       LDA.W $1938                        ;01AEA3|AD3819  |001938;
                       STA.W $1A72,X                      ;01AEA6|9D721A  |001A72;
                       LDX.W $1939                        ;01AEA9|AE3919  |001939;
                       LDA.W $193C                        ;01AEAC|AD3C19  |00193C;
                       STA.W $1A72,X                      ;01AEAF|9D721A  |001A72;
                       RTS                                 ;01AEB2|60      |      ;

; ==============================================================================
; Advanced Animation Sequence Handler
; Handles complex animation sequences with timing control
; ==============================================================================

CODE_01AEB3:
                       PHY                                 ;01AEB3|5A      |      ;
                       LDX.W $1935                        ;01AEB4|AE3519  |001935;
                       LDA.B #$10                         ;01AEB7|A910    |      ;
                       STA.W $1A72,X                      ;01AEB9|9D721A  |001A72;
                       STA.W $193D                        ;01AEBC|8D3D19  |00193D;
                       LDA.W $1A80,X                      ;01AEBF|BD801A  |001A80;
                       AND.B #$CF                         ;01AEC2|29CF    |      ;
                       STA.W $1A80,X                      ;01AEC4|9D801A  |001A80;
                       LDA.W $192B                        ;01AEC7|AD2B19  |01192B;
                       ASL A                               ;01AECA|0A      |      ;
                       ASL A                               ;01AECB|0A      |      ;
                       ASL A                               ;01AECC|0A      |      ;
                       ASL A                               ;01AECD|0A      |      ;
                       ORA.W $1A80,X                      ;01AECE|1D801A  |001A80;
                       STA.W $1A80,X                      ;01AED1|9D801A  |001A80;
                       JSR.W CODE_01CC82                   ;01AED4|2082CC  |01CC82;
                       LDX.W $1939                        ;01AED7|AE3919  |001939;
                       LDA.W $192B                        ;01AEDA|AD2B19  |01192B;
                       ORA.B #$90                         ;01AEDD|0990    |      ;
                       STA.W $1A72,X                      ;01AEDF|9D721A  |001A72;
                       STA.W $193E                        ;01AEE2|8D3E19  |00193E;
                       JSR.W CODE_01CC82                   ;01AEE5|2082CC  |01CC82;
                       PLY                                 ;01AEE8|7A      |      ;
                       LDX.W $1935                        ;01AEE9|AE3519  |001935;
                       JSR.W CODE_01AEF0                   ;01AEEC|20F0AE  |01AEF0;
                       RTS                                 ;01AEEF|60      |      ;

; ==============================================================================
; Complex Animation Loop Control
; Manages complex animation loops with frame timing
; ==============================================================================

CODE_01AEF0:
                       PHY                                 ;01AEF0|5A      |      ;
                       INC.W $19F7                        ;01AEF1|EEF719  |0119F7;

CODE_01AEF4:
                       PHX                                 ;01AEF4|DA      |      ;
                       PHP                                 ;01AEF5|08      |      ;
                       JSR.W CODE_01CAED                   ;01AEF6|20EDCA  |01CAED;
                       JSR.W CODE_0182D0                   ;01AEF9|20D082  |0182D0;
                       PLP                                 ;01AEFC|28      |      ;
                       PLX                                 ;01AEFD|FA      |      ;
                       LDA.W $1A72,X                      ;01AEFE|BD721A  |001A72;
                       BNE CODE_01AEF4                     ;01AF01|D0F1    |01AEF4;
                       PLY                                 ;01AF03|7A      |      ;
                       DEY                                 ;01AF04|88      |      ;
                       BEQ CODE_01AF25                     ;01AF05|F01E    |01AF25;
                       PHY                                 ;01AF07|5A      |      ;
                       LDX.W $1935                        ;01AF08|AE3519  |001935;
                       LDA.W $193D                        ;01AF0B|AD3D19  |00193D;
                       STA.W $1A72,X                      ;01AF0E|9D721A  |001A72;
                       JSR.W CODE_01CC82                   ;01AF11|2082CC  |01CC82;
                       LDX.W $1939                        ;01AF14|AE3919  |001939;
                       LDA.W $193E                        ;01AF17|AD3E19  |00193E;
                       STA.W $1A72,X                      ;01AF1A|9D721A  |001A72;
                       JSR.W CODE_01CC82                   ;01AF1D|2082CC  |01CC82;
                       INC.W $19F7                        ;01AF20|EEF719  |0119F7;
                       BRA CODE_01AEF4                     ;01AF23|80CF    |01AEF4;

CODE_01AF25:
                       RTS                                 ;01AF25|60      |      ;

; ==============================================================================
; Battle Input Processing System
; Advanced input processing for battle commands and navigation
; ==============================================================================

CODE_01AF26:
                       SEP #$20                           ;01AF26|E220    |      ;
                       REP #$10                           ;01AF28|C210    |      ;
                       JSR.W CODE_01D120                   ;01AF2A|2020D1  |01D120;
                       BCC CODE_01AF46                     ;01AF2D|9017    |01AF46;
                       LDA.B #$01                         ;01AF2F|A901    |      ;
                       STA.W $192B                        ;01AF31|8D2B19  |01192B;
                       LDY.W #$0003                       ;01AF34|A00300  |      ;
                       JSR.W CODE_01AEB3                   ;01AF37|20B3AE  |01AEB3;
                       STZ.W $192B                        ;01AF3A|9C2B19  |01192B;
                       LDY.W #$0002                       ;01AF3D|A00200  |      ;
                       JSR.W CODE_01AEB3                   ;01AF40|20B3AE  |01AEB3;
                       JSR.W CODE_01AEA0                   ;01AF43|20A0AE  |01AEA0;

CODE_01AF46:
                       RTS                                 ;01AF46|60      |      ;

; ==============================================================================
; Sound Effect Integration System  
; Integrates sound effects with battle events and animations
; ==============================================================================

CODE_01AF47:
                       LDA.W #$0F08                       ;01AF47|A9080F  |      ;
                       STA.W $0501                        ;01AF4A|8D0105  |010501;
                       PHP                                 ;01AF4D|08      |      ;
                       SEP #$20                           ;01AF4E|E220    |      ;
                       REP #$10                           ;01AF50|C210    |      ;
                       LDA.W $19EE                        ;01AF52|ADEE19  |0119EE;
                       AND.B #$1F                         ;01AF55|291F    |      ;
                       STA.W $0500                        ;01AF57|8D0005  |010500;
                       PLP                                 ;01AF5A|28      |      ;
                       RTS                                 ;01AF5B|60      |      ;

; ==============================================================================
; Advanced Audio Management System
; Complex audio management for battle scenes and effects
; ==============================================================================

CODE_01AF5C:
                       LDA.W $19EE                        ;01AF5C|ADEE19  |0119EE;
                       AND.W #$00FF                       ;01AF5F|29FF00  |      ;

CODE_01AF62:
                       PHX                                 ;01AF62|DA      |      ;
                       PHP                                 ;01AF63|08      |      ;
                       SEP #$20                           ;01AF64|E220    |      ;
                       REP #$10                           ;01AF66|C210    |      ;
                       LDX.W #$880F                       ;01AF68|A20F88  |      ;
                       STX.W $0506                        ;01AF6B|8E0605  |010506;
                       STA.W $0505                        ;01AF6E|8D0505  |010505;
                       PLP                                 ;01AF71|28      |      ;
                       PLX                                 ;01AF72|FA      |      ;
                       RTS                                 ;01AF73|60      |      ;

; ==============================================================================
; Battle State Control Registry
; Central registry for battle state management and coordination
; ==============================================================================

                       db $E2,$20,$C2,$10,$AD,$EE,$19,$8D,$15,$19,$60 ; 01AF74

CODE_01AF7F:
                       PHP                                 ;01AF7F|08      |      ;
                       SEP #$20                           ;01AF80|E220    |      ;
                       REP #$10                           ;01AF82|C210    |      ;
                       LDA.W $19EE                        ;01AF84|ADEE19  |0119EE;
                       STA.W $0E88                        ;01AF87|8D880E  |010E88;
                       PLP                                 ;01AF8A|28      |      ;
                       RTS                                 ;01AF8B|60      |      ;

; ==============================================================================
; Special Battle Event Handler
; Handles special battle events like critical hits and status effects
; ==============================================================================

CODE_01AF8C:
                       SEP #$20                           ;01AF8C|E220    |      ;
                       REP #$10                           ;01AF8E|C210    |      ;
                       LDA.B #$22                         ;01AF90|A922    |      ;
                       STA.W $19EF                        ;01AF92|8DEF19  |0119EF;
                       JSR.W CODE_01B73C                   ;01AF95|203CB7  |01B73C;
                       JSR.W CODE_01C6A1                   ;01AF98|20A1C6  |01C6A1;
                       RTS                                 ;01AF9B|60      |      ;

; ==============================================================================
; Advanced Battle Victory Processing
; Complex victory processing with rewards and experience calculation
; ==============================================================================

                       db $AD,$EE,$19,$29,$FF,$00,$09,$00,$23,$8D,$EE,$19,$20,$43,$B7,$20 ; 01AF9C
                       db $A1,$C6,$60                   ; 01AFAC

; ==============================================================================
; Character Validation and Setup Engine
; Comprehensive character validation with battle setup
; ==============================================================================

CODE_01AFAF:
                       SEP #$20                           ;01AFAF|E220    |      ;
                       REP #$10                           ;01AFB1|C210    |      ;
                       LDA.W $19EE                        ;01AFB3|ADEE19  |0119EE;
                       JSR.W CODE_01B1EB                   ;01AFB6|20EBB1  |01B1EB;
                       BCC CODE_01B008                     ;01AFB9|904D    |01B008;
                       STA.W $192D                        ;01AFBB|8D2D19  |01192D;
                       LDA.W $1A80,X                      ;01AFBE|BD801A  |001A80;
                       AND.B #$CF                         ;01AFC1|29CF    |      ;
                       ORA.B #$10                         ;01AFC3|0910    |      ;
                       STA.W $1A80,X                      ;01AFC5|9D801A  |001A80;
                       LDA.W $1A82,X                      ;01AFC8|BD821A  |001A82;
                       REP #$30                           ;01AFCB|C230    |      ;
                       AND.W #$00FF                       ;01AFCD|29FF00  |      ;
                       ASL A                               ;01AFD0|0A      |      ;
                       PHX                                 ;01AFD1|DA      |      ;
                       TAX                                 ;01AFD2|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01AFD3|BFCAFD00|00FDCA;
                       CLC                                 ;01AFD7|18      |      ;
                       ADC.W #$0008                       ;01AFD8|690800  |      ;
                       TAY                                 ;01AFDB|A8      |      ;
                       PLX                                 ;01AFDC|FA      |      ;
                       JSR.W CODE_01AE8A                   ;01AFDD|208AAE  |01AE8A;
                       LDA.W $192D                        ;01AFE0|AD2D19  |01192D;
                       AND.W #$00FF                       ;01AFE3|29FF00  |      ;
                       ASL A                               ;01AFE6|0A      |      ;
                       ASL A                               ;01AFE7|0A      |      ;
                       PHX                                 ;01AFE8|DA      |      ;
                       TAX                                 ;01AFE9|AA      |      ;
                       LDA.L DATA8_01A63A,X                ;01AFEA|BF3AA601|01A63A;
                       TAY                                 ;01AFEE|A8      |      ;
                       PLX                                 ;01AFEF|FA      |      ;
                       LDA.W $1A73,X                      ;01AFF0|BD731A  |001A73;
                       STA.W $0C02,Y                      ;01AFF3|99020C  |010C02;
                       LDA.W $1A75,X                      ;01AFF6|BD751A  |001A75;
                       STA.W $0C06,Y                      ;01AFF9|99060C  |010C06;
                       LDA.W $1A77,X                      ;01AFFC|BD771A  |001A77;
                       STA.W $0C0A,Y                      ;01AFFF|990A0C  |010C0A;
                       LDA.W $1A79,X                      ;01B002|BD791A  |001A79;
                       STA.W $0C0E,Y                      ;01B005|990E0C  |010C0E;

CODE_01B008:
                       RTS                                 ;01B008|60      |      ;

; ==============================================================================
; Battle Status Effect Manager
; Advanced status effect management with duration tracking
; ==============================================================================

CODE_01B009:
                       SEP #$20                           ;01B009|E220    |      ;
                       REP #$10                           ;01B00B|C210    |      ;
                       LDA.W $1916                        ;01B00D|AD1619  |001916;
                       AND.B #$E0                         ;01B010|29E0    |      ;
                       STA.W $1916                        ;01B012|8D1619  |001916;
                       LDA.W $19EE                        ;01B015|ADEE19  |0119EE;
                       AND.B #$1F                         ;01B018|291F    |      ;
                       STA.W $1916                        ;01B01A|8D1619  |001916;
                       RTS                                 ;01B01D|60      |      ;
