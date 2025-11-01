; Final Fantasy Mystic Quest - Item Data
; Extracted from ROM


; WEAPONS (15 entries)
weapons_data:
  ; weapons_00
  db $FF, $7C, $83, $FF, $38
  dw $CFFF, $FFFF
  db $FF
  db $FF, $FF, $C7, $00, $0C, $A0

  ; weapons_01
  db $F1, $B9, $C6, $43, $FC
  dw $F00F, $FFE6
  db $0C
  db $F3, $92, $7F, $FF, $FF, $FF

  ; weapons_02
  db $FF, $FF, $FF, $FF, $FF
  dw $FF55, $FF00
  db $00
  db $FF, $0B, $FB, $04, $4D, $8C

  ; weapons_03
  db $83, $83, $FF, $3D, $FF
  dw $FFFF, $0455
  db $B2
  db $70, $00, $00, $55, $FF, $00

  ; weapons_04
  db $FF, $00, $FF, $18, $FB
  dw $9F86, $FE7A
  db $81
  db $FF, $FE, $1F, $FF, $FF, $55

  ; weapons_05
  db $04, $60, $01, $00, $00
  dw $FFB0, $C7FD
  db $20
  db $FF, $58, $FF, $AA, $FF, $A5

  ; weapons_06
  db $FF, $14, $FF, $40, $BF
  dw $0200, $850B
  db $D5
  db $DF, $FF, $FF, $60, $FF, $03

  ; weapons_07
  db $FF, $66, $FF, $49, $FF
  dw $FF15, $FF94
  db $70
  db $DF, $22, $DF, $10, $58, $19

  ; weapons_08
  db $B6, $FA, $FF, $FF, $FF
  dw $0AFF, $C13F
  db $C7
  db $38, $F8, $47, $FE, $A1, $FF

  ; weapons_09
  db $D4, $FF, $FA, $FF, $FF
  dw $FEF5, $BFFF
  db $5F
  db $2B, $05, $00, $FF, $BF, $FF

  ; weapons_10
  db $55, $FF, $0A, $2F, $D0
  dw $55AA, $A857
  db $EA
  db $15, $F5, $8A, $40, $AA, $F5

  ; weapons_11
  db $FF, $FF, $FF, $FF, $7F
  dw $BAFF, $55FF
  db $FF
  db $00, $FF, $00, $00, $FF, $FE

  ; weapons_12
  db $01, $FF, $2A, $7F, $80
  dw $AA45, $FFFF
  db $FF
  db $FF, $D5, $FF, $FF, $A0, $FE

  ; weapons_13
  db $41, $F9, $06, $C7, $39
  dw $CA3F, $857F
  db $9F
  db $60, $E3, $1C, $5F, $BF, $FF

  ; weapons_14
  db $FE, $F5, $FA, $FF, $FF
  dw $FAFF, $54FF
  db $FF
  db $00, $FA, $05, $AF, $50, $FF


; ARMOR (7 entries)
armor_data:
  ; armor_00
  db $03, $F3, $0C, $0F, $F1
  dw $2AFF, $5FFF
  db $FF
  db $BF, $FF, $55, $5F, $FF, $FF

  ; armor_01
  db $FE, $D5, $A0, $40, $AA
  dw $40BF, $10EF
  db $F3
  db $4C, $FC, $AB, $FF, $FA, $FF

  ; armor_02
  db $54, $FF, $00, $FE, $01
  dw $FFFF, $57BF
  db $05
  db $AB, $FF, $FF, $FF, $AA, $FF

  ; armor_03
  db $15, $FF, $00, $3F, $C0
  dw $3FC0, $08F7
  db $C9
  db $36, $1C, $E3, $55, $EA, $FF

  ; armor_04
  db $FF, $FF, $FF, $FF, $FF
  dw $F30C, $7E81
  db $2A
  db $D5, $FF, $00, $FF, $00, $00

  ; armor_05
  db $FF, $E7, $1F, $3F, $C0
  dw $FFFF, $FFFF
  db $FF
  db $FF, $FF, $FF, $00, $FF, $54

  ; armor_06
  db $AB, $FF, $00, $FF, $00
  dw $1FE0, $F40B
  db $3F
  db $C0, $00, $FF, $FF, $FF, $FF


; HELMETS (7 entries)
helmets_data:
  ; helmets_00
  db $7F, $10, $FF, $88, $FF
  dw $FFFF, $FFFF
  db $FF
  db $FF, $FF, $FF, $66, $F9, $11

  ; helmets_01
  db $FF, $80, $FF, $04, $FF
  dw $FFF0, $D728
  db $FF
  db $FF, $0C, $FE, $FF, $FF, $FF

  ; helmets_02
  db $FF, $FF, $FF, $FF, $FF
  dw $FF00, $AA55
  db $EB
  db $14, $1F, $E0, $E1, $1F, $C3

  ; helmets_03
  db $3C, $3F, $C0, $00, $FF
  dw $FFFF, $FFFF
  db $FF
  db $FF, $FF, $FF, $05, $FA, $4A

  ; helmets_04
  db $B5, $F5, $0A, $8F, $70
  dw $FFE0, $00FF
  db $E7
  db $18, $7E, $FF, $FF, $FF, $FF

  ; helmets_05
  db $FF, $FF, $FF, $FF, $FF
  dw $FCFB, $9F60
  db $11
  db $FF, $C6, $F9, $16, $FF, $80

  ; helmets_06
  db $FF, $01, $FF, $00, $00
  dw $FFFF, $FFFF
  db $FF
  db $FF, $FF, $FF, $92, $7F, $0C


; SHIELDS (7 entries)
shields_data:
  ; shields_00
  db $FF, $FF, $FF, $FF, $FF
  dw $FF99, $DFA6
  db $B9
  db $DF, $BF, $C0, $BF, $C0, $BF

  ; shields_01
  db $D5, $80, $FF, $9F, $F0
  dw $8080, $8080
  db $FF
  db $EA, $C0, $CF, $DD, $FF, $64

  ; shields_02
  db $FF, $C7, $FF, $E3, $1E
  dw $01FE, $55FE
  db $06
  db $FF, $FE, $37, $00, $00, $00

  ; shields_03
  db $01, $FF, $AB, $01, $C9
  dw $E31F, $F43F
  db $3F
  db $E1, $3F, $EE, $7F, $E0, $68

  ; shields_04
  db $D7, $40, $FF, $FF, $FF
  dw $CBDC, $D1DE
  db $DF
  db $FF, $FF, $FF, $FE, $4B, $FE

  ; shields_05
  db $A1, $FE, $5D, $FE, $A1
  dw $8BFF, $2DD3
  db $01
  db $FF, $FF, $FF, $B5, $5F, $A3

  ; shields_06
  db $5F, $75, $FF, $FF, $FF
  dw $FF7F, $FF42
  db $5F
  db $FF, $8B, $75, $FF, $00, $FF


; ACCESSORIES (11 entries)
accessories_data:
  ; accessories_00
  db $7F, $DF, $7F, $A1, $5E
  dw $A2FF, $ACFF
  db $8B
  db $F4, $FF, $FF, $80, $80, $80

  ; accessories_01
  db $80, $DD, $D3, $FF, $FF
  dw $FF00, $FF00
  db $FF
  db $B4, $FF, $48, $FF, $24, $67

  ; accessories_02
  db $98, $10, $EF, $FF, $FF
  dw $00FF, $B74B
  db $DB
  db $FF, $FF, $FF, $04, $FF, $77

  ; accessories_03
  db $ED, $F5, $1E, $F7, $CC
  dw $6EF5, $6D96
  db $04
  db $FF, $FF, $FF, $FF, $1E, $EF

  ; accessories_04
  db $3F, $9F, $FF, $FF, $FF
  dw $FF08, $DBEF
  db $EF
  db $59, $EB, $9F, $EF, $59, $EB

  ; accessories_05
  db $1C, $2C, $DB, $FF, $FF
  dw $3CFF, $7CBE
  db $BE
  db $FF, $FF, $FF, $00, $FF, $00

  ; accessories_06
  db $FF, $FF, $0F, $FF, $C0
  dw $3CFF, $6699
  db $64
  db $9B, $FF, $FF, $FF, $00, $F0

  ; accessories_07
  db $3F, $C3, $FF, $FF, $FF
  dw $0000, $0000
  db $32
  db $20, $7D, $8E, $3C, $FF, $FD

  ; accessories_08
  db $F6, $FC, $E7, $7E, $CD
  dw $FFFF, $F3DF
  db $C3
  db $0B, $1B, $B3, $00, $00, $00

  ; accessories_09
  db $00, $10, $18, $78, $76
  dw $937C, $F70B
  db $DD
  db $3B, $3C, $FB, $FF, $FF, $EF

  ; accessories_10
  db $8F, $EF, $FC, $E6, $C7
  dw $3FF7, $5FBF
  db $B7
  db $4E, $9B, $67, $99, $77, $CE


; CONSUMABLES (20 entries)
consumables_data:
  ; consumables_00
  db $31, $E3, $C3
  dw $8FC7, $5AFF
  db $7F

  ; consumables_01
  db $B4, $FF, $18
  dw $857A, $23DC
  db $88

  ; consumables_02
  db $77, $06, $F9
  dw $609F, $CBA5
  db $E7

  ; consumables_03
  db $FF, $FF, $70
  dw $0000, $8FFF
  db $EF

  ; consumables_04
  db $10, $57, $A8
  dw $50AF, $CF3F
  db $FF

  ; consumables_05
  db $3F, $70, $8F
  dw $F807, $FF70
  db $FF

  ; consumables_06
  db $FF, $F0, $40
  dw $0000, $20FF
  db $FF

  ; consumables_07
  db $05, $FF, $38
  dw $F2FD, $BFFF
  db $FF

  ; consumables_08
  db $7F, $FF, $BF
  dw $7FFF, $FADF
  db $C7

  ; consumables_09
  db $0F, $40, $80
  dw $8040, $B8FF
  db $FD

  ; consumables_10
  db $62, $EA, $15
  dw $BA45, $C1FF
  db $FF

  ; consumables_11
  db $F7, $FF, $FC
  dw $7EFF, $9F47
  db $FF

  ; consumables_12
  db $FF, $3E, $08
  dw $8103, $C03F
  db $E7

  ; consumables_13
  db $1F, $00, $FF
  dw $0EFF, $01FF
  db $2A

  ; consumables_14
  db $D5, $81, $7E
  dw $C33C, $FFFF
  db $FF

  ; consumables_15
  db $F1, $FE, $FF
  dw $FFFF, $FF00
  db $3F

  ; consumables_16
  db $CE, $0B, $F4
  dw $1FE0, $8AFF
  db $FF

  ; consumables_17
  db $01, $57, $A8
  dw $05FF, $F1FF
  db $FF

  ; consumables_18
  db $FF, $75, $FE
  dw $FAFF, $0000
  db $00

  ; consumables_19
  db $00, $01, $01
  dw $7767, $DEE3
  db $C8

