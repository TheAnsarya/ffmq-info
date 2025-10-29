; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 6, Part 1)
; Advanced Graphics Processing and Complex Animation Control
; ==============================================================================

; ==============================================================================
; Advanced Graphics Tile Coordinate Processing
; Complex tile coordinate processing with multi-layer graphics coordination
; ==============================================================================

CODE_01D044:
                       STA.W $0C58                        ;01D044|8D580C  |010C58;
                       CLC                                 ;01D047|18      |      ;
                       ADC.B #$08                         ;01D048|6908    |      ;
                       STA.W $0C54                        ;01D04A|8D540C  |010C54;
                       STA.W $0C5C                        ;01D04D|8D5C0C  |010C5C;
                       RTS                                 ;01D050|60      |      ;

CODE_01D051:
                       STA.W $0C51                        ;01D051|8D510C  |010C51;
                       STA.W $0C55                        ;01D054|8D550C  |010C55;
                       CLC                                 ;01D057|18      |      ;
                       ADC.B #$08                         ;01D058|6908    |      ;
                       STA.W $0C59                        ;01D05A|8D590C  |010C59;
                       STA.W $0C5D                        ;01D05D|8D5D0C  |010C5D;
                       RTS                                 ;01D060|60      |      ;

; ==============================================================================
; Advanced Graphics Tile Management System
; Complex graphics tile management with advanced coordination
; ==============================================================================

CODE_01D061:
                       PHP                                 ;01D061|08      |      ;
                       REP #$30                           ;01D062|C230    |      ;
                       LDA.W #$0140                       ;01D064|A94001  |      ;
                       BRA CODE_01D06F                     ;01D067|8006    |01D06F;

CODE_01D069:
                       PHP                                 ;01D069|08      |      ;
                       REP #$30                           ;01D06A|C230    |      ;
                       LDA.W #$0144                       ;01D06C|A94401  |      ;

CODE_01D06F:
                       STA.W $0C52                        ;01D06F|8D520C  |010C52;
                       INC A                               ;01D072|1A      |      ;
                       STA.W $0C56                        ;01D073|8D560C  |010C56;
                       INC A                               ;01D076|1A      |      ;
                       STA.W $0C5A                        ;01D077|8D5A0C  |010C5A;
                       INC A                               ;01D07A|1A      |      ;
                       STA.W $0C5E                        ;01D07B|8D5E0C  |010C5E;
                       SEP #$20                           ;01D07E|E220    |      ;
                       REP #$10                           ;01D080|C210    |      ;
                       LDA.B #$0C                         ;01D082|A90C    |      ;
                       ORA.W $1A54                        ;01D084|0D541A  |011A54;
                       TAY                                 ;01D087|A8      |      ;
                       ORA.W $0C53                        ;01D088|0D530C  |010C53;
                       STA.W $0C53                        ;01D08B|8D530C  |010C53;
                       TYA                                 ;01D08E|98      |      ;
                       ORA.W $0C57                        ;01D08F|0D570C  |010C57;
                       STA.W $0C57                        ;01D092|8D570C  |010C57;
                       TYA                                 ;01D095|98      |      ;
                       ORA.W $0C5B                        ;01D096|0D5B0C  |010C5B;
                       STA.W $0C5B                        ;01D099|8D5B0C  |010C5B;
                       TYA                                 ;01D09C|98      |      ;
                       ORA.W $0C5F                        ;01D09D|0D5F0C  |010C5F;
                       STA.W $0C5F                        ;01D0A0|8D5F0C  |010C5F;
                       PLP                                 ;01D0A3|28      |      ;
                       RTS                                 ;01D0A4|60      |      ;

; ==============================================================================
; Complex Graphics Processing Coordination
; Advanced graphics processing with battle coordination
; ==============================================================================

CODE_01D0A5:
                       LDA.B #$08                         ;01D0A5|A908    |      ;
                       JSR.W CODE_01BAAD                   ;01D0A7|20ADBA  |01BAAD;
                       JSR.W CODE_01D069                   ;01D0AA|2069D0  |01D069;
                       LDA.B #$06                         ;01D0AD|A906    |      ;
                       JSR.W CODE_01D6A9                   ;01D0AF|20A9D6  |01D6A9;
                       JSR.W CODE_01D061                   ;01D0B2|2061D0  |01D061;
                       LDA.B #$06                         ;01D0B5|A906    |      ;
                       JSR.W CODE_01D6A9                   ;01D0B7|20A9D6  |01D6A9;
                       RTS                                 ;01D0BA|60      |      ;

; ==============================================================================
; Advanced Animation Loop Control System
; Complex animation loop control with advanced graphics coordination
; ==============================================================================

CODE_01D0BB:
                       PHP                                 ;01D0BB|08      |      ;
                       LDY.W #$0010                       ;01D0BC|A01000  |      ;
                       STZ.W $192B                        ;01D0BF|9C2B19  |01192B;
                       LDX.W #$6B00                       ;01D0C2|A2006B  |      ;
                       STX.W $192D                        ;01D0C5|8E2D19  |01192D;
                       STY.W $192F                        ;01D0C8|8C2F19  |01192F;
                       STZ.W $1931                        ;01D0CB|9C3119  |011931;
                       LDX.W $1900                        ;01D0CE|AE0019  |011900;
                       STX.W $1933                        ;01D0D1|8E3319  |011933;
                       SEP #$20                           ;01D0D4|E220    |      ;
                       REP #$10                           ;01D0D6|C210    |      ;
                       LDA.W $0E91                        ;01D0D8|AD910E  |010E91;
                       CMP.B #$6B                         ;01D0DB|C96B    |      ;
                       BNE CODE_01D0E5                     ;01D0DD|D006    |01D0E5;
                       db $A2,$04,$00,$8E,$31,$19   ;01D0DF|        |      ;

CODE_01D0E5:
                       JSR.W CODE_018DF3                   ;01D0E5|20F38D  |018DF3;

CODE_01D0E8:
                       PHP                                 ;01D0E8|08      |      ;
                       REP #$30                           ;01D0E9|C230    |      ;
                       LDA.W $1900                        ;01D0EB|AD0019  |011900;
                       CLC                                 ;01D0EE|18      |      ;
                       ADC.W $1931                        ;01D0EF|6D3119  |011931;
                       STA.W $1900                        ;01D0F2|8D0019  |011900;
                       LDA.W $1931                        ;01D0F5|AD3119  |011931;
                       EOR.W #$FFFF                       ;01D0F8|49FFFF  |      ;
                       INC A                               ;01D0FB|1A      |      ;
                       STA.W $1931                        ;01D0FC|8D3119  |011931;
                       PLP                                 ;01D0FF|28      |      ;
                       LDA.B #$03                         ;01D100|A903    |      ;
                       STA.W $1A46                        ;01D102|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D105|20F38D  |018DF3;
                       LDA.W $192B                        ;01D108|AD2B19  |01192B;
                       CLC                                 ;01D10B|18      |      ;
                       ADC.B #$03                         ;01D10C|6903    |      ;
                       AND.B #$0F                         ;01D10E|290F    |      ;
                       STA.W $192B                        ;01D110|8D2B19  |01192B;
                       DEY                                 ;01D113|88      |      ;
                       BNE CODE_01D0E8                     ;01D114|D0D2    |01D0E8;
                       REP #$30                           ;01D116|C230    |      ;
                       LDA.W $1933                        ;01D118|AD3319  |011933;
                       STA.W $1900                        ;01D11B|8D0019  |011900;
                       PLP                                 ;01D11E|28      |      ;
                       RTS                                 ;01D11F|60      |      ;

; ==============================================================================
; Advanced Character Sprite Discovery System
; Complex character sprite discovery with battle coordination
; ==============================================================================

CODE_01D120:
                       LDA.B #$00                         ;01D120|A900    |      ;
                       JSR.W CODE_01B1EB                   ;01D122|20EBB1  |01B1EB;
                       BCC CODE_01D14D                     ;01D125|9026    |01D14D;
                       STX.W $1935                        ;01D127|8E3519  |011935;
                       STA.W $1937                        ;01D12A|8D3719  |011937;
                       LDA.W $1A72,X                      ;01D12D|BD721A  |011A72;
                       STA.W $1938                        ;01D130|8D3819  |011938;
                       JSR.W CODE_01D14E                   ;01D133|204ED1  |01D14E;
                       LDA.B #$01                         ;01D136|A901    |      ;
                       JSR.W CODE_01B1EB                   ;01D138|20EBB1  |01B1EB;
                       BCC CODE_01D14D                     ;01D13B|9010    |01D14D;
                       STX.W $1939                        ;01D13D|8E3919  |011939;
                       STA.W $193B                        ;01D140|8D3B19  |01193B;
                       LDA.W $1A72,X                      ;01D143|BD721A  |011A72;
                       STA.W $1938                        ;01D146|8D3819  |011938;
                       JSR.W CODE_01D14E                   ;01D149|204ED1  |01D14E;
                       SEC                                 ;01D14C|38      |      ;

CODE_01D14D:
                       RTS                                 ;01D14D|60      |      ;

CODE_01D14E:
                       LDA.W $1A80,X                      ;01D14E|BD801A  |011A80;
                       AND.B #$3F                         ;01D151|293F    |      ;
                       ORA.B #$80                         ;01D153|0980    |      ;
                       STA.W $1A80,X                      ;01D155|9D801A  |011A80;
                       RTS                                 ;01D158|60      |      ;

; ==============================================================================
; Advanced Color Management and Processing
; Complex color management with advanced coordination systems
; ==============================================================================

CODE_01D159:
                       PHP                                 ;01D159|08      |      ;
                       REP #$30                           ;01D15A|C230    |      ;
                       LDA.W $192B                        ;01D15C|AD2B19  |01192B;
                       STA.W $192F                        ;01D15F|8D2F19  |01192F;
                       CMP.W #$7FFF                       ;01D162|C9FF7F  |      ;
                       BEQ CODE_01D170                     ;01D165|F009    |01D170;
                       JSR.W CODE_01D1E1                   ;01D167|20E1D1  |01D1E1;
                       JSR.W CODE_01D1F4                   ;01D16A|20F4D1  |01D1F4;
                       JSR.W CODE_01D20D                   ;01D16D|200DD2  |01D20D;

CODE_01D170:
                       PLP                                 ;01D170|28      |      ;
                       RTS                                 ;01D171|60      |      ;

; ==============================================================================
; Complex Color Component Processing Engine
; Advanced color component processing with RGB coordination
; ==============================================================================

                       db $08,$C2,$30,$AD,$2B,$19,$8D,$2F,$19,$C9,$FF,$7F,$F0,$5F,$CD,$2D ; 01D172
                       db $19,$F0,$5A,$AD,$2D,$19,$29,$1F,$00,$8D,$31,$19,$AD,$2B,$19,$29 ; 01D182
                       db $1F,$00,$CD,$31,$19,$90,$05,$8D,$2F,$19,$80,$03,$20,$E1,$D1,$AD ; 01D192
                       db $2D,$19,$29,$E0,$03,$8D,$31,$19,$AD,$2B,$19,$29,$E0,$03,$CD,$31 ; 01D1A2
                       db $19,$90,$08,$0D,$2F,$19,$8D,$2F,$19,$80,$03,$20,$F4,$D1,$AD,$2D ; 01D1B2
                       db $19,$29,$00,$7C,$8D,$31,$19,$AD,$2B,$19,$29,$00,$7C,$CD,$31,$19 ; 01D1C2
                       db $90,$08,$0D,$2F,$19,$8D,$2F,$19,$80,$03,$20,$0D,$D2,$28,$60       ; 01D1D2

; ==============================================================================
; Red Component Color Processing
; Handles red component color processing with precision control
; ==============================================================================

CODE_01D1E1:
                       LDA.W $192B                        ;01D1E1|AD2B19  |01192B;
                       AND.W #$001F                       ;01D1E4|291F00  |      ;
                       CMP.W #$001F                       ;01D1E7|C91F00  |      ;
                       BEQ CODE_01D1F0                     ;01D1EA|F004    |01D1F0;
                       INC A                               ;01D1EC|1A      |      ;
                       AND.W #$001F                       ;01D1ED|291F00  |      ;

CODE_01D1F0:
                       STA.W $192F                        ;01D1F0|8D2F19  |01192F;
                       RTS                                 ;01D1F3|60      |      ;

; ==============================================================================
; Green Component Color Processing
; Handles green component color processing with precision control
; ==============================================================================

CODE_01D1F4:
                       LDA.W $192B                        ;01D1F4|AD2B19  |01192B;
                       AND.W #$03E0                       ;01D1F7|29E003  |      ;
                       CMP.W #$03E0                       ;01D1FA|C9E003  |      ;
                       BEQ CODE_01D206                     ;01D1FD|F007    |01D206;
                       CLC                                 ;01D1FF|18      |      ;
                       ADC.W #$0020                       ;01D200|692000  |      ;
                       AND.W #$03E0                       ;01D203|29E003  |      ;

CODE_01D206:
                       ORA.W $192F                        ;01D206|0D2F19  |01192F;
                       STA.W $192F                        ;01D209|8D2F19  |01192F;
                       RTS                                 ;01D20C|60      |      ;

; ==============================================================================
; Blue Component Color Processing
; Handles blue component color processing with precision control
; ==============================================================================

CODE_01D20D:
                       LDA.W $192B                        ;01D20D|AD2B19  |01192B;
                       AND.W #$7C00                       ;01D210|29007C  |      ;
                       CMP.W #$7C00                       ;01D213|C9007C  |      ;
                       BEQ CODE_01D21F                     ;01D216|F007    |01D21F;
                       CLC                                 ;01D218|18      |      ;
                       ADC.W #$0400                       ;01D219|690004  |      ;
                       AND.W #$7C00                       ;01D21C|29007C  |      ;

CODE_01D21F:
                       ORA.W $192F                        ;01D21F|0D2F19  |01192F;
                       STA.W $192F                        ;01D222|8D2F19  |01192F;
                       RTS                                 ;01D225|60      |      ;

; ==============================================================================
; Advanced Color Fade Control System
; Complex color fade control with advanced timing coordination
; ==============================================================================

CODE_01D226:
                       PHP                                 ;01D226|08      |      ;
                       REP #$30                           ;01D227|C230    |      ;
                       LDA.W $192B                        ;01D229|AD2B19  |01192B;
                       STA.W $192F                        ;01D22C|8D2F19  |01192F;
                       BEQ CODE_01D23A                     ;01D22F|F009    |01D23A;
                       JSR.W CODE_01D2AC                   ;01D231|20ACD2  |01D2AC;
                       JSR.W CODE_01D2B9                   ;01D234|20B9D2  |01D2B9;
                       JSR.W CODE_01D2CC                   ;01D237|20CCD2  |01D2CC;

CODE_01D23A:
                       PLP                                 ;01D23A|28      |      ;
                       RTS                                 ;01D23B|60      |      ;

; ==============================================================================
; Advanced Color Interpolation Engine
; Complex color interpolation with advanced blending coordination
; ==============================================================================

CODE_01D23C:
                       PHP                                 ;01D23C|08      |      ;
                       REP #$30                           ;01D23D|C230    |      ;
                       LDA.W $192B                        ;01D23F|AD2B19  |01192B;
                       STA.W $192F                        ;01D242|8D2F19  |01192F;
                       CMP.W $192D                        ;01D245|CD2D19  |01192D;
                       BEQ CODE_01D2AA                     ;01D248|F060    |01D2AA;
                       LDA.W $192D                        ;01D24A|AD2D19  |01192D;
                       AND.W #$001F                       ;01D24D|291F00  |      ;
                       STA.W $1931                        ;01D250|8D3119  |011931;
                       LDA.W $192B                        ;01D253|AD2B19  |01192B;
                       AND.W #$001F                       ;01D256|291F00  |      ;
                       CMP.W $1931                        ;01D259|CD3119  |011931;
                       BEQ CODE_01D260                     ;01D25C|F002    |01D260;
                       BCS CODE_01D265                     ;01D25E|B005    |01D265;

CODE_01D260:
                       STA.W $192F                        ;01D260|8D2F19  |01192F;
                       BRA CODE_01D268                     ;01D263|8003    |01D268;

CODE_01D265:
                       JSR.W CODE_01D2AC                   ;01D265|20ACD2  |01D2AC;

CODE_01D268:
                       LDA.W $192D                        ;01D268|AD2D19  |01192D;
                       AND.W #$03E0                       ;01D26B|29E003  |      ;
                       STA.W $1931                        ;01D26E|8D3119  |011931;
                       LDA.W $192B                        ;01D271|AD2B19  |01192B;
                       AND.W #$03E0                       ;01D274|29E003  |      ;
                       CMP.W $1931                        ;01D277|CD3119  |011931;
                       BEQ CODE_01D27E                     ;01D27A|F002    |01D27E;
                       BCS CODE_01D286                     ;01D27C|B008    |01D286;

CODE_01D27E:
                       ORA.W $192F                        ;01D27E|0D2F19  |01192F;
                       STA.W $192F                        ;01D281|8D2F19  |01192F;
                       BRA CODE_01D289                     ;01D284|8003    |01D289;

CODE_01D286:
                       JSR.W CODE_01D2B9                   ;01D286|20B9D2  |01D2B9;

CODE_01D289:
                       LDA.W $192D                        ;01D289|AD2D19  |01192D;
                       AND.W #$7C00                       ;01D28C|29007C  |      ;
                       STA.W $1931                        ;01D28F|8D3119  |011931;
                       LDA.W $192B                        ;01D292|AD2B19  |01192B;
                       AND.W #$7C00                       ;01D295|29007C  |      ;
                       CMP.W $1931                        ;01D298|CD3119  |011931;
                       BEQ CODE_01D29F                     ;01D29B|F002    |01D29F;
                       BCS CODE_01D2A7                     ;01D29D|B008    |01D2A7;

CODE_01D29F:
                       ORA.W $192F                        ;01D29F|0D2F19  |01192F;
                       STA.W $192F                        ;01D2A2|8D2F19  |01192F;
                       BRA CODE_01D2AA                     ;01D2A5|8003    |01D2AA;

CODE_01D2A7:
                       JSR.W CODE_01D2CC                   ;01D2A7|20CCD2  |01D2CC;

CODE_01D2AA:
                       PLP                                 ;01D2AA|28      |      ;
                       RTS                                 ;01D2AB|60      |      ;

; ==============================================================================
; Red Component Fade Processing
; Handles red component fade processing with precision control
; ==============================================================================

CODE_01D2AC:
                       LDA.W $192B                        ;01D2AC|AD2B19  |01192B;
                       AND.W #$001F                       ;01D2AF|291F00  |      ;
                       BEQ CODE_01D2B5                     ;01D2B2|F001    |01D2B5;
                       DEC A                               ;01D2B4|3A      |      ;

CODE_01D2B5:
                       STA.W $192F                        ;01D2B5|8D2F19  |01192F;
                       RTS                                 ;01D2B8|60      |      ;

; ==============================================================================
; Green Component Fade Processing  
; Handles green component fade processing with precision control
; ==============================================================================

CODE_01D2B9:
                       LDA.W $192B                        ;01D2B9|AD2B19  |01192B;
                       AND.W #$03E0                       ;01D2BC|29E003  |      ;
                       BEQ CODE_01D2C5                     ;01D2BF|F004    |01D2C5;
                       SEC                                 ;01D2C1|38      |      ;
                       SBC.W #$0020                       ;01D2C2|E92000  |      ;

CODE_01D2C5:
                       ORA.W $192F                        ;01D2C5|0D2F19  |01192F;
                       STA.W $192F                        ;01D2C8|8D2F19  |01192F;
                       RTS                                 ;01D2CB|60      |      ;

; ==============================================================================
; Blue Component Fade Processing
; Handles blue component fade processing with precision control
; ==============================================================================

CODE_01D2CC:
                       LDA.W $192B                        ;01D2CC|AD2B19  |01192B;
                       AND.W #$7C00                       ;01D2CF|29007C  |      ;
                       BEQ CODE_01D2D8                     ;01D2D2|F004    |01D2D8;
                       SEC                                 ;01D2D4|38      |      ;
                       SBC.W #$0400                       ;01D2D5|E90004  |      ;

CODE_01D2D8:
                       ORA.W $192F                        ;01D2D8|0D2F19  |01192F;
                       STA.W $192F                        ;01D2DB|8D2F19  |01192F;
                       RTS                                 ;01D2DE|60      |      ;

; ==============================================================================
; Advanced Palette Buffer Management System
; Complex palette buffer management with DMA coordination
; ==============================================================================

CODE_01D2DF:
                       PHP                                 ;01D2DF|08      |      ;
                       REP #$30                           ;01D2E0|C230    |      ;
                       PHB                                 ;01D2E2|8B      |      ;
                       PEA.W $7F00                        ;01D2E3|F4007F  |017F00;
                       PLB                                 ;01D2E6|AB      |      ;
                       PLB                                 ;01D2E7|AB      |      ;
                       LDX.W #$0000                       ;01D2E8|A20000  |      ;
                       LDY.W #$0000                       ;01D2EB|A00000  |      ;
                       LDA.W #$0040                       ;01D2EE|A94000  |      ;

CODE_01D2F1:
                       PHA                                 ;01D2F1|48      |      ;
                       LDA.W $C588,X                      ;01D2F2|BD88C5  |7FC588;
                       STA.W $C608,Y                      ;01D2F5|9908C6  |7FC608;
                       INX                                 ;01D2F8|E8      |      ;
                       INX                                 ;01D2F9|E8      |      ;
                       INY                                 ;01D2FA|C8      |      ;
                       INY                                 ;01D2FB|C8      |      ;
                       PLA                                 ;01D2FC|68      |      ;
                       DEC A                               ;01D2FD|3A      |      ;
                       BNE CODE_01D2F1                     ;01D2FE|D0F1    |01D2F1;
                       PLB                                 ;01D300|AB      |      ;
                       SEP #$20                           ;01D301|E220    |      ;
                       REP #$10                           ;01D303|C210    |      ;
                       LDA.B #$F1                         ;01D305|A9F1    |      ;
                       STA.W $050A                        ;01D307|8D0A05  |01050A;
                       LDA.B #$0A                         ;01D30A|A90A    |      ;
                       STA.W $1935                        ;01D30C|8D3519  |011935;

; ==============================================================================
; Advanced Palette Animation Loop
; Complex palette animation loop with timing coordination
; ==============================================================================

CODE_01D30F:
                       PHP                                 ;01D30F|08      |      ;
                       REP #$30                           ;01D310|C230    |      ;
                       LDY.W #$0040                       ;01D312|A04000  |      ;
                       LDX.W #$0000                       ;01D315|A20000  |      ;

CODE_01D318:
                       LDA.L $7FC588,X                    ;01D318|BF88C57F|7FC588;
                       STA.W $192B                        ;01D31C|8D2B19  |01192B;
                       JSR.W CODE_01D226                   ;01D31F|2026D2  |01D226;
                       LDA.W $192F                        ;01D322|AD2F19  |01192F;
                       STA.L $7FC588,X                    ;01D325|9F88C57F|7FC588;
                       INX                                 ;01D329|E8      |      ;
                       INX                                 ;01D32A|E8      |      ;
                       DEY                                 ;01D32B|88      |      ;
                       BNE CODE_01D318                     ;01D32C|D0EA    |01D318;
                       PLP                                 ;01D32E|28      |      ;
                       LDA.B #$05                         ;01D32F|A905    |      ;
                       STA.W $1A46                        ;01D331|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D334|20F38D  |018DF3;
                       LDA.B #$10                         ;01D337|A910    |      ;
                       JSR.W CODE_01D6A9                   ;01D339|20A9D6  |01D6A9;
                       DEC.W $1935                        ;01D33C|CE3519  |011935;
                       BNE CODE_01D30F                     ;01D33F|D0CE    |01D30F;
                       JSR.W CODE_01D346                   ;01D341|2046D3  |01D346;
                       PLP                                 ;01D344|28      |      ;
                       RTS                                 ;01D345|60      |      ;

; ==============================================================================
; Advanced Memory Clear and Buffer Initialization
; Complex memory clear with advanced buffer initialization
; ==============================================================================

CODE_01D346:
                       PHB                                 ;01D346|8B      |      ;
                       LDA.B #$00                         ;01D347|A900    |      ;
                       STA.L $7F2000                      ;01D349|8F00207F|7F2000;
                       LDX.W #$2000                       ;01D34D|A20020  |      ;
                       LDY.W #$2001                       ;01D350|A00120  |      ;
                       LDA.B #$02                         ;01D353|A902    |      ;
                       XBA                                 ;01D355|EB      |      ;
                       LDA.B #$00                         ;01D356|A900    |      ;
                       MVN $7F,$7F                       ;01D358|547F7F  |      ;
                       PLB                                 ;01D35B|AB      |      ;
                       RTS                                 ;01D35C|60      |      ;
