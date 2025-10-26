;==============================================================================
; Final Fantasy Mystic Quest - Enemy Data
; Extracted and converted to assembly format
;==============================================================================

org $030000

; Enemy Count: 215
; Entry Size: 40 bytes

; Enemy_000 (ID $00)
enemy_000:
  dw $2220        ; HP
  db $22          ; Attack
  db $20          ; Defense
  db $22          ; Magic
  db $21          ; Magic Defense
  db $21          ; Speed
  db $22          ; Accuracy
  db $3A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $3B47        ; EXP
  dw $4721        ; Gold
  db $24          ; Drop Item
  db $21          ; Drop Rate
  db $24          ; Graphics ID
  db $20          ; Palette
  dw $2420        ; AI Script

; Enemy_001 (ID $01)
enemy_001:
  dw $1D2E        ; HP
  db $1D          ; Attack
  db $1F          ; Defense
  db $1D          ; Magic
  db $2E          ; Magic Defense
  db $1F          ; Speed
  db $1D          ; Accuracy
  db $1F          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1F2F        ; EXP
  dw $1F2F        ; Gold
  db $1E          ; Drop Item
  db $1F          ; Drop Rate
  db $11          ; Graphics ID
  db $1E          ; Palette
  dw $1E1F        ; AI Script

; Enemy_002 (ID $02)
enemy_002:
  dw $0908        ; HP
  db $09          ; Attack
  db $08          ; Defense
  db $20          ; Magic
  db $21          ; Magic Defense
  db $54          ; Speed
  db $20          ; Accuracy
  db $7F          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $7877        ; EXP
  dw $7778        ; Gold
  db $2E          ; Drop Item
  db $2E          ; Drop Rate
  db $2E          ; Graphics ID
  db $2E          ; Palette
  dw $2E2E        ; AI Script

; Enemy_003 (ID $03)
enemy_003:
  dw $113E        ; HP
  db $3D          ; Attack
  db $3E          ; Defense
  db $10          ; Magic
  db $3E          ; Magic Defense
  db $3E          ; Speed
  db $3D          ; Accuracy
  db $27          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $273B        ; EXP
  dw $2027        ; Gold
  db $08          ; Drop Item
  db $09          ; Drop Rate
  db $28          ; Graphics ID
  db $29          ; Palette
  dw $2156        ; AI Script

; Enemy_004 (ID $04)
enemy_004:
  dw $1210        ; HP
  db $12          ; Attack
  db $10          ; Defense
  db $12          ; Magic
  db $11          ; Magic Defense
  db $11          ; Speed
  db $12          ; Accuracy
  db $14          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1410        ; EXP
  dw $1411        ; Gold
  db $13          ; Drop Item
  db $13          ; Drop Rate
  db $11          ; Graphics ID
  db $10          ; Palette
  dw $1110        ; AI Script

; Enemy_005 (ID $05)
enemy_005:
  dw $3608        ; HP
  db $36          ; Attack
  db $00          ; Defense
  db $04          ; Magic
  db $01          ; Magic Defense
  db $04          ; Speed
  db $00          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0303        ; EXP
  dw $0001        ; Gold
  db $07          ; Drop Item
  db $3B          ; Drop Rate
  db $01          ; Graphics ID
  db $07          ; Palette
  dw $073B        ; AI Script

; Enemy_006 (ID $06)
enemy_006:
  dw $4B17        ; HP
  db $11          ; Attack
  db $17          ; Defense
  db $4B          ; Magic
  db $17          ; Magic Defense
  db $17          ; Speed
  db $10          ; Accuracy
  db $1E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1E2F        ; EXP
  dw $104F        ; Gold
  db $05          ; Drop Item
  db $46          ; Drop Rate
  db $3B          ; Graphics ID
  db $05          ; Palette
  dw $0546        ; AI Script

; Enemy_007 (ID $07)
enemy_007:
  dw $0C0C        ; HP
  db $1C          ; Attack
  db $1C          ; Defense
  db $50          ; Magic
  db $51          ; Magic Defense
  db $52          ; Speed
  db $53          ; Accuracy
  db $18          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4B4A        ; EXP
  dw $4A4B        ; Gold
  db $72          ; Drop Item
  db $75          ; Drop Rate
  db $74          ; Graphics ID
  db $79          ; Palette
  dw $7575        ; AI Script

; Enemy_008 (ID $08)
enemy_008:
  dw $7C7B        ; HP
  db $7B          ; Attack
  db $7C          ; Defense
  db $7D          ; Magic
  db $7E          ; Magic Defense
  db $7A          ; Speed
  db $79          ; Accuracy
  db $36          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0100        ; EXP
  dw $4601        ; Gold
  db $08          ; Drop Item
  db $09          ; Drop Rate
  db $0A          ; Graphics ID
  db $0B          ; Palette
  dw $6161        ; AI Script

; Enemy_009 (ID $09)
enemy_009:
  dw $7479        ; HP
  db $76          ; Attack
  db $73          ; Defense
  db $79          ; Magic
  db $7A          ; Magic Defense
  db $71          ; Speed
  db $79          ; Accuracy
  db $79          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5B00        ; EXP
  dw $0001        ; Gold
  db $58          ; Drop Item
  db $59          ; Drop Rate
  db $01          ; Graphics ID
  db $5A          ; Palette
  dw $1110        ; AI Script

; Enemy_010 (ID $0A)
enemy_010:
  dw $357F        ; HP
  db $35          ; Attack
  db $00          ; Defense
  db $35          ; Magic
  db $7F          ; Magic Defense
  db $01          ; Speed
  db $35          ; Accuracy
  db $17          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $7F7F        ; EXP
  dw $7F7F        ; Gold
  db $7F          ; Drop Item
  db $7F          ; Drop Rate
  db $7F          ; Graphics ID
  db $7F          ; Palette
  dw $3B3A        ; AI Script

; Enemy_011 (ID $0B)
enemy_011:
  dw $4B4A        ; HP
  db $4B          ; Attack
  db $4A          ; Defense
  db $4A          ; Magic
  db $4B          ; Magic Defense
  db $4B          ; Speed
  db $4A          ; Accuracy
  db $10          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1918        ; EXP
  dw $1819        ; Gold
  db $15          ; Drop Item
  db $70          ; Drop Rate
  db $4B          ; Graphics ID
  db $15          ; Palette
  dw $1570        ; AI Script

; Enemy_012 (ID $0C)
enemy_012:
  dw $647F        ; HP
  db $64          ; Attack
  db $6B          ; Defense
  db $68          ; Magic
  db $69          ; Magic Defense
  db $6A          ; Speed
  db $6B          ; Accuracy
  db $68          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6D6C        ; EXP
  dw $7F7F        ; Gold
  db $65          ; Drop Item
  db $69          ; Drop Rate
  db $7F          ; Graphics ID
  db $65          ; Palette
  dw $7F2B        ; AI Script

; Enemy_013 (ID $0D)
enemy_013:
  dw $0100        ; HP
  db $10          ; Attack
  db $11          ; Defense
  db $03          ; Magic
  db $04          ; Magic Defense
  db $13          ; Speed
  db $14          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $EE47        ; EXP
  dw $FE57        ; Gold
  db $8D          ; Drop Item
  db $9D          ; Drop Rate
  db $8D          ; Graphics ID
  db $9D          ; Palette
  dw $6564        ; AI Script

; Enemy_014 (ID $0E)
enemy_014:
  dw $6667        ; HP
  db $77          ; Attack
  db $BB          ; Defense
  db $B0          ; Magic
  db $A1          ; Magic Defense
  db $B2          ; Speed
  db $B3          ; Accuracy
  db $A1          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $A0B1        ; EXP
  dw $B2B3        ; Gold
  db $06          ; Drop Item
  db $07          ; Drop Rate
  db $16          ; Graphics ID
  db $17          ; Palette
  dw $0607        ; AI Script

; Enemy_015 (ID $0F)
enemy_015:
  dw $4647        ; HP
  db $57          ; Attack
  db $56          ; Defense
  db $00          ; Magic
  db $58          ; Magic Defense
  db $10          ; Speed
  db $11          ; Accuracy
  db $58          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0403        ; EXP
  dw $1413        ; Gold
  db $CE          ; Drop Item
  db $CE          ; Drop Rate
  db $DE          ; Graphics ID
  db $DE          ; Palette
  dw $B1A0        ; AI Script

; Enemy_016 (ID $10)
enemy_016:
  dw $0908        ; HP
  db $18          ; Attack
  db $19          ; Defense
  db $09          ; Magic
  db $08          ; Magic Defense
  db $0A          ; Speed
  db $1A          ; Accuracy
  db $43          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4545        ; EXP
  dw $5555        ; Gold
  db $44          ; Drop Item
  db $43          ; Drop Rate
  db $54          ; Graphics ID
  db $53          ; Palette
  dw $4C4B        ; AI Script

; Enemy_017 (ID $11)
enemy_017:
  dw $DCDC        ; HP
  db $F7          ; Attack
  db $F7          ; Defense
  db $CC          ; Magic
  db $48          ; Magic Defense
  db $48          ; Speed
  db $48          ; Accuracy
  db $48          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $C9C9        ; EXP
  dw $D9D9        ; Gold
  db $C8          ; Drop Item
  db $48          ; Drop Rate
  db $D8          ; Graphics ID
  db $48          ; Palette
  dw $4848        ; AI Script

; Enemy_018 (ID $12)
enemy_018:
  dw $4647        ; HP
  db $57          ; Attack
  db $46          ; Defense
  db $49          ; Magic
  db $4A          ; Magic Defense
  db $59          ; Speed
  db $5A          ; Accuracy
  db $4A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4748        ; EXP
  dw $5748        ; Gold
  db $47          ; Drop Item
  db $47          ; Drop Rate
  db $47          ; Graphics ID
  db $57          ; Palette
  dw $CA48        ; AI Script

; Enemy_019 (ID $13)
enemy_019:
  dw $CFCF        ; HP
  db $DF          ; Attack
  db $DF          ; Defense
  db $BB          ; Magic
  db $BB          ; Magic Defense
  db $BB          ; Speed
  db $BB          ; Accuracy
  db $EA          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $E900        ; EXP
  dw $FBFA        ; Gold
  db $00          ; Drop Item
  db $01          ; Drop Rate
  db $10          ; Graphics ID
  db $E9          ; Palette
  dw $EB00        ; AI Script

; Enemy_020 (ID $14)
enemy_020:
  dw $EBEA        ; HP
  db $46          ; Attack
  db $F8          ; Defense
  db $E9          ; Magic
  db $01          ; Magic Defense
  db $FA          ; Speed
  db $FB          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $01EA        ; EXP
  dw $FBFA        ; Gold
  db $EA          ; Drop Item
  db $01          ; Drop Rate
  db $FA          ; Graphics ID
  db $E9          ; Palette
  dw $F9EA        ; AI Script

; Enemy_021 (ID $15)
enemy_021:
  dw $0403        ; HP
  db $13          ; Attack
  db $14          ; Defense
  db $CD          ; Magic
  db $CD          ; Magic Defense
  db $DD          ; Speed
  db $DD          ; Accuracy
  db $CA          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBF9        ; EXP
  dw $BBBB        ; Gold
  db $EA          ; Drop Item
  db $EB          ; Drop Rate
  db $FA          ; Graphics ID
  db $BB          ; Palette
  dw $EBEA        ; AI Script

; Enemy_022 (ID $16)
enemy_022:
  dw $BBBB        ; HP
  db $BB          ; Attack
  db $BB          ; Defense
  db $BB          ; Magic
  db $BB          ; Magic Defense
  db $BB          ; Speed
  db $BB          ; Accuracy
  db $BB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBBB        ; EXP
  dw $BBBB        ; Gold
  db $42          ; Drop Item
  db $42          ; Drop Rate
  db $CD          ; Graphics ID
  db $CD          ; Palette
  dw $4242        ; AI Script

; Enemy_023 (ID $17)
enemy_023:
  dw $BBBB        ; HP
  db $BB          ; Attack
  db $BB          ; Defense
  db $BB          ; Magic
  db $BB          ; Magic Defense
  db $BB          ; Speed
  db $BB          ; Accuracy
  db $BB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBBB        ; EXP
  dw $BBBB        ; Gold
  db $BB          ; Drop Item
  db $BB          ; Drop Rate
  db $BB          ; Graphics ID
  db $BB          ; Palette
  dw $BBBB        ; AI Script

; Enemy_024 (ID $18)
enemy_024:
  dw $DDDD        ; HP
  db $55          ; Attack
  db $55          ; Defense
  db $DE          ; Magic
  db $DE          ; Magic Defense
  db $55          ; Speed
  db $55          ; Accuracy
  db $DF          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBBB        ; EXP
  dw $BBBB        ; Gold
  db $BB          ; Drop Item
  db $BB          ; Drop Rate
  db $BB          ; Graphics ID
  db $BB          ; Palette
  dw $BBBB        ; AI Script

; Enemy_025 (ID $19)
enemy_025:
  dw $BBBB        ; HP
  db $BB          ; Attack
  db $BB          ; Defense
  db $BB          ; Magic
  db $BB          ; Magic Defense
  db $BB          ; Speed
  db $BB          ; Accuracy
  db $BB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0100        ; EXP
  dw $1110        ; Gold
  db $8D          ; Drop Item
  db $9D          ; Drop Rate
  db $8D          ; Graphics ID
  db $9D          ; Palette
  dw $BBBB        ; AI Script

; Enemy_026 (ID $1A)
enemy_026:
  dw $0100        ; HP
  db $05          ; Attack
  db $15          ; Defense
  db $C8          ; Magic
  db $C8          ; Magic Defense
  db $C3          ; Speed
  db $D8          ; Accuracy
  db $C8          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $C8C8        ; EXP
  dw $C3D8        ; Gold
  db $00          ; Drop Item
  db $28          ; Drop Rate
  db $10          ; Graphics ID
  db $38          ; Palette
  dw $2524        ; AI Script

; Enemy_027 (ID $1B)
enemy_027:
  dw $8823        ; HP
  db $32          ; Attack
  db $FB          ; Defense
  db $CD          ; Magic
  db $DD          ; Magic Defense
  db $CD          ; Speed
  db $DD          ; Accuracy
  db $06          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0607        ; EXP
  dw $1617        ; Gold
  db $40          ; Drop Item
  db $41          ; Drop Rate
  db $50          ; Graphics ID
  db $51          ; Palette
  dw $4242        ; AI Script

; Enemy_028 (ID $1C)
enemy_028:
  dw $2900        ; HP
  db $10          ; Attack
  db $38          ; Defense
  db $37          ; Magic
  db $FB          ; Magic Defense
  db $37          ; Speed
  db $FB          ; Accuracy
  db $2B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $38          ; Drop Item
  db $01          ; Drop Rate
  db $29          ; Graphics ID
  db $11          ; Palette
  dw $FB22        ; AI Script

; Enemy_029 (ID $1D)
enemy_029:
  dw $4443        ; HP
  db $53          ; Attack
  db $54          ; Defense
  db $45          ; Magic
  db $45          ; Magic Defense
  db $55          ; Speed
  db $55          ; Accuracy
  db $44          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $C8C3        ; EXP
  dw $D8D8        ; Gold
  db $C8          ; Drop Item
  db $C8          ; Drop Rate
  db $D8          ; Graphics ID
  db $D8          ; Palette
  dw $C3C8        ; AI Script

; Enemy_030 (ID $1E)
enemy_030:
  dw $0138        ; HP
  db $10          ; Attack
  db $11          ; Defense
  db $33          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $58          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4D5D        ; EXP
  dw $1110        ; Gold
  db $4C          ; Drop Item
  db $4B          ; Drop Rate
  db $5C          ; Graphics ID
  db $5B          ; Palette
  dw $FBFB        ; AI Script

; Enemy_031 (ID $1F)
enemy_031:
  dw $C5C4        ; HP
  db $D4          ; Attack
  db $D5          ; Defense
  db $C6          ; Magic
  db $C7          ; Magic Defense
  db $D6          ; Speed
  db $D7          ; Accuracy
  db $4A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2A00        ; EXP
  dw $1110        ; Gold
  db $3A          ; Drop Item
  db $2A          ; Drop Rate
  db $10          ; Graphics ID
  db $11          ; Palette
  dw $013A        ; AI Script

; Enemy_032 (ID $20)
enemy_032:
  dw $4F4E        ; HP
  db $5E          ; Attack
  db $5F          ; Defense
  db $02          ; Magic
  db $4F          ; Magic Defense
  db $02          ; Speed
  db $5F          ; Accuracy
  db $02          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2F0F        ; EXP
  dw $3F1F        ; Gold
  db $6F          ; Drop Item
  db $7F          ; Drop Rate
  db $72          ; Graphics ID
  db $73          ; Palette
  dw $6564        ; AI Script

; Enemy_033 (ID $21)
enemy_033:
  dw $6362        ; HP
  db $63          ; Attack
  db $62          ; Defense
  db $6C          ; Magic
  db $67          ; Magic Defense
  db $7C          ; Speed
  db $77          ; Accuracy
  db $66          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6C67        ; EXP
  dw $7C77        ; Gold
  db $6D          ; Drop Item
  db $69          ; Drop Rate
  db $7D          ; Graphics ID
  db $79          ; Palette
  dw $6868        ; AI Script

; Enemy_034 (ID $22)
enemy_034:
  dw $F1E0        ; HP
  db $F0          ; Attack
  db $E2          ; Defense
  db $E0          ; Magic
  db $E0          ; Magic Defense
  db $F0          ; Speed
  db $F0          ; Accuracy
  db $F1          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $F0F0        ; EXP
  dw $F0F0        ; Gold
  db $F0          ; Drop Item
  db $F0          ; Drop Rate
  db $F2          ; Graphics ID
  db $F2          ; Palette
  dw $E1F0        ; AI Script

; Enemy_035 (ID $23)
enemy_035:
  dw $E0F1        ; HP
  db $F3          ; Attack
  db $F2          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $F0          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0100        ; EXP
  dw $1110        ; Gold
  db $E1          ; Drop Item
  db $F0          ; Drop Rate
  db $F3          ; Graphics ID
  db $F2          ; Palette
  dw $F1F1        ; AI Script

; Enemy_036 (ID $24)
enemy_036:
  dw $393A        ; HP
  db $10          ; Attack
  db $38          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $37          ; Speed
  db $FB          ; Accuracy
  db $80          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $F0F0        ; EXP
  dw $F0F0        ; Gold
  db $4E          ; Drop Item
  db $4F          ; Drop Rate
  db $5E          ; Graphics ID
  db $5F          ; Palette
  dw $2F0F        ; AI Script

; Enemy_037 (ID $25)
enemy_037:
  dw $8081        ; HP
  db $91          ; Attack
  db $90          ; Defense
  db $6A          ; Magic
  db $6A          ; Magic Defense
  db $7A          ; Speed
  db $7A          ; Accuracy
  db $6A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $A1A0        ; EXP
  dw $B1B0        ; Gold
  db $A2          ; Drop Item
  db $A3          ; Drop Rate
  db $B2          ; Graphics ID
  db $B3          ; Palette
  dw $0100        ; AI Script

; Enemy_038 (ID $26)
enemy_038:
  dw $E14E        ; HP
  db $5E          ; Attack
  db $5F          ; Defense
  db $E1          ; Magic
  db $4F          ; Magic Defense
  db $5E          ; Speed
  db $5F          ; Accuracy
  db $37          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $00          ; Drop Item
  db $01          ; Drop Rate
  db $10          ; Graphics ID
  db $11          ; Palette
  dw $0102        ; AI Script

; Enemy_039 (ID $27)
enemy_039:
  dw $2120        ; HP
  db $30          ; Attack
  db $31          ; Defense
  db $00          ; Magic
  db $01          ; Magic Defense
  db $10          ; Speed
  db $11          ; Accuracy
  db $CA          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $D9C9        ; EXP
  dw $D9C9        ; Gold
  db $84          ; Drop Item
  db $85          ; Drop Rate
  db $94          ; Graphics ID
  db $95          ; Palette
  dw $8584        ; AI Script

; Enemy_040 (ID $28)
enemy_040:
  dw $C7C6        ; HP
  db $D6          ; Attack
  db $D7          ; Defense
  db $C6          ; Magic
  db $C7          ; Magic Defense
  db $D6          ; Speed
  db $C7          ; Accuracy
  db $D6          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $8180        ; EXP
  dw $9190        ; Gold
  db $82          ; Drop Item
  db $83          ; Drop Rate
  db $92          ; Graphics ID
  db $93          ; Palette
  dw $F4E4        ; AI Script

; Enemy_041 (ID $29)
enemy_041:
  dw $0100        ; HP
  db $05          ; Attack
  db $15          ; Defense
  db $23          ; Magic
  db $88          ; Magic Defense
  db $32          ; Speed
  db $FB          ; Accuracy
  db $89          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FB22        ; EXP
  dw $FB32        ; Gold
  db $22          ; Drop Item
  db $FB          ; Drop Rate
  db $33          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_042 (ID $2A)
enemy_042:
  dw $BBBA        ; HP
  db $B6          ; Attack
  db $B7          ; Defense
  db $BA          ; Magic
  db $8F          ; Magic Defense
  db $B6          ; Speed
  db $8E          ; Accuracy
  db $9E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $A79D        ; EXP
  dw $B7B6        ; Gold
  db $9E          ; Drop Item
  db $BC          ; Drop Rate
  db $8E          ; Graphics ID
  db $B7          ; Palette
  dw $A7BD        ; AI Script

; Enemy_043 (ID $2B)
enemy_043:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $CF          ; Magic
  db $DF          ; Magic Defense
  db $DF          ; Speed
  db $CF          ; Accuracy
  db $C9          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $D9CB        ; EXP
  dw $D9CB        ; Gold
  db $DB          ; Drop Item
  db $DB          ; Drop Rate
  db $10          ; Graphics ID
  db $11          ; Palette
  dw $F1E0        ; AI Script

; Enemy_044 (ID $2C)
enemy_044:
  dw $E1F0        ; HP
  db $F2          ; Attack
  db $F3          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $F0E1        ; EXP
  dw $F2F3        ; Gold
  db $8F          ; Drop Item
  db $BB          ; Drop Rate
  db $8E          ; Graphics ID
  db $B7          ; Palette
  dw $A79E        ; AI Script

; Enemy_045 (ID $2D)
enemy_045:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $2B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0100        ; EXP
  dw $1110        ; Gold
  db $A6          ; Drop Item
  db $BC          ; Drop Rate
  db $B6          ; Graphics ID
  db $B7          ; Palette
  dw $BBBA        ; AI Script

; Enemy_046 (ID $2E)
enemy_046:
  dw $9392        ; HP
  db $F5          ; Attack
  db $FB          ; Defense
  db $92          ; Magic
  db $93          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $23          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FB33        ; EXP
  dw $FBFB        ; Gold
  db $C9          ; Drop Item
  db $CB          ; Drop Rate
  db $C9          ; Graphics ID
  db $CB          ; Palette
  dw $D9CB        ; AI Script

; Enemy_047 (ID $2F)
enemy_047:
  dw $A5A4        ; HP
  db $B0          ; Attack
  db $B1          ; Defense
  db $B4          ; Magic
  db $B5          ; Magic Defense
  db $B2          ; Speed
  db $B3          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_048 (ID $30)
enemy_048:
  dw $F1E0        ; HP
  db $F2          ; Attack
  db $F3          ; Defense
  db $F1          ; Magic
  db $E0          ; Magic Defense
  db $F3          ; Speed
  db $F2          ; Accuracy
  db $F0          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $E0E0        ; EXP
  dw $F0F0        ; Gold
  db $36          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $8584        ; AI Script

; Enemy_049 (ID $31)
enemy_049:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_050 (ID $32)
enemy_050:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_051 (ID $33)
enemy_051:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $24          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0100        ; EXP
  dw $0B10        ; Gold
  db $0F          ; Drop Item
  db $0F          ; Drop Rate
  db $42          ; Graphics ID
  db $43          ; Palette
  dw $0001        ; AI Script

; Enemy_052 (ID $34)
enemy_052:
  dw $A5A4        ; HP
  db $B0          ; Attack
  db $B1          ; Defense
  db $B4          ; Magic
  db $B5          ; Magic Defense
  db $B2          ; Speed
  db $B3          ; Accuracy
  db $A4          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $B5B4        ; EXP
  dw $B3B2        ; Gold
  db $EE          ; Drop Item
  db $EE          ; Drop Rate
  db $EF          ; Graphics ID
  db $EF          ; Palette
  dw $ECEC        ; AI Script

; Enemy_053 (ID $35)
enemy_053:
  dw $2120        ; HP
  db $30          ; Attack
  db $31          ; Defense
  db $20          ; Magic
  db $0E          ; Magic Defense
  db $30          ; Speed
  db $31          ; Accuracy
  db $0A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2122        ; EXP
  dw $3132        ; Gold
  db $22          ; Drop Item
  db $21          ; Drop Rate
  db $23          ; Graphics ID
  db $31          ; Palette
  dw $FBFB        ; AI Script

; Enemy_054 (ID $36)
enemy_054:
  dw $EAEA        ; HP
  db $FA          ; Attack
  db $FA          ; Defense
  db $EB          ; Magic
  db $EB          ; Magic Defense
  db $E6          ; Speed
  db $E7          ; Accuracy
  db $F6          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $F9F8        ; EXP
  dw $B7B6        ; Gold
  db $08          ; Drop Item
  db $09          ; Drop Rate
  db $18          ; Graphics ID
  db $19          ; Palette
  dw $1F0F        ; AI Script

; Enemy_055 (ID $37)
enemy_055:
  dw $2F24        ; HP
  db $3E          ; Attack
  db $3F          ; Defense
  db $41          ; Magic
  db $41          ; Magic Defense
  db $51          ; Speed
  db $51          ; Accuracy
  db $CE          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBAA        ; EXP
  dw $B7B8        ; Gold
  db $BA          ; Drop Item
  db $BB          ; Drop Rate
  db $B6          ; Graphics ID
  db $B7          ; Palette
  dw $AFAE        ; AI Script

; Enemy_056 (ID $38)
enemy_056:
  dw $093B        ; HP
  db $18          ; Attack
  db $19          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $CC          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $0A          ; Drop Item
  db $3B          ; Drop Rate
  db $1A          ; Graphics ID
  db $18          ; Palette
  dw $2529        ; AI Script

; Enemy_057 (ID $39)
enemy_057:
  dw $4544        ; HP
  db $54          ; Attack
  db $55          ; Defense
  db $4C          ; Magic
  db $4D          ; Magic Defense
  db $5C          ; Speed
  db $5D          ; Accuracy
  db $5A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6160        ; EXP
  dw $7170        ; Gold
  db $62          ; Drop Item
  db $63          ; Drop Rate
  db $72          ; Graphics ID
  db $73          ; Palette
  dw $6564        ; AI Script

; Enemy_058 (ID $3A)
enemy_058:
  dw $061C        ; HP
  db $17          ; Attack
  db $16          ; Defense
  db $11          ; Magic
  db $12          ; Magic Defense
  db $10          ; Speed
  db $0B          ; Accuracy
  db $20          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5B5A        ; EXP
  dw $5756        ; Gold
  db $58          ; Drop Item
  db $59          ; Drop Rate
  db $4A          ; Graphics ID
  db $4B          ; Palette
  dw $5958        ; AI Script

; Enemy_059 (ID $3B)
enemy_059:
  dw $6968        ; HP
  db $78          ; Attack
  db $79          ; Defense
  db $6A          ; Magic
  db $6B          ; Magic Defense
  db $7A          ; Speed
  db $7B          ; Accuracy
  db $0F          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2152        ; EXP
  dw $2E2D        ; Gold
  db $52          ; Drop Item
  db $53          ; Drop Rate
  db $2E          ; Graphics ID
  db $2D          ; Palette
  dw $B5B4        ; AI Script

; Enemy_060 (ID $3C)
enemy_060:
  dw $8E98        ; HP
  db $8E          ; Attack
  db $9B          ; Defense
  db $FB          ; Magic
  db $8C          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $0F          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6D6C        ; EXP
  dw $8D7C        ; Gold
  db $6E          ; Drop Item
  db $6F          ; Drop Rate
  db $7E          ; Graphics ID
  db $7F          ; Palette
  dw $FBFB        ; AI Script

; Enemy_061 (ID $3D)
enemy_061:
  dw $2120        ; HP
  db $30          ; Attack
  db $31          ; Defense
  db $04          ; Magic
  db $05          ; Magic Defense
  db $0C          ; Speed
  db $10          ; Accuracy
  db $27          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2120        ; EXP
  dw $3130        ; Gold
  db $1D          ; Drop Item
  db $1B          ; Drop Rate
  db $16          ; Graphics ID
  db $17          ; Palette
  dw $8F8E        ; AI Script

; Enemy_062 (ID $3E)
enemy_062:
  dw $9F9E        ; HP
  db $82          ; Attack
  db $83          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2120        ; EXP
  dw $2D2D        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $30          ; Graphics ID
  db $31          ; Palette
  dw $080A        ; AI Script

; Enemy_063 (ID $3F)
enemy_063:
  dw $1607        ; HP
  db $34          ; Attack
  db $35          ; Defense
  db $20          ; Magic
  db $21          ; Magic Defense
  db $1D          ; Speed
  db $1B          ; Accuracy
  db $20          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2E2D        ; EXP
  dw $3534        ; Gold
  db $2E          ; Drop Item
  db $2D          ; Drop Rate
  db $34          ; Graphics ID
  db $35          ; Palette
  dw $9190        ; AI Script

; Enemy_064 (ID $40)
enemy_064:
  dw $1808        ; HP
  db $18          ; Attack
  db $08          ; Defense
  db $0A          ; Magic
  db $0A          ; Magic Defense
  db $1A          ; Speed
  db $1A          ; Accuracy
  db $0A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4544        ; EXP
  dw $5554        ; Gold
  db $02          ; Drop Item
  db $03          ; Drop Rate
  db $04          ; Graphics ID
  db $05          ; Palette
  dw $0306        ; AI Script

; Enemy_065 (ID $41)
enemy_065:
  dw $9B1B        ; HP
  db $1B          ; Attack
  db $9B          ; Defense
  db $02          ; Magic
  db $03          ; Magic Defense
  db $04          ; Speed
  db $05          ; Accuracy
  db $9B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4242        ; EXP
  dw $4242        ; Gold
  db $43          ; Drop Item
  db $43          ; Drop Rate
  db $53          ; Graphics ID
  db $53          ; Palette
  dw $0A0A        ; AI Script

; Enemy_066 (ID $42)
enemy_066:
  dw $2625        ; HP
  db $35          ; Attack
  db $36          ; Defense
  db $27          ; Magic
  db $28          ; Magic Defense
  db $37          ; Speed
  db $38          ; Accuracy
  db $2D          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1312        ; EXP
  dw $1514        ; Gold
  db $2D          ; Drop Item
  db $2D          ; Drop Rate
  db $3D          ; Graphics ID
  db $3D          ; Palette
  dw $2728        ; AI Script

; Enemy_067 (ID $43)
enemy_067:
  dw $9B9B        ; HP
  db $0D          ; Attack
  db $0D          ; Defense
  db $00          ; Magic
  db $01          ; Magic Defense
  db $10          ; Speed
  db $11          ; Accuracy
  db $9B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0F0F        ; EXP
  dw $1F1F        ; Gold
  db $17          ; Drop Item
  db $9B          ; Drop Rate
  db $9B          ; Graphics ID
  db $9B          ; Palette
  dw $2323        ; AI Script

; Enemy_068 (ID $44)
enemy_068:
  dw $2F2F        ; HP
  db $3F          ; Attack
  db $3F          ; Defense
  db $2C          ; Magic
  db $2B          ; Magic Defense
  db $3C          ; Speed
  db $3B          ; Accuracy
  db $2A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0909        ; EXP
  dw $1919        ; Gold
  db $08          ; Drop Item
  db $18          ; Drop Rate
  db $18          ; Graphics ID
  db $08          ; Palette
  dw $4240        ; AI Script

; Enemy_069 (ID $45)
enemy_069:
  dw $9B9B        ; HP
  db $9B          ; Attack
  db $9B          ; Defense
  db $9B          ; Magic
  db $9B          ; Magic Defense
  db $9B          ; Speed
  db $9B          ; Accuracy
  db $02          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4343        ; EXP
  dw $5353        ; Gold
  db $02          ; Drop Item
  db $03          ; Drop Rate
  db $04          ; Graphics ID
  db $05          ; Palette
  dw $0306        ; AI Script

; Enemy_070 (ID $46)
enemy_070:
  dw $9B9B        ; HP
  db $9B          ; Attack
  db $9B          ; Defense
  db $9B          ; Magic
  db $9B          ; Magic Defense
  db $9B          ; Speed
  db $9B          ; Accuracy
  db $1D          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4343        ; EXP
  dw $5353        ; Gold
  db $00          ; Drop Item
  db $01          ; Drop Rate
  db $10          ; Graphics ID
  db $0B          ; Palette
  dw $0F0F        ; AI Script

; Enemy_071 (ID $47)
enemy_071:
  dw $0F1F        ; HP
  db $42          ; Attack
  db $53          ; Defense
  db $40          ; Magic
  db $41          ; Magic Defense
  db $50          ; Speed
  db $51          ; Accuracy
  db $41          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1D1D        ; EXP
  dw $9B9B        ; Gold
  db $9B          ; Drop Item
  db $9B          ; Drop Rate
  db $9B          ; Graphics ID
  db $9B          ; Palette
  dw $9B9B        ; AI Script

; Enemy_072 (ID $48)
enemy_072:
  dw $0908        ; HP
  db $18          ; Attack
  db $19          ; Defense
  db $20          ; Magic
  db $21          ; Magic Defense
  db $30          ; Speed
  db $31          ; Accuracy
  db $0A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0908        ; EXP
  dw $192A        ; Gold
  db $0A          ; Drop Item
  db $08          ; Drop Rate
  db $1A          ; Graphics ID
  db $2A          ; Palette
  dw $2120        ; AI Script

; Enemy_073 (ID $49)
enemy_073:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $9B          ; Magic
  db $9B          ; Magic Defense
  db $9B          ; Speed
  db $9B          ; Accuracy
  db $9B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9B9B        ; EXP
  dw $9B9B        ; Gold
  db $9B          ; Drop Item
  db $9B          ; Drop Rate
  db $9B          ; Graphics ID
  db $9B          ; Palette
  dw $9B9B        ; AI Script

; Enemy_074 (ID $4A)
enemy_074:
  dw $5352        ; HP
  db $2E          ; Attack
  db $2D          ; Defense
  db $20          ; Magic
  db $0E          ; Magic Defense
  db $30          ; Speed
  db $31          ; Accuracy
  db $0D          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1BA2        ; EXP
  dw $17B2        ; Gold
  db $1C          ; Drop Item
  db $A2          ; Drop Rate
  db $17          ; Graphics ID
  db $B2          ; Palette
  dw $0302        ; AI Script

; Enemy_075 (ID $4B)
enemy_075:
  dw $9B9B        ; HP
  db $9B          ; Attack
  db $9B          ; Defense
  db $9B          ; Magic
  db $9B          ; Magic Defense
  db $9B          ; Speed
  db $9B          ; Accuracy
  db $24          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2524        ; EXP
  dw $3633        ; Gold
  db $26          ; Drop Item
  db $27          ; Drop Rate
  db $FB          ; Graphics ID
  db $37          ; Palette
  dw $2627        ; AI Script

; Enemy_076 (ID $4C)
enemy_076:
  dw $27A3        ; HP
  db $DE          ; Attack
  db $B3          ; Defense
  db $27          ; Magic
  db $A3          ; Magic Defense
  db $B3          ; Speed
  db $DF          ; Accuracy
  db $9B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9B9B        ; EXP
  dw $9B9B        ; Gold
  db $9B          ; Drop Item
  db $9B          ; Drop Rate
  db $9B          ; Graphics ID
  db $9B          ; Palette
  dw $9B9B        ; AI Script

; Enemy_077 (ID $4D)
enemy_077:
  dw $3F3E        ; HP
  db $58          ; Attack
  db $59          ; Defense
  db $4C          ; Magic
  db $4C          ; Magic Defense
  db $5C          ; Speed
  db $5D          ; Accuracy
  db $4C          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2928        ; EXP
  dw $3938        ; Gold
  db $2A          ; Drop Item
  db $29          ; Drop Rate
  db $3A          ; Graphics ID
  db $39          ; Palette
  dw $292A        ; AI Script

; Enemy_078 (ID $4E)
enemy_078:
  dw $BBBB        ; HP
  db $BB          ; Attack
  db $BB          ; Defense
  db $2C          ; Magic
  db $2D          ; Magic Defense
  db $3C          ; Speed
  db $3D          ; Accuracy
  db $2B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4D4D        ; EXP
  dw $5F5F        ; Gold
  db $28          ; Drop Item
  db $29          ; Drop Rate
  db $38          ; Graphics ID
  db $39          ; Palette
  dw $4746        ; AI Script

; Enemy_079 (ID $4F)
enemy_079:
  dw $2B2B        ; HP
  db $2B          ; Attack
  db $2B          ; Defense
  db $28          ; Magic
  db $29          ; Magic Defense
  db $38          ; Speed
  db $39          ; Accuracy
  db $BB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBBB        ; EXP
  dw $BBBB        ; Gold
  db $46          ; Drop Item
  db $47          ; Drop Rate
  db $56          ; Graphics ID
  db $57          ; Palette
  dw $2E2E        ; AI Script

; Enemy_080 (ID $50)
enemy_080:
  dw $6160        ; HP
  db $BB          ; Attack
  db $BB          ; Defense
  db $44          ; Magic
  db $45          ; Magic Defense
  db $54          ; Speed
  db $55          ; Accuracy
  db $4A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2928        ; EXP
  dw $3938        ; Gold
  db $62          ; Drop Item
  db $63          ; Drop Rate
  db $72          ; Graphics ID
  db $73          ; Palette
  dw $2928        ; AI Script

; Enemy_081 (ID $51)
enemy_081:
  dw $1212        ; HP
  db $12          ; Attack
  db $12          ; Defense
  db $4D          ; Magic
  db $4D          ; Magic Defense
  db $5F          ; Speed
  db $5F          ; Accuracy
  db $03          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0112        ; EXP
  dw $1112        ; Gold
  db $00          ; Drop Item
  db $02          ; Drop Rate
  db $10          ; Graphics ID
  db $02          ; Palette
  dw $2726        ; AI Script

; Enemy_082 (ID $52)
enemy_082:
  dw $BB64        ; HP
  db $74          ; Attack
  db $BB          ; Defense
  db $64          ; Magic
  db $BB          ; Magic Defense
  db $71          ; Speed
  db $BB          ; Accuracy
  db $69          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6F6E        ; EXP
  dw $7F7E        ; Gold
  db $6E          ; Drop Item
  db $6F          ; Drop Rate
  db $7B          ; Graphics ID
  db $7C          ; Palette
  dw $6362        ; AI Script

; Enemy_083 (ID $53)
enemy_083:
  dw $0012        ; HP
  db $12          ; Attack
  db $10          ; Defense
  db $56          ; Magic
  db $57          ; Magic Defense
  db $3A          ; Speed
  db $39          ; Accuracy
  db $6B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6C6B        ; EXP
  dw $6C6B        ; Gold
  db $03          ; Drop Item
  db $03          ; Drop Rate
  db $13          ; Graphics ID
  db $13          ; Palette
  dw $6665        ; AI Script

; Enemy_084 (ID $54)
enemy_084:
  dw $6362        ; HP
  db $72          ; Attack
  db $73          ; Defense
  db $64          ; Magic
  db $63          ; Magic Defense
  db $74          ; Speed
  db $73          ; Accuracy
  db $64          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6A69        ; EXP
  dw $7A79        ; Gold
  db $62          ; Drop Item
  db $63          ; Drop Rate
  db $72          ; Graphics ID
  db $73          ; Palette
  dw $1212        ; AI Script

; Enemy_085 (ID $55)
enemy_085:
  dw $6F6E        ; HP
  db $7E          ; Attack
  db $7F          ; Defense
  db $BB          ; Magic
  db $BB          ; Magic Defense
  db $BB          ; Speed
  db $BB          ; Accuracy
  db $6E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBBB        ; EXP
  dw $BBBB        ; Gold
  db $6E          ; Drop Item
  db $6F          ; Drop Rate
  db $7E          ; Graphics ID
  db $7F          ; Palette
  dw $BBBB        ; AI Script

; Enemy_086 (ID $56)
enemy_086:
  dw $0201        ; HP
  db $11          ; Attack
  db $02          ; Defense
  db $6E          ; Magic
  db $6F          ; Magic Defense
  db $7B          ; Speed
  db $7C          ; Accuracy
  db $44          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5756        ; EXP
  dw $0200        ; Gold
  db $62          ; Drop Item
  db $63          ; Drop Rate
  db $72          ; Graphics ID
  db $73          ; Palette
  dw $2928        ; AI Script

; Enemy_087 (ID $57)
enemy_087:
  dw $292A        ; HP
  db $3A          ; Attack
  db $39          ; Defense
  db $26          ; Magic
  db $27          ; Magic Defense
  db $36          ; Speed
  db $37          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0200        ; EXP
  dw $0210        ; Gold
  db $BB          ; Drop Item
  db $BB          ; Drop Rate
  db $BB          ; Graphics ID
  db $BB          ; Palette
  dw $BBBB        ; AI Script

; Enemy_088 (ID $58)
enemy_088:
  dw $BBBB        ; HP
  db $BB          ; Attack
  db $BB          ; Defense
  db $BB          ; Magic
  db $BB          ; Magic Defense
  db $BB          ; Speed
  db $BB          ; Accuracy
  db $BB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBBB        ; EXP
  dw $BBBB        ; Gold
  db $BB          ; Drop Item
  db $BB          ; Drop Rate
  db $BB          ; Graphics ID
  db $BB          ; Palette
  dw $BBBB        ; AI Script

; Enemy_089 (ID $59)
enemy_089:
  dw $BBBB        ; HP
  db $BB          ; Attack
  db $BB          ; Defense
  db $BB          ; Magic
  db $BB          ; Magic Defense
  db $BB          ; Speed
  db $BB          ; Accuracy
  db $BB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $BBBB        ; EXP
  dw $BBBB        ; Gold
  db $BB          ; Drop Item
  db $BB          ; Drop Rate
  db $BB          ; Graphics ID
  db $BB          ; Palette
  dw $BBBB        ; AI Script

; Enemy_090 (ID $5A)
enemy_090:
  dw $F1E0        ; HP
  db $F0          ; Attack
  db $E2          ; Defense
  db $F1          ; Magic
  db $F1          ; Magic Defense
  db $F3          ; Speed
  db $F3          ; Accuracy
  db $F1          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $F0F0        ; EXP
  dw $F0F0        ; Gold
  db $4E          ; Drop Item
  db $4F          ; Drop Rate
  db $5E          ; Graphics ID
  db $5F          ; Palette
  dw $F1E0        ; AI Script

; Enemy_091 (ID $5B)
enemy_091:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $12          ; Magic
  db $13          ; Magic Defense
  db $14          ; Speed
  db $15          ; Accuracy
  db $20          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2132        ; EXP
  dw $3132        ; Gold
  db $23          ; Drop Item
  db $23          ; Drop Rate
  db $33          ; Graphics ID
  db $33          ; Palette
  dw $8B8A        ; AI Script

; Enemy_092 (ID $5C)
enemy_092:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $E1          ; Magic
  db $F0          ; Magic Defense
  db $F3          ; Speed
  db $F2          ; Accuracy
  db $C7          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4FC7        ; EXP
  dw $5FC8        ; Gold
  db $C2          ; Drop Item
  db $C1          ; Drop Rate
  db $5E          ; Graphics ID
  db $5F          ; Palette
  dw $4FD1        ; AI Script

; Enemy_093 (ID $5D)
enemy_093:
  dw $2524        ; HP
  db $34          ; Attack
  db $35          ; Defense
  db $23          ; Magic
  db $23          ; Magic Defense
  db $33          ; Speed
  db $33          ; Accuracy
  db $C7          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4FC7        ; EXP
  dw $5FC8        ; Gold
  db $4E          ; Drop Item
  db $4F          ; Drop Rate
  db $5E          ; Graphics ID
  db $5F          ; Palette
  dw $6160        ; AI Script

; Enemy_094 (ID $5E)
enemy_094:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $06          ; Magic
  db $FB          ; Magic Defense
  db $06          ; Speed
  db $FB          ; Accuracy
  db $06          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0302        ; EXP
  dw $0504        ; Gold
  db $D6          ; Drop Item
  db $C1          ; Drop Rate
  db $D0          ; Graphics ID
  db $5F          ; Palette
  dw $C1C2        ; AI Script

; Enemy_095 (ID $5F)
enemy_095:
  dw $0202        ; HP
  db $02          ; Attack
  db $02          ; Defense
  db $A0          ; Magic
  db $A1          ; Magic Defense
  db $B0          ; Speed
  db $B1          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $6F          ; Drop Item
  db $7F          ; Drop Rate
  db $72          ; Graphics ID
  db $73          ; Palette
  dw $6564        ; AI Script

; Enemy_096 (ID $60)
enemy_096:
  dw $4FD1        ; HP
  db $D0          ; Attack
  db $5F          ; Defense
  db $A0          ; Magic
  db $A1          ; Magic Defense
  db $B0          ; Speed
  db $B1          ; Accuracy
  db $4E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0303        ; EXP
  dw $1313        ; Gold
  db $01          ; Drop Item
  db $02          ; Drop Rate
  db $11          ; Graphics ID
  db $02          ; Palette
  dw $0012        ; AI Script

; Enemy_097 (ID $61)
enemy_097:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $F1E1        ; AI Script

; Enemy_098 (ID $62)
enemy_098:
  dw $4F4E        ; HP
  db $5E          ; Attack
  db $5F          ; Defense
  db $4E          ; Magic
  db $4F          ; Magic Defense
  db $5E          ; Speed
  db $5F          ; Accuracy
  db $60          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6362        ; EXP
  dw $6263        ; Gold
  db $82          ; Drop Item
  db $83          ; Drop Rate
  db $63          ; Graphics ID
  db $62          ; Palette
  dw $4F4E        ; AI Script

; Enemy_099 (ID $63)
enemy_099:
  dw $4F4E        ; HP
  db $5E          ; Attack
  db $5F          ; Defense
  db $4E          ; Magic
  db $4F          ; Magic Defense
  db $5E          ; Speed
  db $5F          ; Accuracy
  db $4E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4F4E        ; EXP
  dw $5F5E        ; Gold
  db $12          ; Drop Item
  db $01          ; Drop Rate
  db $12          ; Graphics ID
  db $11          ; Palette
  dw $7F6F        ; AI Script

; Enemy_100 (ID $64)
enemy_100:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_101 (ID $65)
enemy_101:
  dw $0201        ; HP
  db $11          ; Attack
  db $02          ; Defense
  db $64          ; Magic
  db $65          ; Magic Defense
  db $74          ; Speed
  db $75          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_102 (ID $66)
enemy_102:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $4647        ; AI Script

; Enemy_103 (ID $67)
enemy_103:
  dw $A1B2        ; HP
  db $B2          ; Attack
  db $B1          ; Defense
  db $A0          ; Magic
  db $A2          ; Magic Defense
  db $B0          ; Speed
  db $A2          ; Accuracy
  db $45          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4647        ; EXP
  dw $3130        ; Gold
  db $47          ; Drop Item
  db $48          ; Drop Rate
  db $30          ; Graphics ID
  db $58          ; Palette
  dw $5722        ; AI Script

; Enemy_104 (ID $68)
enemy_104:
  dw $2156        ; HP
  db $55          ; Attack
  db $31          ; Defense
  db $20          ; Magic
  db $21          ; Magic Defense
  db $30          ; Speed
  db $31          ; Accuracy
  db $20          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5722        ; EXP
  dw $5833        ; Gold
  db $22          ; Drop Item
  db $21          ; Drop Rate
  db $33          ; Graphics ID
  db $31          ; Palette
  dw $4A4A        ; AI Script

; Enemy_105 (ID $69)
enemy_105:
  dw $5720        ; HP
  db $30          ; Attack
  db $58          ; Defense
  db $22          ; Magic
  db $57          ; Magic Defense
  db $33          ; Speed
  db $58          ; Accuracy
  db $22          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4E4D        ; EXP
  dw $5E5D        ; Gold
  db $4E          ; Drop Item
  db $4D          ; Drop Rate
  db $5E          ; Graphics ID
  db $5D          ; Palette
  dw $4C4B        ; AI Script

; Enemy_106 (ID $6A)
enemy_106:
  dw $6261        ; HP
  db $71          ; Attack
  db $72          ; Defense
  db $A2          ; Magic
  db $A2          ; Magic Defense
  db $A2          ; Speed
  db $A2          ; Accuracy
  db $44          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $8382        ; EXP
  dw $9392        ; Gold
  db $D0          ; Drop Item
  db $D0          ; Drop Rate
  db $14          ; Graphics ID
  db $15          ; Palette
  dw $A2B2        ; AI Script

; Enemy_107 (ID $6B)
enemy_107:
  dw $A3A3        ; HP
  db $B3          ; Attack
  db $B3          ; Defense
  db $D0          ; Magic
  db $D0          ; Magic Defense
  db $14          ; Speed
  db $15          ; Accuracy
  db $40          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4140        ; EXP
  dw $5150        ; Gold
  db $6E          ; Drop Item
  db $6F          ; Drop Rate
  db $7E          ; Graphics ID
  db $7F          ; Palette
  dw $7363        ; AI Script

; Enemy_108 (ID $6C)
enemy_108:
  dw $4C4B        ; HP
  db $5B          ; Attack
  db $5C          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $40          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5756        ; EXP
  dw $5855        ; Gold
  db $40          ; Drop Item
  db $41          ; Drop Rate
  db $50          ; Graphics ID
  db $51          ; Palette
  dw $4645        ; AI Script

; Enemy_109 (ID $6D)
enemy_109:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $40          ; Magic
  db $41          ; Magic Defense
  db $50          ; Speed
  db $51          ; Accuracy
  db $56          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $22          ; Drop Item
  db $46          ; Drop Rate
  db $32          ; Graphics ID
  db $31          ; Palette
  dw $2122        ; AI Script

; Enemy_110 (ID $6E)
enemy_110:
  dw $2122        ; HP
  db $32          ; Attack
  db $31          ; Defense
  db $56          ; Magic
  db $21          ; Magic Defense
  db $55          ; Speed
  db $31          ; Accuracy
  db $20          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5720        ; EXP
  dw $5830        ; Gold
  db $45          ; Drop Item
  db $46          ; Drop Rate
  db $55          ; Graphics ID
  db $31          ; Palette
  dw $4647        ; AI Script

; Enemy_111 (ID $6F)
enemy_111:
  dw $2122        ; HP
  db $32          ; Attack
  db $31          ; Defense
  db $22          ; Magic
  db $21          ; Magic Defense
  db $33          ; Speed
  db $31          ; Accuracy
  db $40          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5720        ; EXP
  dw $5830        ; Gold
  db $47          ; Drop Item
  db $46          ; Drop Rate
  db $30          ; Graphics ID
  db $31          ; Palette
  dw $4645        ; AI Script

; Enemy_112 (ID $70)
enemy_112:
  dw $D0D0        ; HP
  db $14          ; Attack
  db $15          ; Defense
  db $20          ; Magic
  db $21          ; Magic Defense
  db $30          ; Speed
  db $31          ; Accuracy
  db $22          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5722        ; EXP
  dw $5833        ; Gold
  db $40          ; Drop Item
  db $41          ; Drop Rate
  db $50          ; Graphics ID
  db $51          ; Palette
  dw $5756        ; AI Script

; Enemy_113 (ID $71)
enemy_113:
  dw $4622        ; HP
  db $32          ; Attack
  db $31          ; Defense
  db $49          ; Magic
  db $49          ; Magic Defense
  db $59          ; Speed
  db $59          ; Accuracy
  db $B2          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0504        ; EXP
  dw $1514        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $30          ; Graphics ID
  db $31          ; Palette
  dw $2156        ; AI Script

; Enemy_114 (ID $72)
enemy_114:
  dw $6261        ; HP
  db $71          ; Attack
  db $72          ; Defense
  db $62          ; Magic
  db $61          ; Magic Defense
  db $72          ; Speed
  db $71          ; Accuracy
  db $61          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2120        ; EXP
  dw $3130        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $30          ; Graphics ID
  db $31          ; Palette
  dw $2120        ; AI Script

; Enemy_115 (ID $73)
enemy_115:
  dw $D0D0        ; HP
  db $14          ; Attack
  db $15          ; Defense
  db $42          ; Magic
  db $43          ; Magic Defense
  db $52          ; Speed
  db $53          ; Accuracy
  db $60          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6161        ; EXP
  dw $7070        ; Gold
  db $61          ; Drop Item
  db $61          ; Drop Rate
  db $70          ; Graphics ID
  db $70          ; Palette
  dw $6161        ; AI Script

; Enemy_116 (ID $74)
enemy_116:
  dw $2524        ; HP
  db $34          ; Attack
  db $35          ; Defense
  db $22          ; Magic
  db $23          ; Magic Defense
  db $32          ; Speed
  db $33          ; Accuracy
  db $61          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1615        ; EXP
  dw $1817        ; Gold
  db $0D          ; Drop Item
  db $0E          ; Drop Rate
  db $0C          ; Graphics ID
  db $14          ; Palette
  dw $0E0E        ; AI Script

; Enemy_117 (ID $75)
enemy_117:
  dw $041E        ; HP
  db $1E          ; Attack
  db $14          ; Defense
  db $19          ; Magic
  db $19          ; Magic Defense
  db $70          ; Speed
  db $70          ; Accuracy
  db $1A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $61          ; Drop Item
  db $61          ; Drop Rate
  db $70          ; Graphics ID
  db $70          ; Palette
  dw $4D4C        ; AI Script

; Enemy_118 (ID $76)
enemy_118:
  dw $041C        ; HP
  db $0C          ; Attack
  db $14          ; Defense
  db $1E          ; Magic
  db $04          ; Magic Defense
  db $1E          ; Speed
  db $14          ; Accuracy
  db $04          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2020        ; EXP
  dw $3030        ; Gold
  db $4C          ; Drop Item
  db $4D          ; Drop Rate
  db $5C          ; Graphics ID
  db $5D          ; Palette
  dw $6161        ; AI Script

; Enemy_119 (ID $77)
enemy_119:
  dw $041C        ; HP
  db $0C          ; Attack
  db $14          ; Defense
  db $04          ; Magic
  db $04          ; Magic Defense
  db $14          ; Speed
  db $14          ; Accuracy
  db $1E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $041E        ; EXP
  dw $141E        ; Gold
  db $61          ; Drop Item
  db $61          ; Drop Rate
  db $09          ; Graphics ID
  db $09          ; Palette
  dw $6161        ; AI Script

; Enemy_120 (ID $78)
enemy_120:
  dw $2020        ; HP
  db $30          ; Attack
  db $30          ; Defense
  db $1E          ; Magic
  db $04          ; Magic Defense
  db $1E          ; Speed
  db $14          ; Accuracy
  db $4C          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6161        ; EXP
  dw $7070        ; Gold
  db $4C          ; Drop Item
  db $4D          ; Drop Rate
  db $5C          ; Graphics ID
  db $5D          ; Palette
  dw $6161        ; AI Script

; Enemy_121 (ID $79)
enemy_121:
  dw $1919        ; HP
  db $70          ; Attack
  db $70          ; Defense
  db $1A          ; Magic
  db $1A          ; Magic Defense
  db $0B          ; Speed
  db $0B          ; Accuracy
  db $24          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2322        ; EXP
  dw $3332        ; Gold
  db $19          ; Drop Item
  db $19          ; Drop Rate
  db $70          ; Graphics ID
  db $70          ; Palette
  dw $1A1A        ; AI Script

; Enemy_122 (ID $7A)
enemy_122:
  dw $0F0D        ; HP
  db $0C          ; Attack
  db $1F          ; Defense
  db $04          ; Magic
  db $1C          ; Magic Defense
  db $14          ; Speed
  db $0C          ; Accuracy
  db $9A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $9A9A        ; AI Script

; Enemy_123 (ID $7B)
enemy_123:
  dw $9A9A        ; HP
  db $9A          ; Attack
  db $9A          ; Defense
  db $9A          ; Magic
  db $9A          ; Magic Defense
  db $9A          ; Speed
  db $9A          ; Accuracy
  db $9A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $9A9A        ; AI Script

; Enemy_124 (ID $7C)
enemy_124:
  dw $9A9A        ; HP
  db $9A          ; Attack
  db $9A          ; Defense
  db $9A          ; Magic
  db $9A          ; Magic Defense
  db $9A          ; Speed
  db $9A          ; Accuracy
  db $9A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $9A9A        ; AI Script

; Enemy_125 (ID $7D)
enemy_125:
  dw $9A9A        ; HP
  db $9A          ; Attack
  db $9A          ; Defense
  db $9A          ; Magic
  db $9A          ; Magic Defense
  db $9A          ; Speed
  db $9A          ; Accuracy
  db $9A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $9A9A        ; AI Script

; Enemy_126 (ID $7E)
enemy_126:
  dw $9A9A        ; HP
  db $9A          ; Attack
  db $9A          ; Defense
  db $9A          ; Magic
  db $9A          ; Magic Defense
  db $9A          ; Speed
  db $9A          ; Accuracy
  db $9A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $9A9A        ; AI Script

; Enemy_127 (ID $7F)
enemy_127:
  dw $9A9A        ; HP
  db $9A          ; Attack
  db $9A          ; Defense
  db $9A          ; Magic
  db $9A          ; Magic Defense
  db $9A          ; Speed
  db $9A          ; Accuracy
  db $9A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $9A9A        ; AI Script

; Enemy_128 (ID $80)
enemy_128:
  dw $9796        ; HP
  db $97          ; Attack
  db $96          ; Defense
  db $2B          ; Magic
  db $2C          ; Magic Defense
  db $2D          ; Speed
  db $2E          ; Accuracy
  db $80          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $8382        ; EXP
  dw $9392        ; Gold
  db $64          ; Drop Item
  db $65          ; Drop Rate
  db $74          ; Graphics ID
  db $75          ; Palette
  dw $6363        ; AI Script

; Enemy_129 (ID $81)
enemy_129:
  dw $A1A2        ; HP
  db $5E          ; Attack
  db $5F          ; Defense
  db $A2          ; Magic
  db $A3          ; Magic Defense
  db $5E          ; Speed
  db $B3          ; Accuracy
  db $B6          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $A1A2        ; EXP
  dw $5F5E        ; Gold
  db $A2          ; Drop Item
  db $A3          ; Drop Rate
  db $5E          ; Graphics ID
  db $B3          ; Palette
  dw $C7C7        ; AI Script

; Enemy_130 (ID $82)
enemy_130:
  dw $4FA7        ; HP
  db $A8          ; Attack
  db $5F          ; Defense
  db $82          ; Magic
  db $83          ; Magic Defense
  db $92          ; Speed
  db $93          ; Accuracy
  db $E4          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $F4E5        ; EXP
  dw $E4E3        ; Gold
  db $E5          ; Drop Item
  db $F4          ; Drop Rate
  db $F5          ; Graphics ID
  db $E4          ; Palette
  dw $4FB1        ; AI Script

; Enemy_131 (ID $83)
enemy_131:
  dw $B24E        ; HP
  db $5E          ; Attack
  db $B3          ; Defense
  db $81          ; Magic
  db $80          ; Magic Defense
  db $91          ; Speed
  db $90          ; Accuracy
  db $A7          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4FA7        ; EXP
  dw $5FA8        ; Gold
  db $4E          ; Drop Item
  db $4F          ; Drop Rate
  db $5E          ; Graphics ID
  db $5F          ; Palette
  dw $FBFB        ; AI Script

; Enemy_132 (ID $84)
enemy_132:
  dw $A1A7        ; HP
  db $A7          ; Attack
  db $5F          ; Defense
  db $A7          ; Magic
  db $4F          ; Magic Defense
  db $A7          ; Speed
  db $5F          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_133 (ID $85)
enemy_133:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_134 (ID $86)
enemy_134:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_135 (ID $87)
enemy_135:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_136 (ID $88)
enemy_136:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_137 (ID $89)
enemy_137:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_138 (ID $8A)
enemy_138:
  dw $0279        ; HP
  db $02          ; Attack
  db $00          ; Defense
  db $02          ; Magic
  db $7A          ; Magic Defense
  db $01          ; Speed
  db $02          ; Accuracy
  db $37          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $7F7F        ; EXP
  dw $7F7F        ; Gold
  db $79          ; Drop Item
  db $7A          ; Drop Rate
  db $7A          ; Graphics ID
  db $79          ; Palette
  dw $7A79        ; AI Script

; Enemy_139 (ID $8B)
enemy_139:
  dw $4A30        ; HP
  db $7A          ; Attack
  db $30          ; Defense
  db $4B          ; Magic
  db $30          ; Magic Defense
  db $30          ; Speed
  db $79          ; Accuracy
  db $31          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $7A79        ; EXP
  dw $797A        ; Gold
  db $31          ; Drop Item
  db $32          ; Drop Rate
  db $7A          ; Graphics ID
  db $79          ; Palette
  dw $3231        ; AI Script

; Enemy_140 (ID $8C)
enemy_140:
  dw $647F        ; HP
  db $64          ; Attack
  db $6B          ; Defense
  db $68          ; Magic
  db $69          ; Magic Defense
  db $6A          ; Speed
  db $6B          ; Accuracy
  db $68          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6D6C        ; EXP
  dw $7F7F        ; Gold
  db $65          ; Drop Item
  db $69          ; Drop Rate
  db $7F          ; Graphics ID
  db $65          ; Palette
  dw $7F2B        ; AI Script

; Enemy_141 (ID $8D)
enemy_141:
  dw $8382        ; HP
  db $92          ; Attack
  db $93          ; Defense
  db $16          ; Magic
  db $01          ; Magic Defense
  db $10          ; Speed
  db $5F          ; Accuracy
  db $02          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0302        ; EXP
  dw $135E        ; Gold
  db $07          ; Drop Item
  db $4F          ; Drop Rate
  db $07          ; Graphics ID
  db $5F          ; Palette
  dw $6160        ; AI Script

; Enemy_142 (ID $8E)
enemy_142:
  dw $2525        ; HP
  db $89          ; Attack
  db $88          ; Defense
  db $C4          ; Magic
  db $C5          ; Magic Defense
  db $D4          ; Speed
  db $D5          ; Accuracy
  db $C3          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4F4E        ; EXP
  dw $5F5E        ; Gold
  db $ED          ; Drop Item
  db $ED          ; Drop Rate
  db $FD          ; Graphics ID
  db $FD          ; Palette
  dw $EEEE        ; AI Script

; Enemy_143 (ID $8F)
enemy_143:
  dw $4F07        ; HP
  db $08          ; Attack
  db $5F          ; Defense
  db $80          ; Magic
  db $81          ; Magic Defense
  db $90          ; Speed
  db $91          ; Accuracy
  db $64          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $C2C1        ; EXP
  dw $C2D1        ; Gold
  db $07          ; Drop Item
  db $12          ; Drop Rate
  db $08          ; Graphics ID
  db $13          ; Palette
  dw $0022        ; AI Script

; Enemy_144 (ID $90)
enemy_144:
  dw $8180        ; HP
  db $90          ; Attack
  db $91          ; Defense
  db $82          ; Magic
  db $83          ; Magic Defense
  db $92          ; Speed
  db $93          ; Accuracy
  db $4E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5F07        ; EXP
  dw $5F07        ; Gold
  db $07          ; Drop Item
  db $5F          ; Drop Rate
  db $08          ; Graphics ID
  db $5F          ; Palette
  dw $124E        ; AI Script

; Enemy_145 (ID $91)
enemy_145:
  dw $8B8A        ; HP
  db $8A          ; Attack
  db $8B          ; Defense
  db $80          ; Magic
  db $81          ; Magic Defense
  db $90          ; Speed
  db $91          ; Accuracy
  db $82          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $8B8A        ; EXP
  dw $8B8A        ; Gold
  db $22          ; Drop Item
  db $00          ; Drop Rate
  db $33          ; Graphics ID
  db $00          ; Palette
  dw $8B8A        ; AI Script

; Enemy_146 (ID $92)
enemy_146:
  dw $0302        ; HP
  db $5E          ; Attack
  db $13          ; Defense
  db $07          ; Magic
  db $4F          ; Magic Defense
  db $07          ; Speed
  db $5F          ; Accuracy
  db $C4          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0116        ; EXP
  dw $5F10        ; Gold
  db $02          ; Drop Item
  db $01          ; Drop Rate
  db $5E          ; Graphics ID
  db $5F          ; Palette
  dw $0302        ; AI Script

; Enemy_147 (ID $93)
enemy_147:
  dw $E5E4        ; HP
  db $F3          ; Attack
  db $F6          ; Defense
  db $C2          ; Magic
  db $C2          ; Magic Defense
  db $C2          ; Speed
  db $C2          ; Accuracy
  db $E4          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $E5E4        ; EXP
  dw $F6F3        ; Gold
  db $11          ; Drop Item
  db $4E          ; Drop Rate
  db $10          ; Graphics ID
  db $5F          ; Palette
  dw $4F4E        ; AI Script

; Enemy_148 (ID $94)
enemy_148:
  dw $4F4E        ; HP
  db $5E          ; Attack
  db $5F          ; Defense
  db $4E          ; Magic
  db $12          ; Magic Defense
  db $5E          ; Speed
  db $13          ; Accuracy
  db $07          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0107        ; EXP
  dw $5F07        ; Gold
  db $07          ; Drop Item
  db $12          ; Drop Rate
  db $07          ; Graphics ID
  db $13          ; Palette
  dw $0307        ; AI Script

; Enemy_149 (ID $95)
enemy_149:
  dw $9796        ; HP
  db $97          ; Attack
  db $96          ; Defense
  db $AC          ; Magic
  db $AC          ; Magic Defense
  db $BC          ; Speed
  db $BC          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $C3C3        ; EXP
  dw $D3D3        ; Gold
  db $E4          ; Drop Item
  db $E5          ; Drop Rate
  db $F4          ; Graphics ID
  db $F5          ; Palette
  dw $E5E4        ; AI Script

; Enemy_150 (ID $96)
enemy_150:
  dw $E5E4        ; HP
  db $F3          ; Attack
  db $F6          ; Defense
  db $C2          ; Magic
  db $C2          ; Magic Defense
  db $C2          ; Speed
  db $C2          ; Accuracy
  db $89          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $8823        ; EXP
  dw $0032        ; Gold
  db $07          ; Drop Item
  db $01          ; Drop Rate
  db $08          ; Graphics ID
  db $5F          ; Palette
  dw $0000        ; AI Script

; Enemy_154 (ID $9A)
enemy_154:
  dw $2726        ; HP
  db $36          ; Attack
  db $37          ; Defense
  db $24          ; Magic
  db $25          ; Magic Defense
  db $34          ; Speed
  db $35          ; Accuracy
  db $02          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0504        ; EXP
  dw $1514        ; Gold
  db $02          ; Drop Item
  db $02          ; Drop Rate
  db $12          ; Graphics ID
  db $13          ; Palette
  dw $0504        ; AI Script

; Enemy_155 (ID $9B)
enemy_155:
  dw $3131        ; HP
  db $23          ; Attack
  db $23          ; Defense
  db $33          ; Magic
  db $33          ; Magic Defense
  db $03          ; Speed
  db $03          ; Accuracy
  db $60          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6362        ; EXP
  dw $7372        ; Gold
  db $6D          ; Drop Item
  db $6D          ; Drop Rate
  db $7D          ; Graphics ID
  db $7D          ; Palette
  dw $6E6E        ; AI Script

; Enemy_156 (ID $9C)
enemy_156:
  dw $4D4C        ; HP
  db $5C          ; Attack
  db $5D          ; Defense
  db $4D          ; Magic
  db $4D          ; Magic Defense
  db $5D          ; Speed
  db $5D          ; Accuracy
  db $4D          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $3C2C        ; EXP
  dw $2C3C        ; Gold
  db $46          ; Drop Item
  db $47          ; Drop Rate
  db $2F          ; Graphics ID
  db $2F          ; Palette
  dw $0D0A        ; AI Script

; Enemy_157 (ID $9D)
enemy_157:
  dw $4141        ; HP
  db $51          ; Attack
  db $51          ; Defense
  db $44          ; Magic
  db $45          ; Magic Defense
  db $54          ; Speed
  db $55          ; Accuracy
  db $46          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $6464        ; EXP
  dw $7474        ; Gold
  db $46          ; Drop Item
  db $47          ; Drop Rate
  db $56          ; Graphics ID
  db $57          ; Palette
  dw $0202        ; AI Script

; Enemy_158 (ID $9E)
enemy_158:
  dw $3F3F        ; HP
  db $2E          ; Attack
  db $2E          ; Defense
  db $1E          ; Magic
  db $1F          ; Magic Defense
  db $0E          ; Speed
  db $0F          ; Accuracy
  db $67          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1F1E        ; EXP
  dw $0F0E        ; Gold
  db $44          ; Drop Item
  db $45          ; Drop Rate
  db $54          ; Graphics ID
  db $55          ; Palette
  dw $4746        ; AI Script

; Enemy_159 (ID $9F)
enemy_159:
  dw $0303        ; HP
  db $03          ; Attack
  db $03          ; Defense
  db $04          ; Magic
  db $05          ; Magic Defense
  db $14          ; Speed
  db $15          ; Accuracy
  db $4E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $4F4F        ; EXP
  dw $5F5F        ; Gold
  db $4F          ; Drop Item
  db $4E          ; Drop Rate
  db $5F          ; Graphics ID
  db $5E          ; Palette
  dw $2B2A        ; AI Script

; Enemy_160 (ID $A0)
enemy_160:
  dw $8484        ; HP
  db $84          ; Attack
  db $84          ; Defense
  db $90          ; Magic
  db $90          ; Magic Defense
  db $84          ; Speed
  db $84          ; Accuracy
  db $84          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $8484        ; EXP
  dw $9494        ; Gold
  db $94          ; Drop Item
  db $94          ; Drop Rate
  db $84          ; Graphics ID
  db $84          ; Palette
  dw $0303        ; AI Script

; Enemy_161 (ID $A1)
enemy_161:
  dw $0303        ; HP
  db $03          ; Attack
  db $03          ; Defense
  db $03          ; Magic
  db $03          ; Magic Defense
  db $03          ; Speed
  db $03          ; Accuracy
  db $03          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $3828        ; EXP
  dw $0303        ; Gold
  db $38          ; Drop Item
  db $38          ; Drop Rate
  db $03          ; Graphics ID
  db $03          ; Palette
  dw $2838        ; AI Script

; Enemy_162 (ID $A2)
enemy_162:
  dw $0303        ; HP
  db $03          ; Attack
  db $03          ; Defense
  db $03          ; Magic
  db $03          ; Magic Defense
  db $03          ; Speed
  db $03          ; Accuracy
  db $03          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0303        ; EXP
  dw $0303        ; Gold
  db $03          ; Drop Item
  db $03          ; Drop Rate
  db $03          ; Graphics ID
  db $03          ; Palette
  dw $0303        ; AI Script

; Enemy_163 (ID $A3)
enemy_163:
  dw $0B0A        ; HP
  db $1A          ; Attack
  db $1B          ; Defense
  db $0C          ; Magic
  db $0D          ; Magic Defense
  db $1C          ; Speed
  db $1D          ; Accuracy
  db $03          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0303        ; EXP
  dw $0303        ; Gold
  db $03          ; Drop Item
  db $03          ; Drop Rate
  db $03          ; Graphics ID
  db $03          ; Palette
  dw $0303        ; AI Script

; Enemy_164 (ID $A4)
enemy_164:
  dw $0303        ; HP
  db $03          ; Attack
  db $03          ; Defense
  db $03          ; Magic
  db $03          ; Magic Defense
  db $03          ; Speed
  db $03          ; Accuracy
  db $03          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0303        ; EXP
  dw $0303        ; Gold
  db $03          ; Drop Item
  db $03          ; Drop Rate
  db $03          ; Graphics ID
  db $03          ; Palette
  dw $0303        ; AI Script

; Enemy_165 (ID $A5)
enemy_165:
  dw $0303        ; HP
  db $03          ; Attack
  db $03          ; Defense
  db $03          ; Magic
  db $03          ; Magic Defense
  db $03          ; Speed
  db $03          ; Accuracy
  db $03          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0303        ; EXP
  dw $0303        ; Gold
  db $03          ; Drop Item
  db $03          ; Drop Rate
  db $03          ; Graphics ID
  db $03          ; Palette
  dw $0303        ; AI Script

; Enemy_166 (ID $A6)
enemy_166:
  dw $0303        ; HP
  db $03          ; Attack
  db $03          ; Defense
  db $03          ; Magic
  db $03          ; Magic Defense
  db $03          ; Speed
  db $03          ; Accuracy
  db $03          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0303        ; EXP
  dw $0303        ; Gold
  db $24          ; Drop Item
  db $25          ; Drop Rate
  db $34          ; Graphics ID
  db $35          ; Palette
  dw $0100        ; AI Script

; Enemy_167 (ID $A7)
enemy_167:
  dw $0504        ; HP
  db $0C          ; Attack
  db $15          ; Defense
  db $11          ; Magic
  db $12          ; Magic Defense
  db $10          ; Speed
  db $0B          ; Accuracy
  db $12          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $E0E0        ; EXP
  dw $E0E0        ; Gold
  db $86          ; Drop Item
  db $87          ; Drop Rate
  db $9B          ; Graphics ID
  db $9F          ; Palette
  dw $E5E4        ; AI Script

; Enemy_168 (ID $A8)
enemy_168:
  dw $0908        ; HP
  db $2A          ; Attack
  db $19          ; Defense
  db $0D          ; Magic
  db $21          ; Magic Defense
  db $30          ; Speed
  db $31          ; Accuracy
  db $20          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0E20        ; EXP
  dw $3130        ; Gold
  db $0A          ; Drop Item
  db $08          ; Drop Rate
  db $1A          ; Graphics ID
  db $2A          ; Palette
  dw $4141        ; AI Script

; Enemy_169 (ID $A9)
enemy_169:
  dw $2524        ; HP
  db $34          ; Attack
  db $35          ; Defense
  db $24          ; Magic
  db $25          ; Magic Defense
  db $33          ; Speed
  db $36          ; Accuracy
  db $8A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5352        ; EXP
  dw $2D2D        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $30          ; Graphics ID
  db $1E          ; Palette
  dw $2120        ; AI Script

; Enemy_170 (ID $AA)
enemy_170:
  dw $080A        ; HP
  db $1A          ; Attack
  db $18          ; Defense
  db $2C          ; Magic
  db $25          ; Magic Defense
  db $3C          ; Speed
  db $3D          ; Accuracy
  db $24          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2529        ; EXP
  dw $3938        ; Gold
  db $24          ; Drop Item
  db $2B          ; Drop Rate
  db $3A          ; Graphics ID
  db $38          ; Palette
  dw $2524        ; AI Script

; Enemy_171 (ID $AB)
enemy_171:
  dw $2D2D        ; HP
  db $34          ; Attack
  db $35          ; Defense
  db $17          ; Magic
  db $16          ; Magic Defense
  db $34          ; Speed
  db $35          ; Accuracy
  db $3B          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2E2D        ; EXP
  dw $3534        ; Gold
  db $0F          ; Drop Item
  db $0F          ; Drop Rate
  db $42          ; Graphics ID
  db $43          ; Palette
  dw $2D2E        ; AI Script

; Enemy_172 (ID $AC)
enemy_172:
  dw $CFCF        ; HP
  db $CF          ; Attack
  db $CF          ; Defense
  db $CD          ; Magic
  db $CD          ; Magic Defense
  db $CE          ; Speed
  db $CE          ; Accuracy
  db $CD          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $CCCC        ; EXP
  dw $CCCC        ; Gold
  db $1D          ; Drop Item
  db $1B          ; Drop Rate
  db $16          ; Graphics ID
  db $17          ; Palette
  dw $2120        ; AI Script

; Enemy_173 (ID $AD)
enemy_173:
  dw $E0E0        ; HP
  db $E0          ; Attack
  db $E0          ; Defense
  db $20          ; Magic
  db $21          ; Magic Defense
  db $30          ; Speed
  db $1E          ; Accuracy
  db $1C          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1F0F        ; EXP
  dw $4342        ; Gold
  db $1F          ; Drop Item
  db $0F          ; Drop Rate
  db $42          ; Graphics ID
  db $43          ; Palette
  dw $E0E0        ; AI Script

; Enemy_174 (ID $AE)
enemy_174:
  dw $C6C7        ; HP
  db $D7          ; Attack
  db $D6          ; Defense
  db $C3          ; Magic
  db $C2          ; Magic Defense
  db $D3          ; Speed
  db $D2          ; Accuracy
  db $24          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2424        ; EXP
  dw $3333        ; Gold
  db $88          ; Drop Item
  db $89          ; Drop Rate
  db $98          ; Graphics ID
  db $99          ; Palette
  dw $6665        ; AI Script

; Enemy_175 (ID $AF)
enemy_175:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $77          ; Defense
  db $6B          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $7BFB        ; Gold
  db $FB          ; Drop Item
  db $77          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $0B0A        ; AI Script

; Enemy_176 (ID $B0)
enemy_176:
  dw $8988        ; HP
  db $98          ; Attack
  db $99          ; Defense
  db $88          ; Magic
  db $89          ; Magic Defense
  db $98          ; Speed
  db $99          ; Accuracy
  db $88          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FB0E        ; EXP
  dw $0EFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $0E          ; Graphics ID
  db $FB          ; Palette
  dw $FB0E        ; AI Script

; Enemy_177 (ID $B1)
enemy_177:
  dw $E0E0        ; HP
  db $E0          ; Attack
  db $E0          ; Defense
  db $E0          ; Magic
  db $E0          ; Magic Defense
  db $E0          ; Speed
  db $E0          ; Accuracy
  db $E0          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $E0E0        ; EXP
  dw $E0E0        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $1D          ; Graphics ID
  db $1B          ; Palette
  dw $2120        ; AI Script

; Enemy_178 (ID $B2)
enemy_178:
  dw $E0E0        ; HP
  db $E0          ; Attack
  db $E0          ; Defense
  db $E0          ; Magic
  db $E0          ; Magic Defense
  db $E0          ; Speed
  db $E0          ; Accuracy
  db $E0          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $E0E0        ; EXP
  dw $E0E0        ; Gold
  db $E0          ; Drop Item
  db $E0          ; Drop Rate
  db $E0          ; Graphics ID
  db $E0          ; Palette
  dw $E0E0        ; AI Script

; Enemy_179 (ID $B3)
enemy_179:
  dw $E0E0        ; HP
  db $E0          ; Attack
  db $E0          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $24          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0100        ; EXP
  dw $0B10        ; Gold
  db $0F          ; Drop Item
  db $0F          ; Drop Rate
  db $42          ; Graphics ID
  db $43          ; Palette
  dw $0001        ; AI Script

; Enemy_180 (ID $B4)
enemy_180:
  dw $0504        ; HP
  db $0C          ; Attack
  db $10          ; Defense
  db $9A          ; Magic
  db $9A          ; Magic Defense
  db $9A          ; Speed
  db $9A          ; Accuracy
  db $20          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0908        ; EXP
  dw $1918        ; Gold
  db $0A          ; Drop Item
  db $08          ; Drop Rate
  db $1A          ; Graphics ID
  db $18          ; Palette
  dw $2524        ; AI Script

; Enemy_181 (ID $B5)
enemy_181:
  dw $2120        ; HP
  db $30          ; Attack
  db $31          ; Defense
  db $20          ; Magic
  db $0E          ; Magic Defense
  db $30          ; Speed
  db $31          ; Accuracy
  db $0A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2122        ; EXP
  dw $3132        ; Gold
  db $22          ; Drop Item
  db $21          ; Drop Rate
  db $23          ; Graphics ID
  db $31          ; Palette
  dw $2529        ; AI Script

; Enemy_182 (ID $B6)
enemy_182:
  dw $0E20        ; HP
  db $30          ; Attack
  db $31          ; Defense
  db $40          ; Magic
  db $41          ; Magic Defense
  db $50          ; Speed
  db $51          ; Accuracy
  db $24          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2120        ; EXP
  dw $3130        ; Gold
  db $08          ; Drop Item
  db $09          ; Drop Rate
  db $18          ; Graphics ID
  db $19          ; Palette
  dw $1F0F        ; AI Script

; Enemy_183 (ID $B7)
enemy_183:
  dw $2F24        ; HP
  db $3E          ; Attack
  db $3F          ; Defense
  db $24          ; Magic
  db $25          ; Magic Defense
  db $34          ; Speed
  db $35          ; Accuracy
  db $08          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2120        ; EXP
  dw $1B1D        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $30          ; Graphics ID
  db $31          ; Palette
  dw $2120        ; AI Script

; Enemy_184 (ID $B8)
enemy_184:
  dw $093B        ; HP
  db $18          ; Attack
  db $19          ; Defense
  db $BA          ; Magic
  db $BB          ; Magic Defense
  db $BA          ; Speed
  db $BB          ; Accuracy
  db $0A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $0A          ; Drop Item
  db $3B          ; Drop Rate
  db $1A          ; Graphics ID
  db $18          ; Palette
  dw $CDCC        ; AI Script

; Enemy_185 (ID $B9)
enemy_185:
  dw $9A9A        ; HP
  db $9A          ; Attack
  db $9A          ; Defense
  db $20          ; Magic
  db $21          ; Magic Defense
  db $30          ; Speed
  db $1E          ; Accuracy
  db $1C          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0100        ; EXP
  dw $0B10        ; Gold
  db $0F          ; Drop Item
  db $0F          ; Drop Rate
  db $42          ; Graphics ID
  db $43          ; Palette
  dw $0001        ; AI Script

; Enemy_186 (ID $BA)
enemy_186:
  dw $061C        ; HP
  db $17          ; Attack
  db $16          ; Defense
  db $0F          ; Magic
  db $0F          ; Magic Defense
  db $42          ; Speed
  db $43          ; Accuracy
  db $08          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $080A        ; EXP
  dw $181A        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $30          ; Graphics ID
  db $31          ; Palette
  dw $4746        ; AI Script

; Enemy_187 (ID $BB)
enemy_187:
  dw $6564        ; HP
  db $74          ; Attack
  db $75          ; Defense
  db $9A          ; Magic
  db $9A          ; Magic Defense
  db $9A          ; Speed
  db $9A          ; Accuracy
  db $52          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2120        ; EXP
  dw $1B1D        ; Gold
  db $20          ; Drop Item
  db $21          ; Drop Rate
  db $1C          ; Graphics ID
  db $1D          ; Palette
  dw $9A9A        ; AI Script

; Enemy_188 (ID $BC)
enemy_188:
  dw $1D1C        ; HP
  db $17          ; Attack
  db $16          ; Defense
  db $2D          ; Magic
  db $2E          ; Magic Defense
  db $34          ; Speed
  db $35          ; Accuracy
  db $2E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $66          ; Drop Item
  db $67          ; Drop Rate
  db $76          ; Graphics ID
  db $77          ; Palette
  dw $6968        ; AI Script

; Enemy_189 (ID $BD)
enemy_189:
  dw $210D        ; HP
  db $30          ; Attack
  db $31          ; Defense
  db $02          ; Magic
  db $03          ; Magic Defense
  db $10          ; Speed
  db $0B          ; Accuracy
  db $9A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $9A9A        ; EXP
  dw $9A9A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $9A9A        ; AI Script

; Enemy_190 (ID $BE)
enemy_190:
  dw $9F9E        ; HP
  db $88          ; Attack
  db $89          ; Defense
  db $6C          ; Magic
  db $6D          ; Magic Defense
  db $7C          ; Speed
  db $8D          ; Accuracy
  db $6E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $8A8B        ; EXP
  dw $8B8A        ; Gold
  db $9A          ; Drop Item
  db $9A          ; Drop Rate
  db $9A          ; Graphics ID
  db $9A          ; Palette
  dw $4141        ; AI Script

; Enemy_191 (ID $BF)
enemy_191:
  dw $8AA9        ; HP
  db $A4          ; Attack
  db $A5          ; Defense
  db $B0          ; Magic
  db $A2          ; Magic Defense
  db $A0          ; Speed
  db $A1          ; Accuracy
  db $A3          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $B5A3        ; EXP
  dw $A5B3        ; Gold
  db $B0          ; Drop Item
  db $B1          ; Drop Rate
  db $8A          ; Graphics ID
  db $B6          ; Palette
  dw $B3B2        ; AI Script

; Enemy_192 (ID $C0)
enemy_192:
  dw $1818        ; HP
  db $18          ; Attack
  db $18          ; Defense
  db $2A          ; Magic
  db $2B          ; Magic Defense
  db $3A          ; Speed
  db $3B          ; Accuracy
  db $2A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2B2A        ; EXP
  dw $3B3A        ; Gold
  db $2A          ; Drop Item
  db $2B          ; Drop Rate
  db $3A          ; Graphics ID
  db $3B          ; Palette
  dw $3C3C        ; AI Script

; Enemy_193 (ID $C1)
enemy_193:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_194 (ID $C2)
enemy_194:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_195 (ID $C3)
enemy_195:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $3C          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $3C3C        ; EXP
  dw $FBFB        ; Gold
  db $3C          ; Drop Item
  db $3C          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $3C3C        ; AI Script

; Enemy_196 (ID $C4)
enemy_196:
  dw $1818        ; HP
  db $2C          ; Attack
  db $2C          ; Defense
  db $29          ; Magic
  db $29          ; Magic Defense
  db $2C          ; Speed
  db $2C          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $FBFB        ; AI Script

; Enemy_197 (ID $C5)
enemy_197:
  dw $FBFB        ; HP
  db $FB          ; Attack
  db $FB          ; Defense
  db $FB          ; Magic
  db $FB          ; Magic Defense
  db $FB          ; Speed
  db $FB          ; Accuracy
  db $FB          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $FB          ; Drop Item
  db $FB          ; Drop Rate
  db $FB          ; Graphics ID
  db $FB          ; Palette
  dw $0706        ; AI Script

; Enemy_198 (ID $C6)
enemy_198:
  dw $3D3D        ; HP
  db $3C          ; Attack
  db $0B          ; Defense
  db $26          ; Magic
  db $26          ; Magic Defense
  db $36          ; Speed
  db $36          ; Accuracy
  db $45          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $40          ; Drop Item
  db $20          ; Drop Rate
  db $50          ; Graphics ID
  db $30          ; Palette
  dw $4020        ; AI Script

; Enemy_199 (ID $C7)
enemy_199:
  dw $0200        ; HP
  db $10          ; Attack
  db $02          ; Defense
  db $27          ; Magic
  db $27          ; Magic Defense
  db $37          ; Speed
  db $37          ; Accuracy
  db $18          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $FBFB        ; EXP
  dw $FBFB        ; Gold
  db $08          ; Drop Item
  db $09          ; Drop Rate
  db $08          ; Graphics ID
  db $09          ; Palette
  dw $2626        ; AI Script

; Enemy_200 (ID $C8)
enemy_200:
  dw $2240        ; HP
  db $50          ; Attack
  db $32          ; Defense
  db $22          ; Magic
  db $40          ; Magic Defense
  db $32          ; Speed
  db $50          ; Accuracy
  db $2D          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2E2E        ; EXP
  dw $2E2E        ; Gold
  db $2E          ; Drop Item
  db $2E          ; Drop Rate
  db $3E          ; Graphics ID
  db $3E          ; Palette
  dw $0201        ; AI Script

; Enemy_201 (ID $C9)
enemy_201:
  dw $1212        ; HP
  db $12          ; Attack
  db $12          ; Defense
  db $3D          ; Magic
  db $0A          ; Magic Defense
  db $3D          ; Speed
  db $0A          ; Accuracy
  db $0A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $5051        ; EXP
  dw $51FB        ; Gold
  db $34          ; Drop Item
  db $35          ; Drop Rate
  db $2E          ; Graphics ID
  db $2E          ; Palette
  dw $5150        ; AI Script

; Enemy_202 (ID $CA)
enemy_202:
  dw $0B26        ; HP
  db $36          ; Attack
  db $0B          ; Defense
  db $1B          ; Magic
  db $28          ; Magic Defense
  db $38          ; Speed
  db $38          ; Accuracy
  db $28          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $1B28        ; EXP
  dw $3838        ; Gold
  db $3D          ; Drop Item
  db $3D          ; Drop Rate
  db $3C          ; Graphics ID
  db $3C          ; Palette
  dw $2C2C        ; AI Script

; Enemy_203 (ID $CB)
enemy_203:
  dw $2C2C        ; HP
  db $3C          ; Attack
  db $3C          ; Defense
  db $1A          ; Magic
  db $0B          ; Magic Defense
  db $36          ; Speed
  db $0B          ; Accuracy
  db $0F          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0C0D        ; EXP
  dw $1C1D        ; Gold
  db $21          ; Drop Item
  db $21          ; Drop Rate
  db $31          ; Graphics ID
  db $31          ; Palette
  dw $2323        ; AI Script

; Enemy_204 (ID $CC)
enemy_204:
  dw $0A3D        ; HP
  db $3D          ; Attack
  db $0A          ; Defense
  db $0A          ; Magic
  db $3D          ; Magic Defense
  db $0A          ; Speed
  db $3D          ; Accuracy
  db $2E          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $2F2F        ; EXP
  dw $3F3F        ; Gold
  db $08          ; Drop Item
  db $09          ; Drop Rate
  db $08          ; Graphics ID
  db $09          ; Palette
  dw $1818        ; AI Script

; Enemy_205 (ID $CD)
enemy_205:
  dw $0D00        ; HP
  db $00          ; Attack
  db $0F          ; Defense
  db $00          ; Magic
  db $0F          ; Magic Defense
  db $00          ; Speed
  db $07          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0000        ; EXP
  dw $0000        ; Gold
  db $00          ; Drop Item
  db $0F          ; Drop Rate
  db $00          ; Graphics ID
  db $0F          ; Palette
  dw $0100        ; AI Script

; Enemy_206 (ID $CE)
enemy_206:
  dw $0900        ; HP
  db $00          ; Attack
  db $00          ; Defense
  db $0A          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $06          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0700        ; EXP
  dw $0700        ; Gold
  db $00          ; Drop Item
  db $07          ; Drop Rate
  db $00          ; Graphics ID
  db $00          ; Palette
  dw $0002        ; AI Script

; Enemy_207 (ID $CF)
enemy_207:
  dw $080C        ; HP
  db $02          ; Attack
  db $00          ; Defense
  db $08          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $08          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0900        ; EXP
  dw $0008        ; Gold
  db $04          ; Drop Item
  db $00          ; Drop Rate
  db $00          ; Graphics ID
  db $00          ; Palette
  dw $0000        ; AI Script

; Enemy_208 (ID $D0)
enemy_208:
  dw $0A00        ; HP
  db $00          ; Attack
  db $00          ; Defense
  db $00          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $00          ; Accuracy
  db $04          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0007        ; EXP
  dw $0A0F        ; Gold
  db $00          ; Drop Item
  db $0F          ; Drop Rate
  db $00          ; Graphics ID
  db $0A          ; Palette
  dw $000F        ; AI Script

; Enemy_209 (ID $D1)
enemy_209:
  dw $0803        ; HP
  db $04          ; Attack
  db $0B          ; Defense
  db $00          ; Magic
  db $0A          ; Magic Defense
  db $0F          ; Speed
  db $06          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $000F        ; EXP
  dw $050F        ; Gold
  db $00          ; Drop Item
  db $00          ; Drop Rate
  db $0A          ; Graphics ID
  db $0F          ; Palette
  dw $000C        ; AI Script

; Enemy_212 (ID $D4)
enemy_212:
  dw $0300        ; HP
  db $00          ; Attack
  db $0A          ; Defense
  db $0F          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $00          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0001        ; EXP
  dw $0301        ; Gold
  db $0F          ; Drop Item
  db $00          ; Drop Rate
  db $00          ; Graphics ID
  db $0A          ; Palette
  dw $000F        ; AI Script

; Enemy_216 (ID $D8)
enemy_216:
  dw $0F00        ; HP
  db $00          ; Attack
  db $00          ; Defense
  db $00          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $00          ; Accuracy
  db $0A          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0000        ; EXP
  dw $0000        ; Gold
  db $00          ; Drop Item
  db $00          ; Drop Rate
  db $00          ; Graphics ID
  db $0A          ; Palette
  dw $0000        ; AI Script

; Enemy_217 (ID $D9)
enemy_217:
  dw $0002        ; HP
  db $00          ; Attack
  db $00          ; Defense
  db $00          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $00          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0000        ; EXP
  dw $0000        ; Gold
  db $00          ; Drop Item
  db $00          ; Drop Rate
  db $00          ; Graphics ID
  db $00          ; Palette
  dw $0000        ; AI Script

; Enemy_223 (ID $DF)
enemy_223:
  dw $0009        ; HP
  db $00          ; Attack
  db $00          ; Defense
  db $00          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $00          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0004        ; EXP
  dw $0000        ; Gold
  db $0E          ; Drop Item
  db $04          ; Drop Rate
  db $00          ; Graphics ID
  db $00          ; Palette
  dw $0000        ; AI Script

; Enemy_225 (ID $E1)
enemy_225:
  dw $0400        ; HP
  db $00          ; Attack
  db $05          ; Defense
  db $0A          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $00          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0000        ; EXP
  dw $0000        ; Gold
  db $00          ; Drop Item
  db $00          ; Drop Rate
  db $00          ; Graphics ID
  db $00          ; Palette
  dw $0000        ; AI Script

; Enemy_244 (ID $F4)
enemy_244:
  dw $0A0A        ; HP
  db $0A          ; Attack
  db $00          ; Defense
  db $00          ; Magic
  db $0A          ; Magic Defense
  db $00          ; Speed
  db $02          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $000A        ; EXP
  dw $0000        ; Gold
  db $00          ; Drop Item
  db $00          ; Drop Rate
  db $00          ; Graphics ID
  db $0A          ; Palette
  dw $0000        ; AI Script

; Enemy_248 (ID $F8)
enemy_248:
  dw $0400        ; HP
  db $00          ; Attack
  db $00          ; Defense
  db $0E          ; Magic
  db $00          ; Magic Defense
  db $01          ; Speed
  db $00          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $0F0F        ; EXP
  dw $0A0A        ; Gold
  db $00          ; Drop Item
  db $C0          ; Drop Rate
  db $0A          ; Graphics ID
  db $0A          ; Palette
  dw $0A0A        ; AI Script

; Enemy_251 (ID $FB)
enemy_251:
  dw $0400        ; HP
  db $00          ; Attack
  db $00          ; Defense
  db $0E          ; Magic
  db $00          ; Magic Defense
  db $00          ; Speed
  db $0B          ; Accuracy
  db $00          ; Evade
  db $00          ; Element Resist (TODO)
  db $00          ; Status Resist (TODO)
  db $00,$00      ; Reserved
  dw $000E        ; EXP
  dw $0A00        ; Gold
  db $00          ; Drop Item
  db $00          ; Drop Rate
  db $00          ; Graphics ID
  db $00          ; Palette
  dw $0000        ; AI Script

