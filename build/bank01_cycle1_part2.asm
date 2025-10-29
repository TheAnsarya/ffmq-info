          CODE_018272:
                       SEP #                             ;018272|E220    |      ;
                       REP #                             ;018274|C210    |      ;
                       PHK                                  ;018276|4B      |      ;
                       PLB                                  ;018277|AB      |      ;
                       LDX.W #                         ;018278|A2FFFF  |      ;
                       STX.W                           ;01827B|8E5F19  |01195F;
                       LDX.W #                         ;01827E|A20080  |      ;
                       STX.W                           ;018281|8E481A  |011A48;
                       STZ.W                           ;018284|9C2A19  |01192A;
                       JSR.W CODE_018C5B                    ;018287|205B8C  |018C5B;
                       LDA.W                           ;01828A|AD910E  |010E91;
                       STA.W                           ;01828D|8DF019  |0119F0;
                       LDX.W                           ;018290|AE890E  |010E89;
                       STX.W                           ;018293|8EF119  |0119F1;
                       LDA.B #                           ;018296|A980    |      ;
                       STA.W                           ;018298|8D1001  |010110;
                       JSR.W CODE_01914D                    ;01829B|204D91  |01914D;
                       LDA.W                           ;01829E|AD880E  |000E88;
                       CMP.B #                           ;0182A1|C915    |      ;
                       BNE CODE_0182A9                      ;0182A3|D004    |0182A9;
                       JSL.L CODE_009A60                    ;0182A5|22609A00|009A60;
                                                            ;      |        |      ;
          CODE_0182A9:
                       INC.W                           ;0182A9|EEF719  |0119F7;
                       STZ.W                           ;0182AC|9CF819  |0119F8;
                       JSR.W CODE_01E9B3                    ;0182AF|20B3E9  |01E9B3;
                       JSR.W CODE_0182F2                    ;0182B2|20F282  |0182F2;
                       LDA.W                           ;0182B5|ADB019  |0119B0;
                       BEQ CODE_0182BE                      ;0182B8|F004    |0182BE;
                       JSL.L CODE_01B24C                    ;0182BA|224CB201|01B24C;
                                                            ;      |        |      ;
          CODE_0182BE:
                       LDA.W                           ;0182BE|ADF819  |0119F8;
                       BNE CODE_0182A9                      ;0182C1|D0E6    |0182A9;
                       JSR.W CODE_01AB5D                    ;0182C3|205DAB  |01AB5D;
                       JSR.W CODE_01A081                    ;0182C6|2081A0  |01A081;
                                                            ;      |        |      ;
          CODE_0182C9:
                       LDA.W                           ;0182C9|ADF719  |0119F7;
                       BNE CODE_0182C9                      ;0182CC|D0FB    |0182C9;
                       BRA CODE_0182A9                      ;0182CE|80D9    |0182A9;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0182D0:
                       PHP                                  ;0182D0|08      |      ;
                       PHX                                  ;0182D1|DA      |      ;
                       PHY                                  ;0182D2|5A      |      ;
                       SEP #                             ;0182D3|E220    |      ;
                       REP #                             ;0182D5|C210    |      ;
                       BRA CODE_0182E3                      ;0182D7|800A    |0182E3;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0182D9:
                       PHP                                  ;0182D9|08      |      ;
                       PHX                                  ;0182DA|DA      |      ;
                       PHY                                  ;0182DB|5A      |      ;
                       SEP #                             ;0182DC|E220    |      ;
                       REP #                             ;0182DE|C210    |      ;
                       JSR.W CODE_01AB5D                    ;0182E0|205DAB  |01AB5D;
                                                            ;      |        |      ;
          CODE_0182E3:
                       JSR.W CODE_01A081                    ;0182E3|2081A0  |01A081;
                                                            ;      |        |      ;
          CODE_0182E6:
                       LDA.W                           ;0182E6|ADF719  |0019F7;
                       BNE CODE_0182E6                      ;0182E9|D0FB    |0182E6;
                       INC.W                           ;0182EB|EEF719  |0019F7;
                       PLY                                  ;0182EE|7A      |      ;
                       PLX                                  ;0182EF|FA      |      ;
                       PLP                                  ;0182F0|28      |      ;
                       RTS                                  ;0182F1|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0182F2:
                       REP #                             ;0182F2|C220    |      ;
                       AND.W #                         ;0182F4|29FF00  |      ;
                       ASL A                                ;0182F7|0A      |      ;
                       TAX                                  ;0182F8|AA      |      ;
                       SEP #                             ;0182F9|E220    |      ;
                       JMP.W (DATA8_0182FE,X)               ;0182FB|7CFE82  |0182FE;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
         DATA8_0182FE:
                       db ,,,,,,,,,,,,,,,;0182FE|        |      ;
                       db ,,,,,,,,,,,,,,,;01830E|        |      ;
                       db ,                           ;01831E|        |      ;
                       SEP #                             ;018320|E220    |      ;
                       REP #                             ;018322|C210    |      ;
                       PHB                                  ;018324|8B      |      ;
                       LDA.W                           ;018325|ADA519  |0019A5;
                       BNE CODE_01832D                      ;018328|D003    |01832D;
                       JSR.W CODE_018A2D                    ;01832A|202D8A  |018A2D;
                                                            ;      |        |      ;
          CODE_01832D:
                       PLB                                  ;01832D|AB      |      ;
                       RTL                                  ;01832E|6B      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
         DATA8_01832F:
                       db                                ;01832F|        |      ;
                                                            ;      |        |      ;
         DATA8_018330:
                       db ,,,,,,       ;018330|        |      ;
                       PHP                                  ;018337|08      |      ;
                       PHB                                  ;018338|8B      |      ;
                       PHK                                  ;018339|4B      |      ;
                       PLB                                  ;01833A|AB      |      ;
                       SEP #                             ;01833B|E220    |      ;
                       REP #                             ;01833D|C210    |      ;
                       LDA.W                           ;01833F|ADA519  |0119A5;
                       BMI CODE_018358                      ;018342|3014    |018358;
                       JSR.W CODE_018E07                    ;018344|20078E  |018E07;
                       JSR.W CODE_01973A                    ;018347|203A97  |01973A;
                       LDA.B #                           ;01834A|A900    |      ;
                       XBA                                  ;01834C|EB      |      ;
                       LDA.W                           ;01834D|AD461A  |011A46;
                       ASL A                                ;018350|0A      |      ;
                       TAX                                  ;018351|AA      |      ;
                       JSR.W (DATA8_01835B,X)               ;018352|FC5B83  |01835B;
                       STZ.W                           ;018355|9C461A  |011A46;
                                                            ;      |        |      ;
          CODE_018358:
                       PLB                                  ;018358|AB      |      ;
                       PLP                                  ;018359|28      |      ;
                       RTL                                  ;01835A|6B      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
         DATA8_01835B:
                       db ,,,,,,,,,,,,,,,;01835B|        |      ;
                       db ,                           ;01836B|        |      ;
                                                            ;      |        |      ;
          CODE_01836D:
                       LDX.W #                         ;01836D|A20000  |      ;
                       TXA                                  ;018370|8A      |      ;
                       XBA                                  ;018371|EB      |      ;
                                                            ;      |        |      ;
          CODE_018372:
                       LDA.W DATA8_01839F,X                 ;018372|BD9F83  |01839F;
                       STA.W                           ;018375|8D2121  |012121;
                       LDY.W #                         ;018378|A00022  |      ;
                       STY.W                           ;01837B|8C0043  |014300;
                       LDY.W DATA8_0183A0,X                 ;01837E|BCA083  |0183A0;
                       STY.W                           ;018381|8C0243  |014302;
                       LDA.B #                           ;018384|A97F    |      ;
                       STA.W                           ;018386|8D0443  |014304;
                       LDA.W DATA8_0183A2,X                 ;018389|BDA283  |0183A2;
                       TAY                                  ;01838C|A8      |      ;
                       STY.W                           ;01838D|8C0543  |014305;
                       LDA.B #                           ;018390|A901    |      ;
                       STA.W                           ;018392|8D0B42  |01420B;
                       INX                                  ;018395|E8      |      ;
                       INX                                  ;018396|E8      |      ;
                       INX                                  ;018397|E8      |      ;
                       INX                                  ;018398|E8      |      ;
                       CPX.W #                         ;018399|E02000  |      ;
                       BNE CODE_018372                      ;01839C|D0D4    |018372;
                       RTS                                  ;01839E|60      |      ;
