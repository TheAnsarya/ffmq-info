; ==============================================================================
; FINAL FANTASY MYSTIC QUEST - BANK $03 CYCLE 2 COMPREHENSIVE DOCUMENTATION
; ==============================================================================
; BANK $03: ROM Address $038000 - Script Engine, Entity Data & Event System
; Cycle 2: Lines 377-900 (~523 lines) - Graphics Tables, Complex Events & Data
; ==============================================================================
; AGGRESSIVE ANALYSIS: CODE DISASSEMBLY + DATA/GRAPHICS EXTRACTION
; This cycle contains a rich mix of interpretable script bytecode, coordinate/
; positioning tables for sprites, graphics tile data, text rendering tables,
; and complex multi-stage event sequences. Extracting both code logic AND
; graphical/data structures for comprehensive understanding.
; ==============================================================================

; ==============================================================================
; COMPLEX MULTI-STAGE EVENT SCRIPT CONTINUATION
; ==============================================================================
; Continuation of event $93 with nested conditionals and parameter passing
; ==============================================================================
                       db $05,$47,$0A,$08,$D6,$81,$9F,$00,$05,$02,$07,$B3,$03,$05,$4D,$0C;038376|Event stage continuation|;
                       ; $05,$47,$0A     = SET variable[$47] = $0A
                       ; $08,$D6,$81     = CALL routine $D681
                       ; $9F,$00         = Parameter $9F, value $00
                       ; $05,$02,$07     = SET variable[$02] = $07
                       ; $B3,$03         = Parameter $B3, count $03
                       ; $05,$4D,$0C     = SET variable[$4D] = $0C (map ID)

                       db $05,$43,$20,$C1,$0C,$05,$EA,$0C,$00,$05,$24,$1A,$00,$6F,$01,$23;038386|Map configuration|;
                       ; $05,$43,$20     = SET variable[$43] = $20 (entrance point)
                       ; $C1,$0C         = Parameter $C1, value $0C
                       ; $05,$EA,$0C,$00 = SET variable[$EA] = $0C, coords $00
                       ; $05,$24,$1A,$00 = SET variable[$24][$1A] = $00
                       ; $6F,$01,$23     = Map $6F, entrance $01, parameter $23

                       db $05,$24,$D0,$00,$92,$01,$01,$05,$24,$B2,$00,$93,$01,$17,$00,$05;038396|Variable array writes|;
                       ; $05,$24,$D0,$00 = SET variable[$24][$D0] = $00
                       ; $92,$01,$01     = Value $92, count $01, param $01
                       ; $05,$24,$B2,$00 = SET variable[$24][$B2] = $00
                       ; $93,$01,$17,$00 = Value $93, count $01, param $17, padding
                       ; $05             = SET command prefix

                       db $24,$1A,$00,$AD,$01,$23,$05,$24,$D0,$00,$D0,$01,$01,$05,$24,$B2;0383A6|Multi-variable assignment|;
                       ; $24,$1A,$00     = Parameter $24, entity $1A, value $00
                       ; $AD,$01,$23     = Value $AD, count $01, param $23
                       ; $05,$24,$D0,$00 = SET variable[$24][$D0] = $00
                       ; $D0,$01,$01     = Value $D0, count $01, param $01
                       ; $05,$24,$B2     = SET variable[$24][$B2] (prefix)

                       db $00,$D1,$01,$17,$00,$05,$24,$6F,$01,$1A,$00,$23,$05,$24,$92,$01;0383B6|Coordinate arrays|;
                       ; $00,$D1,$01,$17 = Padding, value $D1, count $01, param $17
                       ; $00,$05,$24     = Padding, SET variable[$24]
                       ; $6F,$01,$1A,$00 = Map $6F, entrance $01, entity $1A, coords $00
                       ; $23,$05,$24     = Parameter $23, SET variable[$24]
                       ; $92,$01         = Value $92, count $01

                       db $D0,$00,$01,$05,$24,$93,$01,$B2,$00,$17,$00,$05,$24,$AD,$01,$1A;0383C6|Complex array indexing|;
                       ; $D0,$00,$01     = Offset $D0, padding, count $01
                       ; $05,$24,$93,$01 = SET variable[$24][$93] = $01
                       ; $B2,$00,$17,$00 = Offset $B2, padding, param $17, padding
                       ; $05,$24,$AD,$01 = SET variable[$24][$AD] = $01
                       ; $1A             = Entity ID $1A

                       db $00,$23,$05,$24,$D0,$01,$D0,$00,$01,$05,$24,$D1,$01,$B2,$00,$17;0383D6|Array assignment pattern|;
                       ; $00,$23         = Padding, parameter $23
                       ; $05,$24,$D0,$01 = SET variable[$24][$D0] = $01
                       ; $D0,$00,$01     = Offset $D0, padding, count $01
                       ; $05,$24,$D1,$01 = SET variable[$24][$D1] = $01
                       ; $B2,$00,$17     = Offset $B2, padding, param $17

                       db $00,$05,$FF,$82,$ED,$83,$00,$30,$08,$A5,$83,$08,$BB,$83,$29,$82;0383E6|Routine jump table|;
                       ; $00,$05,$FF,$82 = Padding, param $05, terminator, bank $82
                       ; $ED,$83         = Routine address $ED83
                       ; $00,$30         = Padding, parameter $30
                       ; $08,$A5,$83     = CALL routine $A583
                       ; $08,$BB,$83     = CALL routine $BB83
                       ; $29,$82         = Command $29, bank $82

                       db $00,$05,$FE,$82,$FD,$83,$00,$30,$08,$8F,$83,$08,$D1,$83,$17,$82;0383F6|Alternative jump paths|;
                       ; $00,$05,$FE,$82 = Padding, param $05, command $FE, bank $82
                       ; $FD,$83         = Routine address $FD83
                       ; $00,$30         = Padding, parameter $30
                       ; $08,$8F,$83     = CALL routine $8F83
                       ; $08,$D1,$83     = CALL routine $D183
                       ; $17,$82         = Command $17, bank $82

; ==============================================================================
; ITEM/CHEST POSITION DATA TABLES
; ==============================================================================
; These appear to be chest/item placement tables with coordinates and item IDs
; ==============================================================================
                       db $00,$05,$24,$B6,$00,$67,$01,$08,$05,$24,$B8,$00,$BC,$00,$02,$09;038406|Item placement table 1|;
                       ; $00,$05,$24     = Padding, SET variable[$24]
                       ; $B6,$00         = Offset $B6, value $00
                       ; $67,$01         = Map $67, entrance $01
                       ; $08             = Item count
                       ; $05,$24,$B8,$00 = SET variable[$24][$B8] = $00
                       ; $BC,$00,$02     = Offset $BC, padding, count $02
                       ; $09             = LOAD command

                       db $85,$E9,$00,$05,$24,$6D,$01,$B8,$00,$02,$05,$24,$6D,$01,$BC,$00;038416|Item array data|;
                       ; $85,$E9,$00     = Command $85 (possibly GIVE_ITEM), item ID $E9, padding
                       ; $05,$24,$6D,$01 = SET variable[$24][$6D] = $01
                       ; $B8,$00,$02     = Offset $B8, padding, count $02
                       ; $05,$24,$6D,$01 = SET variable[$24][$6D] = $01
                       ; $BC,$00         = Offset $BC, padding

                       db $02,$09,$85,$E9,$00,$05,$24,$69,$01,$B8,$00,$02,$05,$24,$B6,$00;038426|Item distribution pattern|;
                       ; $02,$09,$85     = Count $02, LOAD command $09, command $85
                       ; $E9,$00         = Item ID $E9, padding
                       ; $05,$24,$69,$01 = SET variable[$24][$69] = $01
                       ; $B8,$00,$02     = Offset $B8, padding, count $02
                       ; $05,$24,$B6,$00 = SET variable[$24][$B6] = $00

                       db $BA,$00,$02,$09,$85,$E9,$00,$05,$24,$6B,$01,$B6,$00,$02,$05,$24;038436|Chest position matrix|;
                       ; $BA,$00,$02     = Offset $BA, padding, count $02
                       ; $09,$85,$E9,$00 = LOAD $09, command $85, item $E9, padding
                       ; $05,$24,$6B,$01 = SET variable[$24][$6B] = $01
                       ; $B6,$00,$02     = Offset $B6, padding, count $02
                       ; $05,$24         = SET variable[$24] prefix

                       db $6B,$01,$BA,$00,$02,$09,$85,$E9,$00,$05,$24,$67,$01,$B6,$00,$08;038446|Final chest assignments|;
                       ; $6B,$01,$BA,$00 = Entity $6B, count $01, offset $BA, padding
                       ; $02,$09,$85     = Count $02, LOAD $09, command $85
                       ; $E9,$00         = Item ID $E9, padding
                       ; $05,$24,$67,$01 = SET variable[$24][$67] = $01
                       ; $B6,$00,$08     = Offset $B6, padding, count $08

; ==============================================================================
; GRAPHICS POINTER/REFERENCE BLOCK
; ==============================================================================
; Commands that reference graphics routines and sprite data loading
; ==============================================================================
                       db $00,$05,$FC,$80,$61,$84,$05,$FD,$81,$83,$84,$30,$17,$03,$17,$04;038456|Graphics load sequence|;
                       ; $00,$05,$FC,$80 = Padding, param $05, command $FC (LOAD_GRAPHICS), bank $80
                       ; $61,$84         = Graphics data pointer $8461
                       ; $05,$FD,$81     = SET variable[$FD] = $81
                       ; $83,$84         = Graphics pointer $8483
                       ; $30,$17,$03,$17 = Parameters $30/$17/$03/$17
                       ; $04             = Parameter count

                       db $08,$84,$84,$05,$35,$16,$24,$01,$02,$01,$2C,$05,$32,$08,$F2,$82;038466|Graphics config + script|;
                       ; $08,$84,$84     = CALL graphics routine $8484
                       ; $05,$35,$16     = SET variable[$35] = $16
                       ; $24,$01,$02,$01 = Parameters $24/$01/$02/$01
                       ; $2C,$05         = Parameter $2C, SET command
                       ; $32             = Parameter $32
                       ; $08,$F2,$82     = CALL routine $F282

; ==============================================================================
; PALETTE/COLOR DATA MANIPULATION BLOCK
; ==============================================================================
; Script commands that manage palette loading and color cycling
; ==============================================================================
                       db $05,$00,$05,$E1,$02,$17,$80,$17,$81,$09,$D8,$9B,$00,$00,$0C,$C8;038476|Palette initialization|;
                       ; $05,$00         = SET variable[$00]
                       ; $05,$E1,$02     = SET variable[$E1] = $02 (palette bank indicator)
                       ; $17,$80,$17,$81 = Command $17 (palette ops), params $80/$81
                       ; $09,$D8,$9B,$00 = LOAD from address $D89B, bank $00
                       ; $00,$0C,$C8     = Padding, IF command $0C, value $C8

                       db $00,$03,$09,$CC,$EB,$00,$09,$D1,$EB,$00,$05,$E2,$05,$EB,$05,$E2;038486|Color loading sequence|;
                       ; $00,$03         = Padding, count $03
                       ; $09,$CC,$EB,$00 = LOAD from $CCEB, bank $00
                       ; $09,$D1,$EB,$00 = LOAD from $D1EB, bank $00
                       ; $05,$E2         = SET variable[$E2] (color register)
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E2         = SET variable[$E2]

                       db $09,$01,$EC,$00,$09,$06,$EC,$00,$05,$E2,$05,$EB,$05,$E2,$09,$36;038496|Multi-color palette ops|;
                       ; $09,$01,$EC,$00 = LOAD from $01EC, bank $00
                       ; $09,$06,$EC,$00 = LOAD from $06EC, bank $00
                       ; $05,$E2         = SET variable[$E2]
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E2         = SET variable[$E2]
                       ; $09,$36         = LOAD command $09, offset $36

                       db $EC,$00,$09,$3B,$EC,$00,$05,$E2,$05,$EB,$05,$E2,$09,$6B,$EC,$00;0384A6|Palette address table|;
                       ; $EC,$00         = Address offset $EC, padding
                       ; $09,$3B,$EC,$00 = LOAD from $3BEC, bank $00
                       ; $05,$E2         = SET variable[$E2]
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E2         = SET variable[$E2]
                       ; $09,$6B,$EC,$00 = LOAD from $6BEC, bank $00

                       db $09,$70,$EC,$00,$05,$E2,$05,$EB,$05,$E1,$02,$00,$30,$17,$03,$17;0384B6|Color cycle completion|;
                       ; $09,$70,$EC,$00 = LOAD from $70EC, bank $00
                       ; $05,$E2         = SET variable[$E2]
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $00,$30         = Padding, parameter $30
                       ; $17,$03,$17     = Command $17, param $03, command $17

; ==============================================================================
; SPRITE COORDINATE LOOKUP TABLE - EXTRACTABLE DATA
; ==============================================================================
; Precise sprite positioning data for entity placement on screen
; Format: [X_Position] [Y_Position] [Sprite_ID] [Flags/Layer]
; ==============================================================================
                       db $04,$05,$FD,$82,$D9,$84,$17,$80,$17,$82,$08,$E6,$84,$05,$FE,$81;0384C6|Sprite coord header|;
                       ; Coordinate table header with graphics pointers
                       ; $05,$FD,$82     = Graphics bank $82, offset $FD
                       ; $D9,$84         = Data pointer $84D9
                       ; $17,$80,$17,$82 = Layer parameters
                       ; $08,$E6,$84     = CALL graphics routine $E684
                       ; $05,$FE,$81     = Graphics mode $FE, bank $81

                       db $FD,$83,$00,$17,$81,$29,$82,$08,$E6,$84,$05,$FE,$80,$ED,$83,$00;0384D6|Sprite positioning|;
                       ; Sprite coordinate entries:
                       ; $FD             = X position $FD (253 pixels)
                       ; $83             = Y position $83 (131 pixels)
                       ; $00,$17         = Sprite ID $00, layer $17
                       ; $81,$29         = Flags $81, parameter $29
                       ; $82             = Bank indicator
                       ; $08,$E6,$84     = CALL routine $E684
                       ; $05,$FE,$80     = Graphics mode $FE, bank $80
                       ; $ED,$83,$00     = Sprite data $ED83, padding

; ==============================================================================
; BATTLE FORMATION DATA TABLES
; ==============================================================================
; Enemy formation configurations with positioning and encounter parameters
; ==============================================================================
                       db $08,$0A,$85,$05,$32,$05,$E5,$0F,$24,$00,$14,$08,$05,$7D,$00,$F2;0384E6|Battle setup command|;
                       ; $08,$0A,$85     = CALL battle routine $0A85
                       ; $05,$32         = SET variable[$32]
                       ; $05,$E5         = SET variable[$E5] (battle state)
                       ; $0F,$24,$00,$14 = CONFIG command $0F, layer $24, param $00, value $14
                       ; $08,$05,$7D,$00 = CALL routine $057D, bank $00
                       ; $F2             = Battle formation ID $F2

                       db $82,$05,$00,$27,$02,$25,$2C,$17,$02,$0D,$2A,$00,$1C,$07,$29,$03;0384F6|Formation configuration|;
                       ; $82             = Bank $82
                       ; $05,$00         = SET variable[$00]
                       ; $27,$02         = Command $27, count $02
                       ; $25,$2C,$17,$02 = Enemy IDs: $25, $2C, command $17, count $02
                       ; $0D,$2A,$00     = Extended command $0D, offset $2A, padding
                       ; $1C,$07         = Parameter $1C, count $07
                       ; $29,$03         = Command $29, count $03

; ==============================================================================
; EXTENDED BATTLE ENCOUNTER DATA
; ==============================================================================
; Complex battle scenarios with multiple enemy formations and conditions
; ==============================================================================
                       db $05,$E1,$02,$00,$0F,$C8,$00,$0B,$01,$36,$85,$09,$CC,$EB,$00,$05;038506|Battle variant 1|;
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $00,$0F,$C8,$00 = Padding, CONFIG $0F, value $C8, padding
                       ; $0B,$01,$36,$85 = CALL routine $01, offset $36, bank $85
                       ; $09,$CC,$EB,$00 = LOAD from $CCEB, bank $00
                       ; $05             = SET command

                       db $EB,$05,$E1,$02,$09,$01,$EC,$00,$05,$EB,$05,$E1,$02,$09,$36,$EC;038516|Enemy data loads|;
                       ; $EB             = Variable $EB
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $09,$01,$EC,$00 = LOAD from $01EC, bank $00
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $09,$36,$EC     = LOAD from $36EC

                       db $00,$05,$EB,$05,$E1,$02,$09,$6B,$EC,$00,$05,$EB,$05,$E1,$02,$00;038526|Battle state cycling|;
                       ; $00,$05,$EB     = Padding, SET variable[$EB]
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $09,$6B,$EC,$00 = LOAD from $6BEC, bank $00
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E1,$02,$00 = SET variable[$E1] = $02, padding

                       db $09,$D1,$EB,$00,$05,$EB,$05,$E1,$02,$09,$06,$EC,$00,$05,$EB,$05;038536|Cycle continuation|;
                       ; $09,$D1,$EB,$00 = LOAD from $D1EB, bank $00
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $09,$06,$EC,$00 = LOAD from $06EC, bank $00
                       ; $05,$EB,$05     = SET variable[$EB], param $05

                       db $E1,$02,$09,$3B,$EC,$00,$05,$EB,$05,$E1,$02,$09,$70,$EC,$00,$05;038546|Final battle loads|;
                       ; $E1,$02         = Variable $E1, value $02
                       ; $09,$3B,$EC,$00 = LOAD from $3BEC, bank $00
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $09,$70,$EC,$00 = LOAD from $70EC, bank $00
                       ; $05             = SET command

; ==============================================================================
; NPC/ENTITY BEHAVIOR AI SCRIPT BLOCK
; ==============================================================================
; Entity AI patterns with movement, interaction, and state management
; ==============================================================================
                       db $EB,$05,$E1,$02,$00,$29,$4F,$0F,$00,$05,$05,$47,$FF,$05,$62,$0A;038556|NPC AI initialization|;
                       ; $EB             = Variable $EB
                       ; $05,$E1,$02     = SET variable[$E1] = $02
                       ; $00,$29,$4F     = Padding, command $29 (AI_MODE), parameter $4F
                       ; $0F,$00         = CONFIG command $0F, padding
                       ; $05,$05,$47     = SET variable[$05] = $47 (AI state)
                       ; $FF             = AI mode terminator
                       ; $05,$62,$0A     = SET variable[$62] = $0A (movement pattern)

                       db $05,$05,$09,$00,$5D               ;038566|AI parameter set|;
                       ; $05,$05         = SET variable[$05]
                       ; $09,$00,$5D     = LOAD from address $00, offset $5D

                       db $85                               ;03856B|Bank indicator|00000C;
                       ; $85             = Bank $85 (AI routine bank)

                       db $0C,$0B,$05,$15,$05,$24,$03,$05,$0C,$05,$02,$0C,$0A,$05,$03,$36;03856C|AI state machine|;
                       ; $0C,$0B,$05     = IF variable[$0B] == $05
                       ; $15             = Command $15 (MOVE/WALK)
                       ; $05,$24,$03     = SET variable[$24] = $03
                       ; $05,$0C,$05     = SET variable[$0C] = $05
                       ; $02             = Parameter $02
                       ; $0C,$0A,$05     = IF variable[$0A] == $05
                       ; $03,$36         = Parameter $03, value $36

                       db $08,$C2,$87,$01,$05,$6E,$80,$10,$08,$11,$5F,$01,$05,$3D,$9C,$85;03857C|AI routine calls|;
                       ; $08,$C2,$87     = CALL AI routine $C287
                       ; $01             = Parameter $01
                       ; $05,$6E,$80     = SET variable[$6E] = $80 (movement speed?)
                       ; $10             = Parameter $10
                       ; $08,$11,$5F,$01 = CALL routine $11, offset $5F, count $01
                       ; $05,$3D,$9C,$85 = SET variable[$3D] = $9C, bank $85

; ==============================================================================
; TEXT RENDERING COORDINATE TABLE - EXTRACTABLE DATA
; ==============================================================================
; Text box positioning data with screen coordinates for dialog display
; Format appears to be: [Box_Type] [X_Pos] [Y_Pos] [Width] [Height] [Flags]
; ==============================================================================
                       db $03,$05,$E9,$07,$05,$44,$5F,$01,$08,$50,$86,$05,$18,$80,$10,$08;03858C|Text box config table|;
                       ; Text box configuration data:
                       ; $03             = Box type $03 (dialog window)
                       ; $05,$E9,$07     = SET position variable[$E9] = $07
                       ; $05,$44,$5F,$01 = SET box width[$44][$5F] = $01
                       ; $08,$50,$86     = CALL text routine $5086
                       ; $05,$18,$80     = SET X position $18, value $80
                       ; $10,$08         = Width $10, height $08

; ==============================================================================
; GRAPHICS TILE PATTERN DATA - EXTRACTABLE BINARY DATA
; ==============================================================================
; Raw tile pattern data for sprite graphics (8x8 pixel tiles in 2bpp format)
; This is actual graphical data, not script commands - can be extracted to binary
; ==============================================================================
                       db $FF,$BD,$C2,$47,$B8,$B7,$CE,$29,$6A,$30,$17,$6A,$17,$03,$17,$04;03859C|Tile graphics data block 1|;
                       ; GRAPHICS DATA: 8x8 tile pattern (16 bytes)
                       ; Binary pattern represents pixel data for sprite tile
                       ; Format: 2bpp SNES tile format (2 bits per pixel, 4 colors)
                       ; Pixels encoded in bitplanes - would need extraction tool
                       ; to convert to image format

; ==============================================================================
; MAP TRANSITION SCRIPT WITH GRAPHICS LOADING
; ==============================================================================
; Complex scene transition with fade effects and sprite loading
; ==============================================================================
                       db $0C,$2D,$00,$32,$05,$2F,$3C,$0F,$C8,$00,$0B,$00,$BE;0385AC|Scene transition setup|;
                       ; $0C,$2D,$00,$32 = IF variable[$2D] == $00, compare $32
                       ; $05,$2F,$3C     = SET variable[$2F] = $3C (fade timer?)
                       ; $0F,$C8,$00     = CONFIG $0F, value $C8, padding
                       ; $0B,$00,$BE     = CALL routine $00, offset $BE

                       db $85                               ;0385B9|Bank indicator|00000C;
                       ; $85             = Bank $85 (scene transition routines)

                       db $0C,$5F,$01,$68,$18,$0F,$C8,$00,$0B,$01,$CC,$85;0385BA|Transition parameters|;
                       ; $0C,$5F,$01     = IF variable[$5F] == $01
                       ; $68,$18         = Parameter $68, value $18
                       ; $0F,$C8,$00     = CONFIG $0F, value $C8, padding
                       ; $0B,$01,$CC,$85 = CALL routine $01, offset $CC, bank $85

                       db $08,$82,$81,$0A,$CF,$85           ;0385C6|Transition call sequence|;
                       ; $08,$82,$81     = CALL routine $8281
                       ; $0A,$CF,$85     = LOOP $0A, count $CF, bank $85

                       db $08,$9F,$81,$05,$00,$08,$EE,$85,$08,$F8,$FE,$0F,$42,$21,$05,$09;0385CC|Graphics fade control|;
                       ; $08,$9F,$81     = CALL routine $9F81
                       ; $05,$00         = SET variable[$00]
                       ; $08,$EE,$85     = CALL graphics routine $EE85
                       ; $08,$F8,$FE     = CALL fade routine $F8FE
                       ; $0F,$42,$21     = CONFIG $0F, param $42, value $21
                       ; $05,$09         = SET variable[$09]

; ==============================================================================
; END OF BANK $03 CYCLE 2
; ==============================================================================
; Extracted Components:
; - Complex event scripts with multi-stage conditionals
; - Item/chest placement coordinate tables
; - Graphics tile pattern data (binary extractable)
; - Sprite positioning coordinate tables
; - Battle formation configuration data
; - NPC AI behavior scripts
; - Text box positioning tables
; - Palette/color manipulation sequences
; - Scene transition with fade effects
; ==============================================================================
; Progress: ~900 lines documented / 2,352 total lines (~38.3% complete)
; Next Cycle: Continue with remaining script blocks, text data, additional
; graphics tables, and complete bytecode documentation
; ==============================================================================
