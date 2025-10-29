; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 6, Part 2)
; Advanced Graphics DMA Systems and Complex Memory Operations
; ==============================================================================

; ==============================================================================
; Advanced Graphics DMA Transfer System
; Complex DMA transfer with advanced graphics coordination
; ==============================================================================

CODE_01D35D:
                       LDX.W #$6A40                       ;01D35D|A2406A  |      ;
                       STX.W $192B                        ;01D360|8E2B19  |01192B;
                       STX.W $19E8                        ;01D363|8EE819  |0119E8;
                       LDA.B #$7F                         ;01D366|A97F    |      ;
                       STA.W $192D                        ;01D368|8D2D19  |01192D;
                       LDX.W #$0000                       ;01D36B|A20000  |      ;
                       STX.W $192E                        ;01D36E|8E2E19  |01192E;
                       LDX.W #$0100                       ;01D371|A20001  |      ;
                       STX.W $1930                        ;01D374|8E3019  |011930;

CODE_01D377:
                       JSR.W CODE_018DF3                   ;01D377|20F38D  |018DF3;
                       LDA.B #$07                         ;01D37A|A907    |      ;
                       STA.W $1A46                        ;01D37C|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D37F|20F38D  |018DF3;
                       JSR.W CODE_01D386                   ;01D382|2086D3  |01D386;
                       RTS                                 ;01D385|60      |      ;

; ==============================================================================
; Complex Graphics Processing and DMA Coordination
; Advanced graphics processing with DMA coordination systems
; ==============================================================================

CODE_01D386:
                       LDX.W $192B                        ;01D386|AE2B19  |01192B;
                       STX.W $1935                        ;01D389|8E3519  |011935;
                       LDA.W $192D                        ;01D38C|AD2D19  |01192D;
                       STA.W $1937                        ;01D38F|8D3719  |011937;
                       LDX.W #$2000                       ;01D392|A20020  |      ;
                       STX.W $1938                        ;01D395|8E3819  |011938;
                       LDX.W $1930                        ;01D398|AE3019  |011930;
                       STX.W $193A                        ;01D39B|8E3A19  |01193A;
                       LDA.B #$04                         ;01D39E|A904    |      ;
                       STA.W $1A46                        ;01D3A0|8D461A  |011A46;
                       JMP.W CODE_018DF3                   ;01D3A3|4CF38D  |018DF3;

; ==============================================================================
; Advanced Graphics Buffer Management
; Complex graphics buffer management with memory coordination
; ==============================================================================

CODE_01D3A6:
                       LDX.W #$7700                       ;01D3A6|A20077  |      ;
                       STX.W $192B                        ;01D3A9|8E2B19  |01192B;
                       STX.W $19EA                        ;01D3AC|8EEA19  |0119EA;

CODE_01D3AF:
                       LDA.B #$7F                         ;01D3AF|A97F    |      ;
                       STA.W $192D                        ;01D3B1|8D2D19  |01192D;
                       LDX.W #$0100                       ;01D3B4|A20001  |      ;
                       STX.W $192E                        ;01D3B7|8E2E19  |01192E;
                       LDX.W #$0080                       ;01D3BA|A28000  |      ;
                       STX.W $1930                        ;01D3BD|8E3019  |011930;
                       BRA CODE_01D377                     ;01D3C0|80B5    |01D377;

CODE_01D3C2:
                       LDX.W #$6A00                       ;01D3C2|A2006A  |      ;
                       STX.W $192B                        ;01D3C5|8E2B19  |01192B;
                       STX.W $19EA                        ;01D3C8|8EEA19  |0119EA;
                       BRA CODE_01D3AF                     ;01D3CB|80E2    |01D3AF;

; ==============================================================================
; Advanced Graphics Streaming System
; Complex graphics streaming with advanced coordination
; ==============================================================================

CODE_01D3CD:
                       LDX.W #$0F08                       ;01D3CD|A2080F  |      ;
                       STX.W $0501                        ;01D3D0|8E0105  |010501;
                       LDA.B #$1A                         ;01D3D3|A91A    |      ;
                       STA.W $0500                        ;01D3D5|8D0005  |010500;
                       LDA.B #$14                         ;01D3D8|A914    |      ;
                       JSR.W CODE_01D6BD                   ;01D3DA|20BDD6  |01D6BD;
                       LDX.W #$0000                       ;01D3DD|A20000  |      ;
                       STX.W $1933                        ;01D3E0|8E3319  |011933;
                       LDX.W #$0010                       ;01D3E3|A21000  |      ;
                       STX.W $1943                        ;01D3E6|8E4319  |011943;
                       LDA.B #$7F                         ;01D3E9|A97F    |      ;
                       STA.W $1937                        ;01D3EB|8D3719  |011937;

; ==============================================================================
; Advanced Graphics Multi-Layer Processing Loop
; Complex multi-layer graphics processing with coordination
; ==============================================================================

CODE_01D3EE:
                       LDX.W #$0000                       ;01D3EE|A20000  |      ;
                       STX.W $192B                        ;01D3F1|8E2B19  |01192B;
                       LDX.W #$2000                       ;01D3F4|A20020  |      ;
                       STX.W $192D                        ;01D3F7|8E2D19  |01192D;
                       LDX.W #$0008                       ;01D3FA|A20800  |      ;
                       JSR.W CODE_01D462                   ;01D3FD|2062D4  |01D462;
                       LDX.W $19E8                        ;01D400|AEE819  |0119E8;
                       STX.W $1935                        ;01D403|8E3519  |011935;
                       LDX.W $192D                        ;01D406|AE2D19  |01192D;
                       STX.W $1938                        ;01D409|8E3819  |011938;
                       LDX.W #$0100                       ;01D40C|A20001  |      ;
                       STX.W $193A                        ;01D40F|8E3A19  |01193A;
                       JSR.W CODE_018DF3                   ;01D412|20F38D  |018DF3;
                       LDA.B #$04                         ;01D415|A904    |      ;
                       STA.W $1A46                        ;01D417|8D461A  |011A46;
                       JSR.W CODE_0182D0                   ;01D41A|20D082  |0182D0;
                       LDX.W #$0100                       ;01D41D|A20001  |      ;
                       STX.W $192B                        ;01D420|8E2B19  |01192B;
                       LDX.W #$2100                       ;01D423|A20021  |      ;
                       STX.W $192D                        ;01D426|8E2D19  |01192D;
                       LDX.W #$0004                       ;01D429|A20400  |      ;
                       JSR.W CODE_01D462                   ;01D42C|2062D4  |01D462;
                       JSR.W CODE_018DF3                   ;01D42F|20F38D  |018DF3;
                       LDX.W $19EA                        ;01D432|AEEA19  |0119EA;
                       STX.W $1935                        ;01D435|8E3519  |011935;
                       LDX.W $192D                        ;01D438|AE2D19  |01192D;
                       STX.W $1938                        ;01D43B|8E3819  |011938;
                       LDX.W #$0080                       ;01D43E|A28000  |      ;
                       STX.W $193A                        ;01D441|8E3A19  |01193A;
                       LDA.B #$04                         ;01D444|A904    |      ;
                       STA.W $1A46                        ;01D446|8D461A  |011A46;
                       JSR.W CODE_0182D0                   ;01D449|20D082  |0182D0;
                       LDA.W $1933                        ;01D44C|AD3319  |011933;
                       CLC                                 ;01D44F|18      |      ;
                       ADC.B #$12                         ;01D450|6912    |      ;
                       AND.B #$1E                         ;01D452|291E    |      ;
                       STA.W $1933                        ;01D454|8D3319  |011933;
                       LDA.B #$10                         ;01D457|A910    |      ;
                       JSR.W CODE_01D6A9                   ;01D459|20A9D6  |01D6A9;
                       DEC.W $1943                        ;01D45C|CE4319  |011943;
                       BNE CODE_01D3EE                     ;01D45F|D08D    |01D3EE;
                       RTS                                 ;01D461|60      |      ;

; ==============================================================================
; Advanced Graphics Copy Engine
; Complex graphics copy engine with advanced memory management
; ==============================================================================

CODE_01D462:
                       PHP                                 ;01D462|08      |      ;
                       PHB                                 ;01D463|8B      |      ;
                       REP #$30                           ;01D464|C230    |      ;
                       PHX                                 ;01D466|DA      |      ;
                       PEA.W $7F00                        ;01D467|F4007F  |017F00;
                       PLB                                 ;01D46A|AB      |      ;
                       PLB                                 ;01D46B|AB      |      ;
                       LDA.L $00192B                      ;01D46C|AF2B1900|00192B;
                       CLC                                 ;01D470|18      |      ;
                       ADC.L $001933                      ;01D471|6F331900|001933;
                       TAX                                 ;01D475|AA      |      ;
                       LDA.L $00192D                      ;01D476|AF2D1900|00192D;
                       CLC                                 ;01D47A|18      |      ;
                       ADC.L $001933                      ;01D47B|6F331900|001933;
                       TAY                                 ;01D47F|A8      |      ;
                       PLA                                 ;01D480|68      |      ;

CODE_01D481:
                       PHA                                 ;01D481|48      |      ;
                       LDA.W $0000,X                      ;01D482|BD0000  |7F0000;
                       STA.W $0000,Y                      ;01D485|990000  |7F0000;
                       TXA                                 ;01D488|8A      |      ;
                       CLC                                 ;01D489|18      |      ;
                       ADC.W #$0020                       ;01D48A|692000  |      ;
                       TAX                                 ;01D48D|AA      |      ;
                       TYA                                 ;01D48E|98      |      ;
                       CLC                                 ;01D48F|18      |      ;
                       ADC.W #$0020                       ;01D490|692000  |      ;
                       TAY                                 ;01D493|A8      |      ;
                       PLA                                 ;01D494|68      |      ;
                       DEC A                               ;01D495|3A      |      ;
                       BNE CODE_01D481                     ;01D496|D0E9    |01D481;
                       PLB                                 ;01D498|AB      |      ;
                       PLP                                 ;01D499|28      |      ;
                       RTS                                 ;01D49A|60      |      ;

; ==============================================================================
; Advanced Character Animation Processing
; Complex character animation with advanced timing control
; ==============================================================================

CODE_01D49B:
                       PHP                                 ;01D49B|08      |      ;
                       JSR.W CODE_01B1EB                   ;01D49C|20EBB1  |01B1EB;
                       STX.W $192B                        ;01D49F|8E2B19  |01192B;
                       STA.W $192D                        ;01D4A2|8D2D19  |01192D;
                       REP #$30                           ;01D4A5|C230    |      ;
                       LDY.W #$000C                       ;01D4A7|A00C00  |      ;

CODE_01D4AA:
                       PHY                                 ;01D4AA|5A      |      ;
                       LDA.W $1A87,X                      ;01D4AB|BD871A  |011A87;
                       DEC A                               ;01D4AE|3A      |      ;
                       AND.W #$03FF                       ;01D4AF|29FF03  |      ;
                       STA.W $1A87,X                      ;01D4B2|9D871A  |011A87;
                       LDA.W #$0008                       ;01D4B5|A90800  |      ;
                       JSR.W CODE_01D6BD                   ;01D4B8|20BDD6  |01D6BD;
                       PLY                                 ;01D4BB|7A      |      ;
                       DEY                                 ;01D4BC|88      |      ;
                       BNE CODE_01D4AA                     ;01D4BD|D0EB    |01D4AA;
                       LDX.W $192B                        ;01D4BF|AE2B19  |01192B;
                       PHX                                 ;01D4C2|DA      |      ;
                       LDA.W #$0012                       ;01D4C3|A91200  |      ;
                       STA.W $192B                        ;01D4C6|8D2B19  |01192B;
                       JSR.W CODE_01D603                   ;01D4C9|2003D6  |01D603;
                       LDA.W #$0014                       ;01D4CC|A91400  |      ;
                       JSR.W CODE_01D6BD                   ;01D4CF|20BDD6  |01D6BD;
                       LDY.W #$0008                       ;01D4D2|A00800  |      ;

CODE_01D4D5:
                       LDA.W #$0004                       ;01D4D5|A90400  |      ;
                       STA.W $192B                        ;01D4D8|8D2B19  |01192B;
                       JSR.W CODE_01D603                   ;01D4DB|2003D6  |01D603;
                       LDA.W #$0004                       ;01D4DE|A90400  |      ;
                       JSR.W CODE_01D6BD                   ;01D4E1|20BDD6  |01D6BD;
                       DEY                                 ;01D4E4|88      |      ;
                       BNE CODE_01D4D5                     ;01D4E5|D0EE    |01D4D5;
                       PLX                                 ;01D4E7|FA      |      ;
                       STX.W $192B                        ;01D4E8|8E2B19  |01192B;
                       PHP                                 ;01D4EB|08      |      ;
                       SEP #$20                           ;01D4EC|E220    |      ;
                       REP #$10                           ;01D4EE|C210    |      ;
                       LDA.B #$03                         ;01D4F0|A903    |      ;
                       STA.W $1A72,X                      ;01D4F2|9D721A  |011A72;
                       PLP                                 ;01D4F5|28      |      ;
                       REP #$30                           ;01D4F6|C230    |      ;
                       LDY.W #$000C                       ;01D4F8|A00C00  |      ;

CODE_01D4FB:
                       PHY                                 ;01D4FB|5A      |      ;
                       LDA.W $1A87,X                      ;01D4FC|BD871A  |011A87;
                       INC A                               ;01D4FF|1A      |      ;
                       AND.W #$03FF                       ;01D500|29FF03  |      ;
                       STA.W $1A87,X                      ;01D503|9D871A  |011A87;
                       LDA.W #$0008                       ;01D506|A90800  |      ;
                       JSR.W CODE_01D6C4                   ;01D509|20C4D6  |01D6C4;
                       PLY                                 ;01D50C|7A      |      ;
                       DEY                                 ;01D50D|88      |      ;
                       BNE CODE_01D4FB                     ;01D50E|D0EB    |01D4FB;
                       SEP #$20                           ;01D510|E220    |      ;
                       REP #$10                           ;01D512|C210    |      ;
                       LDA.B #$10                         ;01D514|A910    |      ;
                       STA.W $1935                        ;01D516|8D3519  |011935;

; ==============================================================================
; Advanced Palette Animation Control System
; Complex palette animation control with timing coordination
; ==============================================================================

CODE_01D519:
                       PHP                                 ;01D519|08      |      ;
                       REP #$30                           ;01D51A|C230    |      ;
                       LDY.W #$0040                       ;01D51C|A04000  |      ;
                       LDX.W #$0000                       ;01D51F|A20000  |      ;

CODE_01D522:
                       LDA.L $7FC588,X                    ;01D522|BF88C57F|7FC588;
                       STA.W $192B                        ;01D526|8D2B19  |01192B;
                       JSR.W CODE_01D159                   ;01D529|2059D1  |01D159;
                       LDA.W $192F                        ;01D52C|AD2F19  |01192F;
                       STA.L $7FC588,X                    ;01D52F|9F88C57F|7FC588;
                       INX                                 ;01D533|E8      |      ;
                       INX                                 ;01D534|E8      |      ;
                       DEY                                 ;01D535|88      |      ;
                       BNE CODE_01D522                     ;01D536|D0EA    |01D522;
                       PLP                                 ;01D538|28      |      ;
                       LDA.B #$05                         ;01D539|A905    |      ;
                       STA.W $1A46                        ;01D53B|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D53E|20F38D  |018DF3;
                       LDA.B #$10                         ;01D541|A910    |      ;
                       JSR.W CODE_01D6C4                   ;01D543|20C4D6  |01D6C4;
                       DEC.W $1935                        ;01D546|CE3519  |011935;
                       BNE CODE_01D519                     ;01D549|D0CE    |01D519;
                       LDA.B #$70                         ;01D54B|A970    |      ;
                       STA.W $050B                        ;01D54D|8D0B05  |01050B;
                       LDA.B #$81                         ;01D550|A981    |      ;
                       STA.W $050A                        ;01D552|8D0A05  |01050A;
                       LDA.B #$0A                         ;01D555|A90A    |      ;
                       STA.W $192B                        ;01D557|8D2B19  |01192B;
                       JSR.W CODE_01D603                   ;01D55A|2003D6  |01D603;
                       JSR.W CODE_018DF3                   ;01D55D|20F38D  |018DF3;
                       LDA.B #$0E                         ;01D560|A90E    |      ;
                       STA.W $1935                        ;01D562|8D3519  |011935;

; ==============================================================================
; Advanced Color Blending Processing System
; Complex color blending processing with interpolation control
; ==============================================================================

CODE_01D565:
                       PHP                                 ;01D565|08      |      ;
                       REP #$30                           ;01D566|C230    |      ;
                       LDY.W #$0040                       ;01D568|A04000  |      ;
                       LDX.W #$0000                       ;01D56B|A20000  |      ;

CODE_01D56E:
                       LDA.L $7FC588,X                    ;01D56E|BF88C57F|7FC588;
                       STA.W $192B                        ;01D572|8D2B19  |01192B;
                       LDA.L $7FC608,X                    ;01D575|BF08C67F|7FC608;
                       STA.W $192D                        ;01D579|8D2D19  |01192D;
                       JSR.W CODE_01D23C                   ;01D57C|203CD2  |01D23C;
                       LDA.W $192F                        ;01D57F|AD2F19  |01192F;
                       STA.L $7FC588,X                    ;01D582|9F88C57F|7FC588;
                       INX                                 ;01D586|E8      |      ;
                       INX                                 ;01D587|E8      |      ;
                       DEY                                 ;01D588|88      |      ;
                       BNE CODE_01D56E                     ;01D589|D0E3    |01D56E;
                       PLP                                 ;01D58B|28      |      ;
                       JSR.W CODE_018DF3                   ;01D58C|20F38D  |018DF3;
                       LDA.B #$05                         ;01D58F|A905    |      ;
                       STA.W $1A46                        ;01D591|8D461A  |011A46;
                       LDA.B #$10                         ;01D594|A910    |      ;
                       JSR.W CODE_01D6C4                   ;01D596|20C4D6  |01D6C4;
                       DEC.W $1935                        ;01D599|CE3519  |011935;
                       BNE CODE_01D565                     ;01D59C|D0C7    |01D565;
                       LDA.B #$28                         ;01D59E|A928    |      ;
                       JSR.W CODE_01D6C4                   ;01D5A0|20C4D6  |01D6C4;
                       LDX.W #$0F08                       ;01D5A3|A2080F  |      ;
                       STX.W $0501                        ;01D5A6|8E0105  |010501;
                       LDA.W $1916                        ;01D5A9|AD1619  |011916;
                       AND.B #$1F                         ;01D5AC|291F    |      ;
                       STA.W $0500                        ;01D5AE|8D0005  |010500;
                       PLP                                 ;01D5B1|28      |      ;
                       RTS                                 ;01D5B2|60      |      ;

; ==============================================================================
; Advanced VRAM Management System
; Complex VRAM management with DMA coordination
; ==============================================================================

                       LDA.B #$80                         ;01D5B3|A980    |      ;
                       STA.W $2115                        ;01D5B5|8D1521  |012115;
                       LDX.W $192B                        ;01D5B8|AE2B19  |01192B;
                       STX.W $2116                        ;01D5BB|8E1621  |012116;
                       LDA.W $213A                        ;01D5BE|AD3A21  |01213A;
                       LDA.B #$81                         ;01D5C1|A981    |      ;
                       STA.W $4300                        ;01D5C3|8D0043  |014300;
                       LDA.B #$39                         ;01D5C6|A939    |      ;
                       STA.W $4301                        ;01D5C8|8D0143  |014301;
                       LDA.W $192D                        ;01D5CB|AD2D19  |01192D;
                       STA.W $4304                        ;01D5CE|8D0443  |014304;
                       LDX.W $192E                        ;01D5D1|AE2E19  |01192E;
                       STX.W $4302                        ;01D5D4|8E0243  |014302;
                       LDX.W $1930                        ;01D5D7|AE3019  |011930;
                       STX.W $4305                        ;01D5DA|8E0543  |014305;
                       LDA.B #$01                         ;01D5DD|A901    |      ;
                       STA.W $420B                        ;01D5DF|8D0B42  |01420B;
                       RTS                                 ;01D5E2|60      |      ;

; ==============================================================================
; Advanced Graphics Buffer Streaming System
; Complex graphics buffer streaming with memory coordination
; ==============================================================================

                       db $DA,$5A,$08,$8B,$E2,$20,$C2,$10,$AD,$51,$1A,$8D,$2C,$19,$9C,$51 ; 01D5E3
                       db $1A,$AD,$2B,$19,$D0,$03,$4C,$81,$D6,$C2,$30,$AD,$2D,$19,$80,$1B ; 01D5F3

; ==============================================================================
; Advanced Graphics Data Processing Engine
; Complex graphics data processing with advanced memory management
; ==============================================================================

CODE_01D603:
                       PHX                                 ;01D603|DA      |      ;
                       PHY                                 ;01D604|5A      |      ;
                       PHP                                 ;01D605|08      |      ;
                       PHB                                 ;01D606|8B      |      ;
                       SEP #$20                           ;01D607|E220    |      ;
                       REP #$10                           ;01D609|C210    |      ;
                       LDA.W $1A51                        ;01D60B|AD511A  |011A51;
                       STA.W $192C                        ;01D60E|8D2C19  |01192C;
                       STZ.W $1A51                        ;01D611|9C511A  |011A51;
                       LDA.W $192B                        ;01D614|AD2B19  |01192B;
                       BEQ CODE_01D681                     ;01D617|F068    |01D681;
                       REP #$30                           ;01D619|C230    |      ;
                       LDA.W #$6F7B                       ;01D61B|A97B6F  |      ;
                       LDX.W #$5000                       ;01D61E|A20050  |      ;
                       LDY.W #$0100                       ;01D621|A00001  |      ;

CODE_01D624:
                       STA.L $7F0000,X                    ;01D624|9F00007F|7F0000;
                       INX                                 ;01D628|E8      |      ;
                       INX                                 ;01D629|E8      |      ;
                       DEY                                 ;01D62A|88      |      ;
                       BNE CODE_01D624                     ;01D62B|D0F7    |01D624;
                       LDX.W #$C588                       ;01D62D|A288C5  |      ;
                       LDY.W #$4000                       ;01D630|A00040  |      ;
                       LDA.W #$007F                       ;01D633|A97F00  |      ;
                       MVN $7F,$7F                       ;01D636|547F7F  |      ;
                       LDX.W #$C488                       ;01D639|A288C4  |      ;
                       LDY.W #$6000                       ;01D63C|A00060  |      ;
                       LDA.W #$00FF                       ;01D63F|A9FF00  |      ;
                       MVN $7F,$7F                       ;01D642|547F7F  |      ;
                       LDX.W #$5000                       ;01D645|A20050  |      ;
                       LDY.W #$C588                       ;01D648|A088C5  |      ;
                       LDA.W #$007F                       ;01D64B|A97F00  |      ;
                       MVN $7F,$7F                       ;01D64E|547F7F  |      ;
                       LDX.W #$5000                       ;01D651|A20050  |      ;
                       LDY.W #$C488                       ;01D654|A088C4  |      ;
                       LDA.W #$00FF                       ;01D657|A9FF00  |      ;
                       MVN $7F,$7F                       ;01D65A|547F7F  |      ;
                       PLB                                 ;01D65D|AB      |      ;
                       SEP #$20                           ;01D65E|E220    |      ;
                       REP #$10                           ;01D660|C210    |      ;
                       JSR.W CODE_018DF3                   ;01D662|20F38D  |018DF3;
                       LDA.B #$06                         ;01D665|A906    |      ;
                       STA.W $1A46                        ;01D667|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D66A|20F38D  |018DF3;
                       LDA.W $192B                        ;01D66D|AD2B19  |01192B;
                       BMI CODE_01D6A5                     ;01D670|3033    |01D6A5;

CODE_01D672:
                       JSR.W CODE_0182D9                   ;01D672|20D982  |0182D9;
                       DEC.W $192B                        ;01D675|CE2B19  |01192B;
                       BNE CODE_01D672                     ;01D678|D0F8    |01D672;
                       PHB                                 ;01D67A|8B      |      ;
                       LDA.W $192C                        ;01D67B|AD2C19  |01192C;
                       STA.W $1A51                        ;01D67E|8D511A  |011A51;

CODE_01D681:
                       REP #$30                           ;01D681|C230    |      ;
                       LDX.W #$4000                       ;01D683|A20040  |      ;
                       LDY.W #$C588                       ;01D686|A088C5  |      ;
                       LDA.W #$007F                       ;01D689|A97F00  |      ;
                       MVN $7F,$7F                       ;01D68C|547F7F  |      ;
                       LDX.W #$6000                       ;01D68F|A20060  |      ;
                       LDY.W #$C488                       ;01D692|A088C4  |      ;
                       LDA.W #$00FF                       ;01D695|A9FF00  |      ;
                       MVN $7F,$7F                       ;01D698|547F7F  |      ;
                       PLB                                 ;01D69B|AB      |      ;
                       SEP #$20                           ;01D69C|E220    |      ;
                       REP #$10                           ;01D69E|C210    |      ;
                       LDA.B #$06                         ;01D6A0|A906    |      ;
                       STA.W $1A46                        ;01D6A2|8D461A  |011A46;

CODE_01D6A5:
                       PLP                                 ;01D6A5|28      |      ;
                       PLY                                 ;01D6A6|7A      |      ;
                       PLX                                 ;01D6A7|FA      |      ;
                       RTS                                 ;01D6A8|60      |      ;

; ==============================================================================
; Advanced Timing Control Functions
; Complex timing control with advanced synchronization
; ==============================================================================

CODE_01D6A9:
                       PHX                                 ;01D6A9|DA      |      ;
                       PHP                                 ;01D6AA|08      |      ;
                       LDX.W #$0000                       ;01D6AB|A20000  |      ;

CODE_01D6AE:
                       SEP #$20                           ;01D6AE|E220    |      ;
                       REP #$10                           ;01D6B0|C210    |      ;

CODE_01D6B2:
                       PHA                                 ;01D6B2|48      |      ;
                       JSR.W (DATA8_01D6CB,X)              ;01D6B3|FCCBD6  |01D6CB;
                       PLA                                 ;01D6B6|68      |      ;
                       DEC A                               ;01D6B7|3A      |      ;
                       BNE CODE_01D6B2                     ;01D6B8|D0F8    |01D6B2;
                       PLP                                 ;01D6BA|28      |      ;
                       PLX                                 ;01D6BB|FA      |      ;
                       RTS                                 ;01D6BC|60      |      ;

CODE_01D6BD:
                       PHX                                 ;01D6BD|DA      |      ;
                       PHP                                 ;01D6BE|08      |      ;
                       LDX.W #$0002                       ;01D6BF|A20200  |      ;
                       BRA CODE_01D6AE                     ;01D6C2|80EA    |01D6AE;

CODE_01D6C4:
                       PHX                                 ;01D6C4|DA      |      ;
                       PHP                                 ;01D6C5|08      |      ;
                       LDX.W #$0004                       ;01D6C6|A20400  |      ;
                       BRA CODE_01D6AE                     ;01D6C9|80E3    |01D6AE;

DATA8_01D6CB:
                       db $D1,$D6,$D0,$82,$D9,$82   ;01D6CB|        |      ;
                       JSL.L CODE_0096A0                   ;01D6D1|22A09600|0096A0;
                       RTS                                 ;01D6D5|60      |      ;

; ==============================================================================
; Advanced Character Processing Functions
; Complex character processing with battle coordination
; ==============================================================================

                       SEP #$20                           ;01D6D6|E220    |      ;
                       REP #$10                           ;01D6D8|C210    |      ;
                       LDA.B #$03                         ;01D6DA|A903    |      ;
                       STA.W $19E2                        ;01D6DC|8DE219  |0119E2;
                       BRA CODE_01D6E8                     ;01D6DF|8007    |01D6E8;

                       SEP #$20                           ;01D6E1|E220    |      ;
                       REP #$10                           ;01D6E3|C210    |      ;
                       STZ.W $19E2                        ;01D6E5|9CE219  |0119E2;

CODE_01D6E8:
                       LDA.W $19E2                        ;01D6E8|ADE219  |0119E2;
                       JSR.W CODE_01B1EB                   ;01D6EB|20EBB1  |01B1EB;
                       STX.W $19EA                        ;01D6EE|8EEA19  |0119EA;
                       STA.W $19E7                        ;01D6F1|8DE719  |0119E7;
                       LDA.W $1A7D,X                      ;01D6F4|BD7D1A  |011A7D;
                       STA.W $192D                        ;01D6F7|8D2D19  |01192D;
                       LDA.W $1A7E,X                      ;01D6FA|BD7E1A  |011A7E;
                       DEC A                               ;01D6FD|3A      |      ;
                       STA.W $192E                        ;01D6FE|8D2E19  |01192E;
                       JSR.W CODE_01880C                   ;01D701|200C88  |01880C;
                       LDA.L $7F8000,X                    ;01D704|BF00807F|7F8000;
                       INC A                               ;01D708|1A      |      ;
                       STA.L $7F8000,X                    ;01D709|9F00807F|7F8000;
                       STA.W $19D6                        ;01D70D|8DD619  |0119D6;
                       LDA.B #$01                         ;01D710|A901    |      ;
                       STA.W $194B                        ;01D712|8D4B19  |01194B;
                       STZ.W $1951                        ;01D715|9C5119  |011951;
                       LDA.W $19C9                        ;01D718|ADC919  |0119C9;
                       STA.W $19CA                        ;01D71B|8DCA19  |0119CA;
                       LDA.B #$00                         ;01D71E|A900    |      ;
                       XBA                                 ;01D720|EB      |      ;
                       LDA.W $19D6                        ;01D721|ADD619  |0119D6;
                       TAX                                 ;01D724|AA      |      ;
                       LDA.L $7FD0F4,X                    ;01D725|BFF4D07F|7FD0F4;
                       STA.W $19C9                        ;01D729|8DC919  |0119C9;
                       PHP                                 ;01D72C|08      |      ;
                       REP #$30                           ;01D72D|C230    |      ;
                       TXA                                 ;01D72F|8A      |      ;
                       ASL A                               ;01D730|0A      |      ;
                       ASL A                               ;01D731|0A      |      ;
                       TAX                                 ;01D732|AA      |      ;
                       LDA.L $7FCEF4,X                    ;01D733|BFF4CE7F|7FCEF4;
                       STA.W $19C5                        ;01D737|8DC519  |0119C5;
                       LDA.L $7FCEF6,X                    ;01D73A|BFF6CE7F|7FCEF6;
                       STA.W $19C7                        ;01D73E|8DC719  |0119C7;
                       PLP                                 ;01D741|28      |      ;
                       JSR.W CODE_0196D3                   ;01D742|20D396  |0196D3;
                       JSR.W CODE_019058                   ;01D745|205890  |019058;
                       LDA.W $19E2                        ;01D748|ADE219  |0119E2;
                       BNE CODE_01D76D                     ;01D74B|D020    |01D76D;
                       LDX.W #$0000                       ;01D74D|A20000  |      ;
                       LDA.W $19BD                        ;01D750|ADBD19  |0119BD;
                       INC A                               ;01D753|1A      |      ;
                       CLC                                 ;01D754|18      |      ;
                       ADC.L DATA8_0196CB,X                ;01D755|7FCB9601|0196CB;
                       AND.B #$1F                         ;01D759|291F    |      ;
                       STA.W $19BD                        ;01D75B|8DBD19  |0119BD;
                       LDA.W $19BF                        ;01D75E|ADBF19  |0119BF;
                       CLC                                 ;01D761|18      |      ;
                       ADC.L DATA8_0196CC,X                ;01D762|7FCC9601|0196CC;
                       AND.B #$0F                         ;01D766|290F    |      ;
                       STA.W $19BF                        ;01D768|8DBF19  |0119BF;
                       BRA CODE_01D78B                     ;01D76B|801E    |01D78B;

CODE_01D76D:
                       LDX.W #$0000                       ;01D76D|A20000  |      ;
                       LDA.W $19BD                        ;01D770|ADBD19  |0119BD;
                       CLC                                 ;01D773|18      |      ;
                       ADC.L DATA8_0196CB,X                ;01D774|7FCB9601|0196CB;
                       AND.B #$1F                         ;01D778|291F    |      ;
                       STA.W $19BD                        ;01D77A|8DBD19  |0119BD;
                       LDA.W $19BF                        ;01D77D|ADBF19  |0119BF;
                       DEC A                               ;01D780|3A      |      ;
                       CLC                                 ;01D781|18      |      ;
                       ADC.L DATA8_0196CC,X                ;01D782|7FCC9601|0196CC;
                       AND.B #$0F                         ;01D786|290F    |      ;
                       STA.W $19BF                        ;01D788|8DBF19  |0119BF;

CODE_01D78B:
                       JSR.W CODE_0188CD                   ;01D78B|20CD88  |0188CD;
                       LDX.W $192B                        ;01D78E|AE2B19  |01192B;
                       STX.W $195F                        ;01D791|8E5F19  |01195F;
                       REP #$30                           ;01D794|C230    |      ;
                       LDA.L DATA8_00F5EA                  ;01D796|AFEAF500|00F5EA;
                       STA.W $194D                        ;01D79A|8D4D19  |01194D;
                       SEP #$20                           ;01D79D|E220    |      ;
                       REP #$10                           ;01D79F|C210    |      ;
                       LDX.W #$A11F                       ;01D7A1|A21FA1  |      ;
                       STX.W $0506                        ;01D7A4|8E0605  |010506;
                       LDA.B #$0A                         ;01D7A7|A90A    |      ;
                       STA.W $0505                        ;01D7A9|8D0505  |010505;
                       LDA.B #$14                         ;01D7AC|A914    |      ;
                       STA.W $1926                        ;01D7AE|8D2619  |011926;

; ==============================================================================
; Advanced Animation State Control
; Complex animation state control with advanced timing
; ==============================================================================

CODE_01D7B1:
                       LDA.W $1926                        ;01D7B1|AD2619  |011926;
                       CMP.B #$0F                         ;01D7B4|C90F    |      ;
                       BCS CODE_01D7C0                     ;01D7B6|B008    |01D7C0;
                       CMP.B #$05                         ;01D7B8|C905    |      ;
                       BCS CODE_01D7C4                     ;01D7BA|B008    |01D7C4;
                       LDA.B #$39                         ;01D7BC|A939    |      ;
                       BRA CODE_01D7C6                     ;01D7BE|8006    |01D7C6;

CODE_01D7C0:
                       LDA.B #$37                         ;01D7C0|A937    |      ;
                       BRA CODE_01D7C6                     ;01D7C2|8002    |01D7C6;

CODE_01D7C4:
                       LDA.B #$36                         ;01D7C4|A936    |      ;

CODE_01D7C6:
                       LDX.W $19EA                        ;01D7C6|AEEA19  |0119EA;
                       JSR.W CODE_01CACF                   ;01D7C9|20CFCA  |01CACF;
                       BRA CODE_01D7CE                     ;01D7CC|8000    |01D7CE;

CODE_01D7CE:
                       LDX.W $194D                        ;01D7CE|AE4D19  |01194D;

CODE_01D7D1:
                       LDA.L DATA8_00F5F2,X                ;01D7D1|BFF2F500|00F5F2;
                       INX                                 ;01D7D5|E8      |      ;
                       CMP.B #$FF                         ;01D7D6|C9FF    |      ;
                       BEQ CODE_01D809                     ;01D7D8|F02F    |01D809;
                       CMP.B #$80                         ;01D7DA|C980    |      ;
                       BEQ CODE_01D7FC                     ;01D7DC|F01E    |01D7FC;
                       STA.W $1949                        ;01D7DE|8D4919  |011949;
                       LDA.B #$0C                         ;01D7E1|A90C    |      ;
                       STA.W $194A                        ;01D7E3|8D4A19  |01194A;
                       PHX                                 ;01D7E6|DA      |      ;
                       LDX.W $19EA                        ;01D7E7|AEEA19  |0119EA;
                       LDA.W $1A85,X                      ;01D7EA|BD851A  |011A85;
                       STA.W $192D                        ;01D7ED|8D2D19  |01192D;
                       LDA.W $1A87,X                      ;01D7F0|BD871A  |011A87;
                       STA.W $192E                        ;01D7F3|8D2E19  |01192E;
                       PLX                                 ;01D7F6|FA      |      ;
                       JSR.W CODE_019681                   ;01D7F7|208196  |019681;
                       BRA CODE_01D7D1                     ;01D7FA|80D5    |01D7D1;

CODE_01D7FC:
                       LDA.L DATA8_00F5F2,X                ;01D7FC|BFF2F500|00F5F2;
                       INX                                 ;01D800|E8      |      ;
                       STA.W $1949                        ;01D801|8D4919  |011949;
                       JSR.W CODE_019EDD                   ;01D804|20DD9E  |019EDD;
                       BRA CODE_01D7D1                     ;01D807|80C8    |01D7D1;

CODE_01D809:
                       STX.W $194D                        ;01D809|8E4D19  |01194D;
                       JSR.W CODE_0182D0                   ;01D80C|20D082  |0182D0;
                       LDA.W $1926                        ;01D80F|AD2619  |011926;
                       CMP.B #$0B                         ;01D812|C90B    |      ;
                       BNE CODE_01D81B                     ;01D814|D005    |01D81B;
                       LDA.B #$22                         ;01D816|A922    |      ;
                       JSR.W CODE_01BAAD                   ;01D818|20ADBA  |01BAAD;

CODE_01D81B:
                       DEC.W $1926                        ;01D81B|CE2619  |011926;
                       BPL CODE_01D7B1                     ;01D81E|1091    |01D7B1;
                       LDA.W $19E7                        ;01D820|ADE719  |0119E7;
