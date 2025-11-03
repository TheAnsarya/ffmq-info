;==============================================================================
; Final Fantasy Mystic Quest - Enemy Stats Data
; AUTO-GENERATED from data/extracted/enemies/enemies.json
;==============================================================================
; DO NOT EDIT MANUALLY - Edit JSON and regenerate
;
; Location: Bank $02, ROM $C275
; Structure: 14 bytes per enemy, 83 enemies
;
; To rebuild this file:
;   python tools/conversion/convert_enemies.py
;==============================================================================

org $C275

enemy_stats_table:

; Enemy 000: Brownie
enemy_000_stats:
  dw $0032           ; HP: 50
  db $03             ; Attack: 3
  db $01             ; Defense: 1
  db $03             ; Speed: 3
  db $01             ; Magic: 1
  dw $0000           ; Resistances: None
  db $01             ; Magic Defense: 1
  db $01             ; Magic Evade: 1
  db $02             ; Accuracy: 2
  db $01             ; Evade: 1
  dw $0000           ; Weaknesses: None

; Enemy 001: Mintmint
enemy_001_stats:
  dw $00A0           ; HP: 160
  db $0C             ; Attack: 12
  db $0B             ; Defense: 11
  db $0C             ; Speed: 12
  db $09             ; Magic: 9
  dw $0000           ; Resistances: None
  db $0B             ; Magic Defense: 11
  db $0A             ; Magic Evade: 10
  db $0D             ; Accuracy: 13
  db $0A             ; Evade: 10
  dw $0000           ; Weaknesses: None

; Enemy 002: Red Cap
enemy_002_stats:
  dw $01E0           ; HP: 480
  db $24             ; Attack: 36
  db $24             ; Defense: 36
  db $26             ; Speed: 38
  db $20             ; Magic: 32
  dw $0000           ; Resistances: None
  db $26             ; Magic Defense: 38
  db $28             ; Magic Evade: 40
  db $28             ; Accuracy: 40
  db $24             ; Evade: 36
  dw $0040           ; Weaknesses: Stone

; Enemy 003: Mad Plant
enemy_003_stats:
  dw $003C           ; HP: 60
  db $04             ; Attack: 4
  db $03             ; Defense: 3
  db $03             ; Speed: 3
  db $02             ; Magic: 2
  dw $0000           ; Resistances: None
  db $02             ; Magic Defense: 2
  db $02             ; Magic Evade: 2
  db $03             ; Accuracy: 3
  db $02             ; Evade: 2
  dw $0004           ; Weaknesses: Poison

; Enemy 004: Plant Man
enemy_004_stats:
  dw $01CC           ; HP: 460
  db $22             ; Attack: 34
  db $21             ; Defense: 33
  db $22             ; Speed: 34
  db $1E             ; Magic: 30
  dw $2400           ; Resistances: Axe, Fire
  db $20             ; Magic Defense: 32
  db $22             ; Magic Evade: 34
  db $23             ; Accuracy: 35
  db $20             ; Evade: 32
  dw $0024           ; Weaknesses: Poison, Paralysis

; Enemy 005: Live Oak
enemy_005_stats:
  dw $02C6           ; HP: 710
  db $34             ; Attack: 52
  db $35             ; Defense: 53
  db $33             ; Speed: 51
  db $2C             ; Magic: 44
  dw $2400           ; Resistances: Axe, Fire
  db $35             ; Magic Defense: 53
  db $34             ; Magic Evade: 52
  db $37             ; Accuracy: 55
  db $34             ; Evade: 52
  dw $0024           ; Weaknesses: Poison, Paralysis

; Enemy 006: Slime
enemy_006_stats:
  dw $0037           ; HP: 55
  db $03             ; Attack: 3
  db $02             ; Defense: 2
  db $03             ; Speed: 3
  db $01             ; Magic: 1
  dw $0000           ; Resistances: None
  db $01             ; Magic Defense: 1
  db $02             ; Magic Evade: 2
  db $02             ; Accuracy: 2
  db $01             ; Evade: 1
  dw $0002           ; Weaknesses: Blind

; Enemy 007: Jelly
enemy_007_stats:
  dw $01A4           ; HP: 420
  db $1F             ; Attack: 31
  db $1E             ; Defense: 30
  db $1C             ; Speed: 28
  db $19             ; Magic: 25
  dw $0000           ; Resistances: None
  db $1C             ; Magic Defense: 28
  db $1D             ; Magic Evade: 29
  db $1E             ; Accuracy: 30
  db $1C             ; Evade: 28
  dw $0002           ; Weaknesses: Blind

; Enemy 008: Ooze
enemy_008_stats:
  dw $02EE           ; HP: 750
  db $39             ; Attack: 57
  db $3A             ; Defense: 58
  db $3B             ; Speed: 59
  db $31             ; Magic: 49
  dw $B400           ; Resistances: Axe, Air, Fire, Earth
  db $38             ; Magic Defense: 56
  db $38             ; Magic Evade: 56
  db $3E             ; Accuracy: 62
  db $3C             ; Evade: 60
  dw $0402           ; Weaknesses: Blind, Axe

; Enemy 009: Poison Toad
enemy_009_stats:
  dw $0046           ; HP: 70
  db $05             ; Attack: 5
  db $04             ; Defense: 4
  db $03             ; Speed: 3
  db $04             ; Magic: 4
  dw $0400           ; Resistances: Axe
  db $03             ; Magic Defense: 3
  db $04             ; Magic Evade: 4
  db $06             ; Accuracy: 6
  db $06             ; Evade: 6
  dw $0000           ; Weaknesses: None

; Enemy 010: Giant Toad
enemy_010_stats:
  dw $00B4           ; HP: 180
  db $0E             ; Attack: 14
  db $0E             ; Defense: 14
  db $0F             ; Speed: 15
  db $0E             ; Magic: 14
  dw $2000           ; Resistances: Fire
  db $0D             ; Magic Defense: 13
  db $0E             ; Magic Evade: 14
  db $10             ; Accuracy: 16
  db $0E             ; Evade: 14
  dw $0000           ; Weaknesses: None

; Enemy 011: Mad Toad
enemy_011_stats:
  dw $02E4           ; HP: 740
  db $37             ; Attack: 55
  db $38             ; Defense: 56
  db $39             ; Speed: 57
  db $30             ; Magic: 48
  dw $6000           ; Resistances: Fire, Water
  db $39             ; Magic Defense: 57
  db $38             ; Magic Evade: 56
  db $3B             ; Accuracy: 59
  db $39             ; Evade: 57
  dw $4040           ; Weaknesses: Stone, Water

; Enemy 012: Basilisk
enemy_012_stats:
  dw $005A           ; HP: 90
  db $08             ; Attack: 8
  db $06             ; Defense: 6
  db $06             ; Speed: 6
  db $05             ; Magic: 5
  dw $0000           ; Resistances: None
  db $07             ; Magic Defense: 7
  db $05             ; Magic Evade: 5
  db $08             ; Accuracy: 8
  db $07             ; Evade: 7
  dw $0000           ; Weaknesses: None

; Enemy 013: Flazzard
enemy_013_stats:
  dw $01C2           ; HP: 450
  db $22             ; Attack: 34
  db $22             ; Defense: 34
  db $22             ; Speed: 34
  db $1F             ; Magic: 31
  dw $0420           ; Resistances: Paralysis, Axe
  db $26             ; Magic Defense: 38
  db $26             ; Magic Evade: 38
  db $25             ; Accuracy: 37
  db $25             ; Evade: 37
  dw $0040           ; Weaknesses: Stone

; Enemy 014: Salamand
enemy_014_stats:
  dw $0280           ; HP: 640
  db $32             ; Attack: 50
  db $30             ; Defense: 48
  db $31             ; Speed: 49
  db $2E             ; Magic: 46
  dw $0420           ; Resistances: Paralysis, Axe
  db $36             ; Magic Defense: 54
  db $38             ; Magic Evade: 56
  db $32             ; Accuracy: 50
  db $32             ; Evade: 50
  dw $0040           ; Weaknesses: Stone

; Enemy 015: Sand Worm
enemy_015_stats:
  dw $008C           ; HP: 140
  db $09             ; Attack: 9
  db $08             ; Defense: 8
  db $03             ; Speed: 3
  db $06             ; Magic: 6
  dw $0000           ; Resistances: None
  db $02             ; Magic Defense: 2
  db $02             ; Magic Evade: 2
  db $0A             ; Accuracy: 10
  db $02             ; Evade: 2
  dw $0084           ; Weaknesses: Poison, Doom

; Enemy 016: Land Worm
enemy_016_stats:
  dw $0109           ; HP: 265
  db $12             ; Attack: 18
  db $10             ; Defense: 16
  db $04             ; Speed: 4
  db $0D             ; Magic: 13
  dw $0000           ; Resistances: None
  db $0E             ; Magic Defense: 14
  db $05             ; Magic Evade: 5
  db $12             ; Accuracy: 18
  db $06             ; Evade: 6
  dw $0084           ; Weaknesses: Poison, Doom

; Enemy 017: Leech
enemy_017_stats:
  dw $02E9           ; HP: 745
  db $36             ; Attack: 54
  db $38             ; Defense: 56
  db $34             ; Speed: 52
  db $2D             ; Magic: 45
  dw $0020           ; Resistances: Paralysis
  db $34             ; Magic Defense: 52
  db $28             ; Magic Evade: 40
  db $38             ; Accuracy: 56
  db $30             ; Evade: 48
  dw $0294           ; Weaknesses: Poison, Sleep, Doom, Bomb

; Enemy 018: Skeleton
enemy_018_stats:
  dw $0078           ; HP: 120
  db $09             ; Attack: 9
  db $0A             ; Defense: 10
  db $08             ; Speed: 8
  db $06             ; Magic: 6
  dw $8000           ; Resistances: Earth
  db $09             ; Magic Defense: 9
  db $05             ; Magic Evade: 5
  db $0A             ; Accuracy: 10
  db $05             ; Evade: 5
  dw $0088           ; Weaknesses: Confusion, Doom

; Enemy 019: Red Bone
enemy_019_stats:
  dw $01FE           ; HP: 510
  db $27             ; Attack: 39
  db $28             ; Defense: 40
  db $26             ; Speed: 38
  db $22             ; Magic: 34
  dw $8000           ; Resistances: Earth
  db $2C             ; Magic Defense: 44
  db $26             ; Magic Evade: 38
  db $2C             ; Accuracy: 44
  db $28             ; Evade: 40
  dw $0048           ; Weaknesses: Confusion, Stone

; Enemy 020: Skuldier
enemy_020_stats:
  dw $02EE           ; HP: 750
  db $39             ; Attack: 57
  db $3D             ; Defense: 61
  db $39             ; Speed: 57
  db $32             ; Magic: 50
  dw $8000           ; Resistances: Earth
  db $3F             ; Magic Defense: 63
  db $3C             ; Magic Evade: 60
  db $3C             ; Accuracy: 60
  db $3C             ; Evade: 60
  dw $0019           ; Weaknesses: Silence, Confusion, Sleep

; Enemy 021: Roc
enemy_021_stats:
  dw $0064           ; HP: 100
  db $07             ; Attack: 7
  db $05             ; Defense: 5
  db $09             ; Speed: 9
  db $06             ; Magic: 6
  dw $0080           ; Resistances: Doom
  db $03             ; Magic Defense: 3
  db $07             ; Magic Evade: 7
  db $08             ; Accuracy: 8
  db $09             ; Evade: 9
  dw $0001           ; Weaknesses: Silence

; Enemy 022: Sparna
enemy_022_stats:
  dw $0104           ; HP: 260
  db $13             ; Attack: 19
  db $11             ; Defense: 17
  db $1A             ; Speed: 26
  db $12             ; Magic: 18
  dw $0080           ; Resistances: Doom
  db $16             ; Magic Defense: 22
  db $13             ; Magic Evade: 19
  db $18             ; Accuracy: 24
  db $19             ; Evade: 25
  dw $0001           ; Weaknesses: Silence

; Enemy 023: Garuda
enemy_023_stats:
  dw $0339           ; HP: 825
  db $3D             ; Attack: 61
  db $3D             ; Defense: 61
  db $45             ; Speed: 69
  db $34             ; Magic: 52
  dw $0080           ; Resistances: Doom
  db $3C             ; Magic Defense: 60
  db $3C             ; Magic Evade: 60
  db $44             ; Accuracy: 68
  db $46             ; Evade: 70
  dw $0011           ; Weaknesses: Silence, Sleep

; Enemy 024: Zombie
enemy_024_stats:
  dw $01F4           ; HP: 500
  db $23             ; Attack: 35
  db $26             ; Defense: 38
  db $23             ; Speed: 35
  db $1D             ; Magic: 29
  dw $B400           ; Resistances: Axe, Air, Fire, Earth
  db $1C             ; Magic Defense: 28
  db $1E             ; Magic Evade: 30
  db $25             ; Accuracy: 37
  db $25             ; Evade: 37
  dw $2058           ; Weaknesses: Confusion, Sleep, Stone, Fire

; Enemy 025: Mummy
enemy_025_stats:
  dw $02AD           ; HP: 685
  db $33             ; Attack: 51
  db $38             ; Defense: 56
  db $35             ; Speed: 53
  db $2E             ; Magic: 46
  dw $B400           ; Resistances: Axe, Air, Fire, Earth
  db $33             ; Magic Defense: 51
  db $36             ; Magic Evade: 54
  db $38             ; Accuracy: 56
  db $38             ; Evade: 56
  dw $2058           ; Weaknesses: Confusion, Sleep, Stone, Fire

; Enemy 026: Desert Hag
enemy_026_stats:
  dw $0118           ; HP: 280
  db $17             ; Attack: 23
  db $18             ; Defense: 24
  db $14             ; Speed: 20
  db $10             ; Magic: 16
  dw $2800           ; Resistances: Zombie, Fire
  db $10             ; Magic Defense: 16
  db $14             ; Magic Evade: 20
  db $1C             ; Accuracy: 28
  db $1A             ; Evade: 26
  dw $0820           ; Weaknesses: Paralysis, Zombie

; Enemy 027: Water Hag
enemy_027_stats:
  dw $02FD           ; HP: 765
  db $39             ; Attack: 57
  db $3C             ; Defense: 60
  db $3C             ; Speed: 60
  db $2D             ; Magic: 45
  dw $2840           ; Resistances: Stone, Zombie, Fire
  db $34             ; Magic Defense: 52
  db $35             ; Magic Evade: 53
  db $3F             ; Accuracy: 63
  db $36             ; Evade: 54
  dw $0820           ; Weaknesses: Paralysis, Zombie

; Enemy 028: Ninja
enemy_028_stats:
  dw $0244           ; HP: 580
  db $2C             ; Attack: 44
  db $2C             ; Defense: 44
  db $31             ; Speed: 49
  db $24             ; Magic: 36
  dw $1200           ; Resistances: Bomb, Air
  db $2E             ; Magic Defense: 46
  db $2D             ; Magic Evade: 45
  db $30             ; Accuracy: 48
  db $2E             ; Evade: 46
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 029: Shadow
enemy_029_stats:
  dw $039D           ; HP: 925
  db $46             ; Attack: 70
  db $43             ; Defense: 67
  db $4E             ; Speed: 78
  db $38             ; Magic: 56
  dw $1200           ; Resistances: Bomb, Air
  db $4E             ; Magic Defense: 78
  db $5A             ; Magic Evade: 90
  db $46             ; Accuracy: 70
  db $5C             ; Evade: 92
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 030: Sphinx
enemy_030_stats:
  dw $0168           ; HP: 360
  db $1B             ; Attack: 27
  db $20             ; Defense: 32
  db $1E             ; Speed: 30
  db $16             ; Magic: 22
  dw $0880           ; Resistances: Doom, Zombie
  db $19             ; Magic Defense: 25
  db $1D             ; Magic Evade: 29
  db $20             ; Accuracy: 32
  db $1E             ; Evade: 30
  dw $0000           ; Weaknesses: None

; Enemy 031: Manticor
enemy_031_stats:
  dw $0348           ; HP: 840
  db $3F             ; Attack: 63
  db $46             ; Defense: 70
  db $44             ; Speed: 68
  db $37             ; Magic: 55
  dw $48A0           ; Resistances: Paralysis, Doom, Zombie, Water
  db $3F             ; Magic Defense: 63
  db $42             ; Magic Evade: 66
  db $46             ; Accuracy: 70
  db $45             ; Evade: 69
  dw $0040           ; Weaknesses: Stone

; Enemy 032: Centaur
enemy_032_stats:
  dw $00E6           ; HP: 230
  db $11             ; Attack: 17
  db $12             ; Defense: 18
  db $16             ; Speed: 22
  db $0E             ; Magic: 14
  dw $1800           ; Resistances: Zombie, Air
  db $11             ; Magic Defense: 17
  db $12             ; Magic Evade: 18
  db $13             ; Accuracy: 19
  db $13             ; Evade: 19
  dw $0000           ; Weaknesses: None

; Enemy 033: Nitemare
enemy_033_stats:
  dw $0217           ; HP: 535
  db $28             ; Attack: 40
  db $2B             ; Defense: 43
  db $2E             ; Speed: 46
  db $23             ; Magic: 35
  dw $1820           ; Resistances: Paralysis, Zombie, Air
  db $35             ; Magic Defense: 53
  db $35             ; Magic Evade: 53
  db $35             ; Accuracy: 53
  db $38             ; Evade: 56
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 034: Stoney Roost
enemy_034_stats:
  dw $015E           ; HP: 350
  db $19             ; Attack: 25
  db $17             ; Defense: 23
  db $18             ; Speed: 24
  db $18             ; Magic: 24
  dw $4080           ; Resistances: Doom, Water
  db $1C             ; Magic Defense: 28
  db $16             ; Magic Evade: 22
  db $14             ; Accuracy: 20
  db $15             ; Evade: 21
  dw $8001           ; Weaknesses: Silence, Earth

; Enemy 035: Hot Wings
enemy_035_stats:
  dw $0249           ; HP: 585
  db $2B             ; Attack: 43
  db $2A             ; Defense: 42
  db $30             ; Speed: 48
  db $28             ; Magic: 40
  dw $00A0           ; Resistances: Paralysis, Doom
  db $30             ; Magic Defense: 48
  db $2E             ; Magic Evade: 46
  db $29             ; Accuracy: 41
  db $2E             ; Evade: 46
  dw $0211           ; Weaknesses: Silence, Sleep, Bomb

; Enemy 036: Ghost
enemy_036_stats:
  dw $0226           ; HP: 550
  db $27             ; Attack: 39
  db $25             ; Defense: 37
  db $28             ; Speed: 40
  db $26             ; Magic: 38
  dw $80C0           ; Resistances: Stone, Doom, Earth
  db $26             ; Magic Defense: 38
  db $26             ; Magic Evade: 38
  db $29             ; Accuracy: 41
  db $29             ; Evade: 41
  dw $1008           ; Weaknesses: Confusion, Air

; Enemy 037: Spector
enemy_037_stats:
  dw $02B2           ; HP: 690
  db $31             ; Attack: 49
  db $2F             ; Defense: 47
  db $34             ; Speed: 52
  db $2E             ; Magic: 46
  dw $80C0           ; Resistances: Stone, Doom, Earth
  db $35             ; Magic Defense: 53
  db $36             ; Magic Evade: 54
  db $2F             ; Accuracy: 47
  db $2F             ; Evade: 47
  dw $1019           ; Weaknesses: Silence, Confusion, Sleep, Air

; Enemy 038: Gather
enemy_038_stats:
  dw $0168           ; HP: 360
  db $18             ; Attack: 24
  db $1B             ; Defense: 27
  db $19             ; Speed: 25
  db $1A             ; Magic: 26
  dw $0800           ; Resistances: Zombie
  db $19             ; Magic Defense: 25
  db $1A             ; Magic Evade: 26
  db $1A             ; Accuracy: 26
  db $1B             ; Evade: 27
  dw $0052           ; Weaknesses: Blind, Sleep, Stone

; Enemy 039: Beholder
enemy_039_stats:
  dw $032A           ; HP: 810
  db $3D             ; Attack: 61
  db $3F             ; Defense: 63
  db $3C             ; Speed: 60
  db $39             ; Magic: 57
  dw $0800           ; Resistances: Zombie
  db $3C             ; Magic Defense: 60
  db $3E             ; Magic Evade: 62
  db $3D             ; Accuracy: 61
  db $3D             ; Evade: 61
  dw $0402           ; Weaknesses: Blind, Axe

; Enemy 040: Fangpire
enemy_040_stats:
  dw $0258           ; HP: 600
  db $2E             ; Attack: 46
  db $2C             ; Defense: 44
  db $30             ; Speed: 48
  db $28             ; Magic: 40
  dw $0000           ; Resistances: None
  db $31             ; Magic Defense: 49
  db $33             ; Magic Evade: 51
  db $33             ; Accuracy: 51
  db $2C             ; Evade: 44
  dw $0020           ; Weaknesses: Paralysis

; Enemy 041: Vampire
enemy_041_stats:
  dw $030C           ; HP: 780
  db $3B             ; Attack: 59
  db $39             ; Defense: 57
  db $3E             ; Speed: 62
  db $36             ; Magic: 54
  dw $0100           ; Resistances: Projectile
  db $3E             ; Magic Defense: 62
  db $41             ; Magic Evade: 65
  db $41             ; Accuracy: 65
  db $3B             ; Evade: 59
  dw $0011           ; Weaknesses: Silence, Sleep

; Enemy 042: Mage
enemy_042_stats:
  dw $014A           ; HP: 330
  db $15             ; Attack: 21
  db $0A             ; Defense: 10
  db $15             ; Speed: 21
  db $19             ; Magic: 25
  dw $0080           ; Resistances: Doom
  db $1E             ; Magic Defense: 30
  db $1A             ; Magic Evade: 26
  db $1A             ; Accuracy: 26
  db $10             ; Evade: 16
  dw $0020           ; Weaknesses: Paralysis

; Enemy 043: Sorcerer
enemy_043_stats:
  dw $0348           ; HP: 840
  db $3B             ; Attack: 59
  db $38             ; Defense: 56
  db $46             ; Speed: 70
  db $41             ; Magic: 65
  dw $0080           ; Resistances: Doom
  db $55             ; Magic Defense: 85
  db $48             ; Magic Evade: 72
  db $38             ; Accuracy: 56
  db $38             ; Evade: 56
  dw $0011           ; Weaknesses: Silence, Sleep

; Enemy 044: Land Turtle
enemy_044_stats:
  dw $010E           ; HP: 270
  db $14             ; Attack: 20
  db $20             ; Defense: 32
  db $10             ; Speed: 16
  db $10             ; Magic: 16
  dw $2000           ; Resistances: Fire
  db $18             ; Magic Defense: 24
  db $11             ; Magic Evade: 17
  db $14             ; Accuracy: 20
  db $10             ; Evade: 16
  dw $0054           ; Weaknesses: Poison, Sleep, Stone

; Enemy 045: Sea Turtle
enemy_045_stats:
  dw $0276           ; HP: 630
  db $2F             ; Attack: 47
  db $46             ; Defense: 70
  db $2C             ; Speed: 44
  db $28             ; Magic: 40
  dw $2020           ; Resistances: Paralysis, Fire
  db $36             ; Magic Defense: 54
  db $34             ; Magic Evade: 52
  db $36             ; Accuracy: 54
  db $2C             ; Evade: 44
  dw $0084           ; Weaknesses: Poison, Doom

; Enemy 046: Stone Man
enemy_046_stats:
  dw $00D2           ; HP: 210
  db $10             ; Attack: 16
  db $10             ; Defense: 16
  db $12             ; Speed: 18
  db $10             ; Magic: 16
  dw $0400           ; Resistances: Axe
  db $0C             ; Magic Defense: 12
  db $0D             ; Magic Evade: 13
  db $12             ; Accuracy: 18
  db $0D             ; Evade: 13
  dw $0020           ; Weaknesses: Paralysis

; Enemy 047: Lizard Man
enemy_047_stats:
  dw $02B2           ; HP: 690
  db $33             ; Attack: 51
  db $37             ; Defense: 55
  db $38             ; Speed: 56
  db $34             ; Magic: 52
  dw $0400           ; Resistances: Axe
  db $34             ; Magic Defense: 52
  db $36             ; Magic Evade: 54
  db $37             ; Accuracy: 55
  db $34             ; Evade: 52
  dw $0020           ; Weaknesses: Paralysis

; Enemy 048: Wasp
enemy_048_stats:
  dw $022B           ; HP: 555
  db $29             ; Attack: 41
  db $2D             ; Defense: 45
  db $2C             ; Speed: 44
  db $26             ; Magic: 38
  dw $0800           ; Resistances: Zombie
  db $2E             ; Magic Defense: 46
  db $2C             ; Magic Evade: 44
  db $2D             ; Accuracy: 45
  db $28             ; Evade: 40
  dw $0040           ; Weaknesses: Stone

; Enemy 049: Fly Eye
enemy_049_stats:
  dw $03A7           ; HP: 935
  db $46             ; Attack: 70
  db $47             ; Defense: 71
  db $48             ; Speed: 72
  db $40             ; Magic: 64
  dw $4800           ; Resistances: Zombie, Water
  db $4C             ; Magic Defense: 76
  db $48             ; Magic Evade: 72
  db $4A             ; Accuracy: 74
  db $46             ; Evade: 70
  dw $8020           ; Weaknesses: Paralysis, Earth

; Enemy 050: Minotaur
enemy_050_stats:
  dw $00DC           ; HP: 220
  db $11             ; Attack: 17
  db $15             ; Defense: 21
  db $13             ; Speed: 19
  db $0A             ; Magic: 10
  dw $2200           ; Resistances: Bomb, Fire
  db $0A             ; Magic Defense: 10
  db $0C             ; Magic Evade: 12
  db $14             ; Accuracy: 20
  db $10             ; Evade: 16
  dw $0020           ; Weaknesses: Paralysis

; Enemy 051: Medusa
enemy_051_stats:
  dw $01A4           ; HP: 420
  db $21             ; Attack: 33
  db $28             ; Defense: 40
  db $24             ; Speed: 36
  db $1C             ; Magic: 28
  dw $2400           ; Resistances: Axe, Fire
  db $1C             ; Magic Defense: 28
  db $1E             ; Magic Evade: 30
  db $22             ; Accuracy: 34
  db $20             ; Evade: 32
  dw $0040           ; Weaknesses: Stone

; Enemy 052: Ice Golem
enemy_052_stats:
  dw $012C           ; HP: 300
  db $15             ; Attack: 21
  db $12             ; Defense: 18
  db $12             ; Speed: 18
  db $14             ; Magic: 20
  dw $1800           ; Resistances: Zombie, Air
  db $19             ; Magic Defense: 25
  db $18             ; Magic Evade: 24
  db $18             ; Accuracy: 24
  db $12             ; Evade: 18
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 053: Fire Golem
enemy_053_stats:
  dw $0366           ; HP: 870
  db $41             ; Attack: 65
  db $41             ; Defense: 65
  db $43             ; Speed: 67
  db $3C             ; Magic: 60
  dw $1800           ; Resistances: Zombie, Air
  db $47             ; Magic Defense: 71
  db $45             ; Magic Evade: 69
  db $40             ; Accuracy: 64
  db $43             ; Evade: 67
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 054: Jinn
enemy_054_stats:
  dw $029A           ; HP: 666
  db $31             ; Attack: 49
  db $34             ; Defense: 52
  db $34             ; Speed: 52
  db $26             ; Magic: 38
  dw $0180           ; Resistances: Doom, Projectile
  db $2C             ; Magic Defense: 44
  db $2C             ; Magic Evade: 44
  db $35             ; Accuracy: 53
  db $2C             ; Evade: 44
  dw $0111           ; Weaknesses: Silence, Sleep, Projectile

; Enemy 055: Cockatrice
enemy_055_stats:
  dw $0378           ; HP: 888
  db $42             ; Attack: 66
  db $49             ; Defense: 73
  db $46             ; Speed: 70
  db $3A             ; Magic: 58
  dw $01C0           ; Resistances: Stone, Doom, Projectile
  db $3F             ; Magic Defense: 63
  db $40             ; Magic Evade: 64
  db $46             ; Accuracy: 70
  db $40             ; Evade: 64
  dw $0111           ; Weaknesses: Silence, Sleep, Projectile

; Enemy 056: Thunder Eye
enemy_056_stats:
  dw $0096           ; HP: 150
  db $0B             ; Attack: 11
  db $0B             ; Defense: 11
  db $0C             ; Speed: 12
  db $08             ; Magic: 8
  dw $0000           ; Resistances: None
  db $0C             ; Magic Defense: 12
  db $0E             ; Magic Evade: 14
  db $0F             ; Accuracy: 15
  db $0D             ; Evade: 13
  dw $0000           ; Weaknesses: None

; Enemy 057: Doom Eye
enemy_057_stats:
  dw $00BE           ; HP: 190
  db $0D             ; Attack: 13
  db $0D             ; Defense: 13
  db $0D             ; Speed: 13
  db $0A             ; Magic: 10
  dw $0000           ; Resistances: None
  db $0F             ; Magic Defense: 15
  db $0D             ; Magic Evade: 13
  db $0D             ; Accuracy: 13
  db $0F             ; Evade: 15
  dw $0008           ; Weaknesses: Confusion

; Enemy 058: Succubus
enemy_058_stats:
  dw $0190           ; HP: 400
  db $1E             ; Attack: 30
  db $1B             ; Defense: 27
  db $1D             ; Speed: 29
  db $18             ; Magic: 24
  dw $0050           ; Resistances: Sleep, Stone
  db $21             ; Magic Defense: 33
  db $20             ; Magic Evade: 32
  db $22             ; Accuracy: 34
  db $23             ; Evade: 35
  dw $0020           ; Weaknesses: Paralysis

; Enemy 059: Freeze Crab
enemy_059_stats:
  dw $019A           ; HP: 410
  db $1F             ; Attack: 31
  db $28             ; Defense: 40
  db $20             ; Speed: 32
  db $1C             ; Magic: 28
  dw $0000           ; Resistances: None
  db $1E             ; Magic Defense: 30
  db $1E             ; Magic Evade: 30
  db $22             ; Accuracy: 34
  db $1F             ; Evade: 31
  dw $0804           ; Weaknesses: Poison, Zombie

; Enemy 060: Gemini Crest (L)
enemy_060_stats:
  dw $0294           ; HP: 660
  db $32             ; Attack: 50
  db $31             ; Defense: 49
  db $32             ; Speed: 50
  db $2D             ; Magic: 45
  dw $0C20           ; Resistances: Paralysis, Axe, Zombie
  db $33             ; Magic Defense: 51
  db $33             ; Magic Evade: 51
  db $38             ; Accuracy: 56
  db $38             ; Evade: 56
  dw $0040           ; Weaknesses: Stone

; Enemy 061: Gemini Crest (R)
enemy_061_stats:
  dw $0276           ; HP: 630
  db $2F             ; Attack: 47
  db $30             ; Defense: 48
  db $33             ; Speed: 51
  db $2B             ; Magic: 43
  dw $6400           ; Resistances: Axe, Fire, Water
  db $38             ; Magic Defense: 56
  db $36             ; Magic Evade: 54
  db $35             ; Accuracy: 53
  db $33             ; Evade: 51
  dw $8080           ; Weaknesses: Doom, Earth

; Enemy 062: Pazuzu
enemy_062_stats:
  dw $0366           ; HP: 870
  db $41             ; Attack: 65
  db $42             ; Defense: 66
  db $45             ; Speed: 69
  db $3A             ; Magic: 58
  dw $E720           ; Resistances: Paralysis, Projectile, Bomb, Axe, Fire, Water, Earth
  db $47             ; Magic Defense: 71
  db $46             ; Magic Evade: 70
  db $45             ; Accuracy: 69
  db $43             ; Evade: 67
  dw $4011           ; Weaknesses: Silence, Sleep, Water

; Enemy 063: Sky Beast
enemy_063_stats:
  dw $0384           ; HP: 900
  db $43             ; Attack: 67
  db $44             ; Defense: 68
  db $44             ; Speed: 68
  db $39             ; Magic: 57
  dw $3000           ; Resistances: Air, Fire
  db $43             ; Magic Defense: 67
  db $42             ; Magic Evade: 66
  db $46             ; Accuracy: 70
  db $41             ; Evade: 65
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 064: Captain
enemy_064_stats:
  dw $2710           ; HP: 10000
  db $0A             ; Attack: 10
  db $B4             ; Defense: 180
  db $62             ; Speed: 98
  db $60             ; Magic: 96
  dw $0000           ; Resistances: None
  db $E6             ; Magic Defense: 230
  db $55             ; Magic Evade: 85
  db $5A             ; Accuracy: 90
  db $5B             ; Evade: 91
  dw $0008           ; Weaknesses: Confusion

; Enemy 065: Hydra
enemy_065_stats:
  dw $2710           ; HP: 10000
  db $05             ; Attack: 5
  db $62             ; Defense: 98
  db $63             ; Speed: 99
  db $62             ; Magic: 98
  dw $F4A0           ; Resistances: Paralysis, Doom, Axe, Air, Fire, Water, Earth
  db $5A             ; Magic Defense: 90
  db $58             ; Magic Evade: 88
  db $5D             ; Accuracy: 93
  db $58             ; Evade: 88
  dw $0000           ; Weaknesses: None

; Enemy 066: Squid Eye
enemy_066_stats:
  dw $0050           ; HP: 80
  db $01             ; Attack: 1
  db $19             ; Defense: 25
  db $0C             ; Speed: 12
  db $01             ; Magic: 1
  dw $0000           ; Resistances: None
  db $01             ; Magic Defense: 1
  db $01             ; Magic Evade: 1
  db $05             ; Accuracy: 5
  db $01             ; Evade: 1
  dw $0000           ; Weaknesses: None

; Enemy 067: Libra Crest
enemy_067_stats:
  dw $00F0           ; HP: 240
  db $04             ; Attack: 4
  db $32             ; Defense: 50
  db $0C             ; Speed: 12
  db $08             ; Magic: 8
  dw $0000           ; Resistances: None
  db $0A             ; Magic Defense: 10
  db $08             ; Magic Evade: 8
  db $0F             ; Accuracy: 15
  db $07             ; Evade: 7
  dw $0000           ; Weaknesses: None

; Enemy 068: Dullahan
enemy_068_stats:
  dw $09C4           ; HP: 2500
  db $32             ; Attack: 50
  db $32             ; Defense: 50
  db $1E             ; Speed: 30
  db $1F             ; Magic: 31
  dw $F080           ; Resistances: Doom, Air, Fire, Water, Earth
  db $B4             ; Magic Defense: 180
  db $22             ; Magic Evade: 34
  db $28             ; Accuracy: 40
  db $21             ; Evade: 33
  dw $0000           ; Weaknesses: None

; Enemy 069: Dark Lord
enemy_069_stats:
  dw $0BB8           ; HP: 3000
  db $64             ; Attack: 100
  db $32             ; Defense: 50
  db $22             ; Speed: 34
  db $20             ; Magic: 32
  dw $F400           ; Resistances: Axe, Air, Fire, Water, Earth
  db $96             ; Magic Defense: 150
  db $1E             ; Magic Evade: 30
  db $3C             ; Accuracy: 60
  db $1E             ; Evade: 30
  dw $0004           ; Weaknesses: Poison

; Enemy 070: Twinhead Wyvern
enemy_070_stats:
  dw $1770           ; HP: 6000
  db $73             ; Attack: 115
  db $3A             ; Defense: 58
  db $34             ; Speed: 52
  db $73             ; Magic: 115
  dw $F120           ; Resistances: Paralysis, Projectile, Air, Fire, Water, Earth
  db $C8             ; Magic Defense: 200
  db $32             ; Magic Evade: 50
  db $50             ; Accuracy: 80
  db $28             ; Evade: 40
  dw $0200           ; Weaknesses: Bomb

; Enemy 071: Lamia
enemy_071_stats:
  dw $1964           ; HP: 6500
  db $64             ; Attack: 100
  db $38             ; Defense: 56
  db $3E             ; Speed: 62
  db $44             ; Magic: 68
  dw $F550           ; Resistances: Sleep, Stone, Projectile, Axe, Air, Fire, Water, Earth
  db $A0             ; Magic Defense: 160
  db $41             ; Magic Evade: 65
  db $58             ; Accuracy: 88
  db $3E             ; Evade: 62
  dw $0000           ; Weaknesses: None

; Enemy 072: Gargoyle
enemy_072_stats:
  dw $32C8           ; HP: 13000
  db $82             ; Attack: 130
  db $4B             ; Defense: 75
  db $4E             ; Speed: 78
  db $50             ; Magic: 80
  dw $F620           ; Resistances: Paralysis, Bomb, Axe, Air, Fire, Water, Earth
  db $DC             ; Magic Defense: 220
  db $4B             ; Magic Evade: 75
  db $5A             ; Accuracy: 90
  db $4B             ; Evade: 75
  dw $4210           ; Weaknesses: Sleep, Bomb, Water

; Enemy 073: Gargoyle Statue
enemy_073_stats:
  dw $36B0           ; HP: 14000
  db $A0             ; Attack: 160
  db $55             ; Defense: 85
  db $48             ; Speed: 72
  db $53             ; Magic: 83
  dw $C020           ; Resistances: Paralysis, Water, Earth
  db $55             ; Magic Defense: 85
  db $50             ; Magic Evade: 80
  db $5D             ; Accuracy: 93
  db $4E             ; Evade: 78
  dw $0200           ; Weaknesses: Bomb

; Enemy 074: Dullahan (Phoebe)
enemy_074_stats:
  dw $0898           ; HP: 2200
  db $46             ; Attack: 70
  db $3C             ; Defense: 60
  db $20             ; Speed: 32
  db $1C             ; Magic: 28
  dw $E400           ; Resistances: Axe, Fire, Water, Earth
  db $64             ; Magic Defense: 100
  db $4B             ; Magic Evade: 75
  db $58             ; Accuracy: 88
  db $46             ; Evade: 70
  dw $0008           ; Weaknesses: Confusion

; Enemy 075: Dark Lord (Phoebe)
enemy_075_stats:
  dw $1964           ; HP: 6500
  db $50             ; Attack: 80
  db $30             ; Defense: 48
  db $29             ; Speed: 41
  db $30             ; Magic: 48
  dw $FCC0           ; Resistances: Stone, Doom, Axe, Zombie, Air, Fire, Water, Earth
  db $B4             ; Magic Defense: 180
  db $48             ; Magic Evade: 72
  db $62             ; Accuracy: 98
  db $58             ; Evade: 88
  dw $0020           ; Weaknesses: Paralysis

; Enemy 076: Medusa (Quest)
enemy_076_stats:
  dw $36B0           ; HP: 14000
  db $7D             ; Attack: 125
  db $91             ; Defense: 145
  db $3C             ; Speed: 60
  db $73             ; Magic: 115
  dw $FD20           ; Resistances: Paralysis, Projectile, Axe, Zombie, Air, Fire, Water, Earth
  db $62             ; Magic Defense: 98
  db $50             ; Magic Evade: 80
  db $5D             ; Accuracy: 93
  db $55             ; Evade: 85
  dw $0000           ; Weaknesses: None

; Enemy 077: Stone Golem
enemy_077_stats:
  dw $3A98           ; HP: 15000
  db $EB             ; Attack: 235
  db $5A             ; Defense: 90
  db $6C             ; Speed: 108
  db $FA             ; Magic: 250
  dw $FC20           ; Resistances: Paralysis, Axe, Zombie, Air, Fire, Water, Earth
  db $96             ; Magic Defense: 150
  db $5D             ; Magic Evade: 93
  db $5A             ; Accuracy: 90
  db $5A             ; Evade: 90
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 078: Gorgon Bull
enemy_078_stats:
  dw $61A8           ; HP: 25000
  db $6E             ; Attack: 110
  db $5F             ; Defense: 95
  db $4E             ; Speed: 78
  db $5D             ; Magic: 93
  dw $FE80           ; Resistances: Doom, Bomb, Axe, Zombie, Air, Fire, Water, Earth
  db $5A             ; Magic Defense: 90
  db $5C             ; Magic Evade: 92
  db $5F             ; Accuracy: 95
  db $5A             ; Evade: 90
  dw $0011           ; Weaknesses: Silence, Sleep

; Enemy 079: Minotaur (Quest)
enemy_079_stats:
  dw $4E20           ; HP: 20000
  db $F0             ; Attack: 240
  db $5F             ; Defense: 95
  db $64             ; Speed: 100
  db $62             ; Magic: 98
  dw $FE80           ; Resistances: Doom, Bomb, Axe, Zombie, Air, Fire, Water, Earth
  db $B4             ; Magic Defense: 180
  db $5A             ; Magic Evade: 90
  db $5D             ; Accuracy: 93
  db $5B             ; Evade: 91
  dw $0011           ; Weaknesses: Silence, Sleep

; Enemy 080: Skullrus Rex
enemy_080_stats:
  dw $9C40           ; HP: 40000
  db $32             ; Attack: 50
  db $78             ; Defense: 120
  db $56             ; Speed: 86
  db $4B             ; Magic: 75
  dw $FFD0           ; Resistances: Sleep, Stone, Doom, Projectile, Bomb, Axe, Zombie, Air, Fire, Water, Earth
  db $A0             ; Magic Defense: 160
  db $46             ; Magic Evade: 70
  db $61             ; Accuracy: 97
  db $50             ; Evade: 80
  dw $0000           ; Weaknesses: None

; Enemy 081: Dark King (Phase 1)
enemy_081_stats:
  dw $0190           ; HP: 400
  db $28             ; Attack: 40
  db $1E             ; Defense: 30
  db $14             ; Speed: 20
  db $0A             ; Magic: 10
  dw $C0A0           ; Resistances: Paralysis, Doom, Water, Earth
  db $32             ; Magic Defense: 50
  db $32             ; Magic Evade: 50
  db $50             ; Accuracy: 80
  db $28             ; Evade: 40
  dw $0050           ; Weaknesses: Sleep, Stone

; Enemy 082: Dark King Spider
enemy_082_stats:
  dw $0190           ; HP: 400
  db $28             ; Attack: 40
  db $1E             ; Defense: 30
  db $14             ; Speed: 20
  db $0A             ; Magic: 10
  dw $C0A0           ; Resistances: Paralysis, Doom, Water, Earth
  db $32             ; Magic Defense: 50
  db $32             ; Magic Evade: 50
  db $50             ; Accuracy: 80
  db $28             ; Evade: 40
  dw $0050           ; Weaknesses: Sleep, Stone
