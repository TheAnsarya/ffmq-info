;==============================================================================
; Final Fantasy Mystic Quest - Enemy Attack Links
; AUTO-GENERATED from data/extracted/attacks/enemy_attack_links.json
;==============================================================================
; DO NOT EDIT MANUALLY - Edit JSON and regenerate
;
; Location: Bank $02, ROM $BE94
; Structure: 6 bytes per enemy, 83 enemies
; Each byte is an attack ID (0-168)
;
; To rebuild this file:
;   python tools/conversion/convert_enemy_attack_links.py
;==============================================================================

org $BE94

enemy_attack_links_table:

; Enemy 000 Attack Links
enemy_000_attacks:
  db $5A,$5B,$FF,$FF,$FF,$FF  ; Attacks: 90,91,255,255,255,255

; Enemy 001 Attack Links
enemy_001_attacks:
  db $5A,$5B,$A4,$FF,$FF,$FF  ; Attacks: 90,91,164,255,255,255

; Enemy 002 Attack Links
enemy_002_attacks:
  db $5B,$A4,$5A,$AC,$FF,$FF  ; Attacks: 91,164,90,172,255,255

; Enemy 003 Attack Links
enemy_003_attacks:
  db $78,$61,$FF,$FF,$FF,$FF  ; Attacks: 120,97,255,255,255,255

; Enemy 004 Attack Links
enemy_004_attacks:
  db $78,$61,$A7,$9C,$FF,$FF  ; Attacks: 120,97,167,156,255,255

; Enemy 005 Attack Links
enemy_005_attacks:
  db $61,$9C,$78,$50,$92,$FF  ; Attacks: 97,156,120,80,146,255

; Enemy 006 Attack Links
enemy_006_attacks:
  db $5D,$77,$FF,$FF,$FF,$FF  ; Attacks: 93,119,255,255,255,255

; Enemy 007 Attack Links
enemy_007_attacks:
  db $5D,$77,$BF,$FF,$FF,$FF  ; Attacks: 93,119,191,255,255,255

; Enemy 008 Attack Links
enemy_008_attacks:
  db $5D,$77,$BF,$52,$91,$FF  ; Attacks: 93,119,191,82,145,255

; Enemy 009 Attack Links
enemy_009_attacks:
  db $7B,$AA,$FF,$FF,$FF,$FF  ; Attacks: 123,170,255,255,255,255

; Enemy 010 Attack Links
enemy_010_attacks:
  db $7B,$AA,$A8,$FF,$FF,$FF  ; Attacks: 123,170,168,255,255,255

; Enemy 011 Attack Links
enemy_011_attacks:
  db $7B,$AA,$A8,$50,$B5,$FF  ; Attacks: 123,170,168,80,181,255

; Enemy 012 Attack Links
enemy_012_attacks:
  db $70,$71,$FF,$FF,$FF,$FF  ; Attacks: 112,113,255,255,255,255

; Enemy 013 Attack Links
enemy_013_attacks:
  db $70,$71,$81,$A9,$FF,$FF  ; Attacks: 112,113,129,169,255,255

; Enemy 014 Attack Links
enemy_014_attacks:
  db $81,$90,$71,$9F,$70,$FF  ; Attacks: 129,144,113,159,112,255

; Enemy 015 Attack Links
enemy_015_attacks:
  db $60,$55,$FF,$FF,$FF,$FF  ; Attacks: 96,85,255,255,255,255

; Enemy 016 Attack Links
enemy_016_attacks:
  db $60,$55,$80,$FF,$FF,$FF  ; Attacks: 96,85,128,255,255,255

; Enemy 017 Attack Links
enemy_017_attacks:
  db $60,$83,$55,$80,$BE,$FF  ; Attacks: 96,131,85,128,190,255

; Enemy 018 Attack Links
enemy_018_attacks:
  db $40,$5E,$A5,$FF,$FF,$FF  ; Attacks: 64,94,165,255,255,255

; Enemy 019 Attack Links
enemy_019_attacks:
  db $40,$5E,$A5,$AF,$FF,$FF  ; Attacks: 64,94,165,175,255,255

; Enemy 020 Attack Links
enemy_020_attacks:
  db $40,$5E,$A5,$AF,$57,$FF  ; Attacks: 64,94,165,175,87,255

; Enemy 021 Attack Links
enemy_021_attacks:
  db $72,$A0,$FF,$FF,$FF,$FF  ; Attacks: 114,160,255,255,255,255

; Enemy 022 Attack Links
enemy_022_attacks:
  db $72,$8D,$53,$FF,$FF,$FF  ; Attacks: 114,141,83,255,255,255

; Enemy 023 Attack Links
enemy_023_attacks:
  db $72,$8E,$B2,$53,$A0,$FF  ; Attacks: 114,142,178,83,160,255

; Enemy 024 Attack Links
enemy_024_attacks:
  db $6F,$9D,$A7,$C2,$FF,$FF  ; Attacks: 111,157,167,194,255,255

; Enemy 025 Attack Links
enemy_025_attacks:
  db $5F,$62,$AF,$AB,$B5,$FF  ; Attacks: 95,98,175,171,181,255

; Enemy 026 Attack Links
enemy_026_attacks:
  db $79,$86,$B7,$FF,$FF,$FF  ; Attacks: 121,134,183,255,255,255

; Enemy 027 Attack Links
enemy_027_attacks:
  db $79,$62,$86,$8B,$FF,$FF  ; Attacks: 121,98,134,139,255,255

; Enemy 028 Attack Links
enemy_028_attacks:
  db $48,$41,$B1,$AD,$FF,$FF  ; Attacks: 72,65,177,173,255,255

; Enemy 029 Attack Links
enemy_029_attacks:
  db $41,$48,$B1,$C2,$93,$C1  ; Attacks: 65,72,177,194,147,193

; Enemy 030 Attack Links
enemy_030_attacks:
  db $76,$8C,$A6,$70,$FF,$FF  ; Attacks: 118,140,166,112,255,255

; Enemy 031 Attack Links
enemy_031_attacks:
  db $76,$90,$83,$80,$B4,$FF  ; Attacks: 118,144,131,128,180,255

; Enemy 032 Attack Links
enemy_032_attacks:
  db $47,$B9,$A6,$FF,$FF,$FF  ; Attacks: 71,185,166,255,255,255

; Enemy 033 Attack Links
enemy_033_attacks:
  db $47,$B9,$AC,$A6,$FF,$FF  ; Attacks: 71,185,172,166,255,255

; Enemy 034 Attack Links
enemy_034_attacks:
  db $87,$6D,$A2,$FF,$FF,$FF  ; Attacks: 135,109,162,255,255,255

; Enemy 035 Attack Links
enemy_035_attacks:
  db $6D,$82,$A2,$FF,$FF,$FF  ; Attacks: 109,130,162,255,255,255

; Enemy 036 Attack Links
enemy_036_attacks:
  db $87,$6E,$51,$C2,$FF,$FF  ; Attacks: 135,110,81,194,255,255

; Enemy 037 Attack Links
enemy_037_attacks:
  db $6E,$87,$51,$B7,$C2,$FF  ; Attacks: 110,135,81,183,194,255

; Enemy 038 Attack Links
enemy_038_attacks:
  db $75,$B0,$A9,$C1,$FF,$FF  ; Attacks: 117,176,169,193,255,255

; Enemy 039 Attack Links
enemy_039_attacks:
  db $75,$91,$B0,$56,$C1,$FF  ; Attacks: 117,145,176,86,193,255

; Enemy 040 Attack Links
enemy_040_attacks:
  db $BE,$5C,$8D,$94,$FF,$FF  ; Attacks: 190,92,141,148,255,255

; Enemy 041 Attack Links
enemy_041_attacks:
  db $5C,$4C,$BE,$8E,$94,$FF  ; Attacks: 92,76,190,142,148,255

; Enemy 042 Attack Links
enemy_042_attacks:
  db $4C,$B2,$FF,$FF,$FF,$FF  ; Attacks: 76,178,255,255,255,255

; Enemy 043 Attack Links
enemy_043_attacks:
  db $4B,$4C,$4E,$B2,$FF,$FF  ; Attacks: 75,76,78,178,255,255

; Enemy 044 Attack Links
enemy_044_attacks:
  db $5F,$76,$98,$43,$FF,$FF  ; Attacks: 95,118,152,67,255,255

; Enemy 045 Attack Links
enemy_045_attacks:
  db $5F,$60,$81,$98,$A0,$FF  ; Attacks: 95,96,129,152,160,255

; Enemy 046 Attack Links
enemy_046_attacks:
  db $74,$7A,$9B,$43,$FF,$FF  ; Attacks: 116,122,155,67,255,255

; Enemy 047 Attack Links
enemy_047_attacks:
  db $BA,$74,$9B,$55,$57,$FF  ; Attacks: 186,116,155,85,87,255

; Enemy 048 Attack Links
enemy_048_attacks:
  db $95,$80,$B8,$A8,$FF,$FF  ; Attacks: 149,128,184,168,255,255

; Enemy 049 Attack Links
enemy_049_attacks:
  db $B8,$B5,$80,$95,$56,$FF  ; Attacks: 184,181,128,149,86,255

; Enemy 050 Attack Links
enemy_050_attacks:
  db $73,$A0,$97,$43,$FF,$FF  ; Attacks: 115,160,151,67,255,255

; Enemy 051 Attack Links
enemy_051_attacks:
  db $73,$97,$9B,$A0,$FF,$FF  ; Attacks: 115,151,155,160,255,255

; Enemy 052 Attack Links
enemy_052_attacks:
  db $A3,$6C,$AE,$FF,$FF,$FF  ; Attacks: 163,108,174,255,255,255

; Enemy 053 Attack Links
enemy_053_attacks:
  db $6C,$90,$A3,$AE,$B3,$FF  ; Attacks: 108,144,163,174,179,255

; Enemy 054 Attack Links
enemy_054_attacks:
  db $4D,$B6,$A5,$B3,$FF,$FF  ; Attacks: 77,182,165,179,255,255

; Enemy 055 Attack Links
enemy_055_attacks:
  db $B6,$4C,$4E,$BE,$B3,$A2  ; Attacks: 182,76,78,190,179,162

; Enemy 056 Attack Links
enemy_056_attacks:
  db $76,$63,$A8,$53,$9F,$FF  ; Attacks: 118,99,168,83,159,255

; Enemy 057 Attack Links
enemy_057_attacks:
  db $44,$64,$A0,$A4,$54,$A7  ; Attacks: 68,100,160,164,84,167

; Enemy 058 Attack Links
enemy_058_attacks:
  db $A1,$C0,$8C,$50,$BC,$FF  ; Attacks: 161,192,140,80,188,255

; Enemy 059 Attack Links
enemy_059_attacks:
  db $7D,$61,$8B,$88,$94,$FF  ; Attacks: 125,97,139,136,148,255

; Enemy 060 Attack Links
enemy_060_attacks:
  db $68,$82,$84,$42,$45,$AC  ; Attacks: 104,130,132,66,69,172

; Enemy 061 Attack Links
enemy_061_attacks:
  db $BD,$A7,$B5,$98,$52,$96  ; Attacks: 189,167,181,152,82,150

; Enemy 062 Attack Links
enemy_062_attacks:
  db $4E,$80,$8D,$C3,$B4,$94  ; Attacks: 78,128,141,195,180,148

; Enemy 063 Attack Links
enemy_063_attacks:
  db $7E,$91,$43,$93,$B2,$FF  ; Attacks: 126,145,67,147,178,255

; Enemy 064 Attack Links
enemy_064_attacks:
  db $C7,$B4,$4B,$AF,$AB,$FF  ; Attacks: 199,180,75,175,171,255

; Enemy 065 Attack Links
enemy_065_attacks:
  db $4E,$C5,$A4,$92,$FF,$FF  ; Attacks: 78,197,164,146,255,255

; Enemy 066 Attack Links
enemy_066_attacks:
  db $7C,$FF,$FF,$FF,$FF,$FF  ; Attacks: 124,255,255,255,255,255

; Enemy 067 Attack Links
enemy_067_attacks:
  db $44,$64,$54,$FF,$FF,$FF  ; Attacks: 68,100,84,255,255,255

; Enemy 068 Attack Links
enemy_068_attacks:
  db $C0,$65,$BC,$50,$A1,$FF  ; Attacks: 192,101,188,80,161,255

; Enemy 069 Attack Links
enemy_069_attacks:
  db $7D,$61,$88,$8D,$A4,$FF  ; Attacks: 125,97,136,141,164,255

; Enemy 070 Attack Links
enemy_070_attacks:
  db $42,$4D,$45,$84,$AC,$FF  ; Attacks: 66,77,69,132,172,255

; Enemy 071 Attack Links
enemy_071_attacks:
  db $BD,$99,$9E,$96,$B5,$FF  ; Attacks: 189,153,158,150,181,255

; Enemy 072 Attack Links
enemy_072_attacks:
  db $BB,$8D,$C3,$80,$B4,$FF  ; Attacks: 187,141,195,128,180,255

; Enemy 073 Attack Links
enemy_073_attacks:
  db $43,$91,$7E,$AC,$93,$FF  ; Attacks: 67,145,126,172,147,255

; Enemy 074 Attack Links
enemy_074_attacks:
  db $46,$C7,$C4,$AF,$AB,$7F  ; Attacks: 70,199,196,175,171,127

; Enemy 075 Attack Links
enemy_075_attacks:
  db $67,$69,$89,$AC,$66,$8A  ; Attacks: 103,105,137,172,102,138

; Enemy 076 Attack Links
enemy_076_attacks:
  db $59,$9A,$9F,$4E,$60,$B4  ; Attacks: 89,154,159,78,96,180

; Enemy 077 Attack Links
enemy_077_attacks:
  db $D7,$9A,$9F,$4E,$76,$8D  ; Attacks: 215,154,159,78,118,141

; Enemy 078 Attack Links
enemy_078_attacks:
  db $6B,$8F,$C6,$6A,$A2,$C8  ; Attacks: 107,143,198,106,162,200

; Enemy 079 Attack Links
enemy_079_attacks:
  db $D8,$D9,$DA,$93,$C8,$C9  ; Attacks: 216,217,218,147,200,201

; Enemy 080 Attack Links
enemy_080_attacks:
  db $CA,$53,$52,$A9,$FF,$FF  ; Attacks: 202,83,82,169,255,255

; Enemy 081 Attack Links
enemy_081_attacks:
  db $CD,$CC,$CB,$CF,$CE,$D0  ; Attacks: 205,204,203,207,206,208
