; ==============================================================================
; FINAL FANTASY MYSTIC QUEST - BANK $03 CYCLE 1 COMPREHENSIVE DOCUMENTATION
; ==============================================================================
; BANK $03: ROM Address $038000 - Script Engine, Entity Data & Event System
; Cycle 1: Lines 1-450 - Script Bytecode Engine & Map Data Tables
; ==============================================================================
; ANALYSIS FOCUS: 80% CODE DOCUMENTATION / 20% DATA PATTERN RECOGNITION
; This bank appears to contain the game's script bytecode engine that drives
; map events, NPC interactions, entity spawning, and dialog triggers. While
; much of the content is hexadecimal data arrays, these represent interpretable
; bytecode commands and structured data that control game behavior.
; ==============================================================================

                                                            ;      |        |      ;
                       ORG $038000                          ;      |        |      ;
                                                            ;      |        |      ;

; ==============================================================================
; SCRIPT BYTECODE / EVENT DATA BLOCK 1
; ==============================================================================
; This appears to be a script bytecode table containing commands for map events,
; NPC behaviors, entity spawning, and dialog triggers. Each byte likely represents:
; - Command opcodes (e.g., 0x05 = set variable, 0x08 = jump, 0x0C = call)
; - Command parameters (entity IDs, map coordinates, flags, values)
; - Dialog/text references (pointers to text strings)
; - Conditional branches (if/then logic for events)
;
; CODE PATTERN ANALYSIS:
; - $05 prefix appears frequently: likely "SET" command (set variable/flag)
; - $08 prefix: possible "CALL/JUMP" command (execute subroutine)
; - $0C prefix: possible "COMPARE/IF" command (conditional check)
; - $09 prefix: possible "LOAD/READ" command (read memory/flag)
; - $0F prefix: possible "RETURN/END" command (end script/return)
; ==============================================================================
                       db $0C,$00,$06,$01,$05,$24,$03,$05,$02,$06,$02,$09,$04,$80,$0D,$00;038000|Script commands|000600;
                       ; Bytecode interpretation attempt:
                       ; $0C,$00,$06,$01 = IF flag[$00] == $06, param $01
                       ; $05,$24,$03     = SET variable[$24] = $03
                       ; $05,$02,$06     = SET variable[$02] = $06
                       ; $02,$09,$04     = Parameter $02, LOAD $09, value $04
                       ; $80             = Possible terminator or branch flag
                       ; $0D,$00         = Extended command $0D, param $00

                       db $0D,$1D,$00,$00,$2D,$05,$F9,$08,$B0,$24,$00,$02,$20,$16,$15,$00;038010|Script commands|00001D;
                       ; $0D,$1D,$00,$00 = Command $0D (possibly SPAWN/CREATE), entity $1D, coords $00/$00
                       ; $2D             = Command $2D (possibly DISABLE/REMOVE)
                       ; $05,$F9,$08     = SET variable[$F9] = $08
                       ; $B0             = Command $B0 (possibly WARP/TELEPORT)
                       ; $24,$00,$02     = Parameter $24, value $00, count $02
                       ; $20,$16,$15,$00 = Command $20, coords $16/$15, param $00

                       db $02,$19,$05,$24,$1A,$00,$66,$01,$02,$15,$00,$1A,$19,$05,$24,$1A;038020|Script entity spawn data|;
                       ; Entity spawn pattern detected:
                       ; $02,$19         = Spawn type $02, entity ID $19
                       ; $05,$24,$1A,$00 = SET variable[$24][$1A] = $00
                       ; $66,$01         = Map ID $66, entrance $01
                       ; $02,$15,$00     = Spawn type $02, coords $15/$00
                       ; $1A,$19         = Entity $1A, type $19

                       db $00,$66,$01,$02,$15,$00,$1A,$19,$05,$24,$1A,$00,$68,$01,$02,$15;038030|Multiple entity spawns|;
                       ; Repeated entity spawn pattern:
                       ; $00,$66,$01     = Continuation/offset $00, map $66, entrance $01
                       ; $02,$15,$00     = Spawn at coords $15/$00
                       ; $1A,$19         = Entity $1A, type $19
                       ; $05,$24,$1A,$00 = SET variable[$24][$1A] = $00
                       ; $68,$01         = Map ID $68, entrance $01
                       ; $02,$15         = Spawn type $02, coords $15

                       db $00,$18,$19,$05,$24,$1A,$00,$62,$01,$02,$05;038040|Entity spawn continued|000008;
                       ; $00,$18,$19     = Coords $00/$18, entity $19
                       ; $05,$24,$1A,$00 = SET variable[$24][$1A] = $00
                       ; $62,$01         = Map ID $62, entrance $01
                       ; $02,$05         = Spawn type $02, param $05

; ==============================================================================
; PADDING/FILLER BLOCK
; ==============================================================================
; This block contains repeated $08 values, typically used as padding to align
; data structures or to fill unused space in ROM banks. Not executable code.
; ==============================================================================
                       db $36,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08;038040|Padding block|000008;
                       db $08,$08,$08,$08,$08,$08,$08,$01,$08,$12,$A4,$29,$93,$05,$F3,$BD;038050|Padding + script resume|;

; ==============================================================================
; SCRIPT CONTINUATION & MEMORY POINTERS
; ==============================================================================
; Script resumes after padding. The $05,$F3 pattern suggests a SET command
; writing to higher memory addresses (possibly WRAM variables or flags).
; ==============================================================================
                       db $B7,$03,$00,$00,$7F,$78,$02,$09,$6A,$A5,$0C,$0E,$5F,$01,$00,$00;038060|Memory write operations|000003;
                       ; $B7,$03         = Command $B7, param $03
                       ; $00,$00,$7F     = Address $0000, bank $7F (WRAM)
                       ; $78,$02         = Value $78, count $02
                       ; $09,$6A,$A5     = LOAD from address $6A, value $A5
                       ; $0C,$0E,$5F,$01 = IF command $0C, compare $0E, target $5F, param $01
                       ; $00,$00         = Null padding

                       db $7F,$05,$F4,$5F,$01,$00,$0B,$00,$CA,$80,$19,$05,$40,$5F,$01,$05;038070|WRAM operations + conditions|5FF405;
                       ; $7F             = Bank $7F (WRAM) indicator
                       ; $05,$F4,$5F,$01 = SET variable[$F4][$5F] = $01
                       ; $00,$0B,$00     = Padding/alignment
                       ; $CA,$80         = Command $CA (possibly AUDIO/SOUND), param $80
                       ; $19             = Entity/event ID $19
                       ; $05,$40,$5F,$01 = SET variable[$40][$5F] = $01
                       ; $05             = SET command prefix

                       db $11,$05,$24,$1A,$00,$64,$01,$02,$19,$05,$FC,$93,$D3,$80,$08,$12;038080|Entity initialization|000005;
                       ; $11             = Command $11 (possibly ENABLE/ACTIVATE)
                       ; $05,$24,$1A,$00 = SET variable[$24][$1A] = $00
                       ; $64,$01         = Map $64, entrance $01
                       ; $02,$19         = Spawn type $02, entity $19
                       ; $05,$FC,$93     = SET variable[$FC] = $93
                       ; $D3,$80         = Command $D3, param $80
                       ; $08,$12         = CALL/JUMP to routine $12

; ==============================================================================
; COMPLEX SCRIPT BLOCK - MULTI-COMMAND SEQUENCES
; ==============================================================================
; This section contains more complex bytecode sequences with nested commands,
; conditional branches, and subroutine calls. Pattern suggests event triggers
; that check multiple conditions before executing actions.
; ==============================================================================
                       db $A4,$10,$64,$01,$05,$4B,$62,$01,$05,$6B,$01,$05,$37,$13,$1E,$14;038090|Multi-condition event|000010;
                       ; $A4,$10         = Command $A4 (possibly WAIT/DELAY), duration $10
                       ; $64,$01         = Map $64, entrance $01
                       ; $05,$4B,$62,$01 = SET variable[$4B][$62] = $01
                       ; $05,$6B,$01     = SET variable[$6B] = $01
                       ; $05,$37,$13     = SET variable[$37] = $13
                       ; $1E,$14         = Command $1E (possibly MOVE/WALK), direction $14

                       db $FE,$05,$45,$62,$01,$12,$1A,$00,$FF,$05,$40,$5F,$01,$05,$11,$FF;0380A0|Conditional branch|004505;
                       ; $FE             = Command $FE (possibly GOSUB/CALL with return)
                       ; $05,$45,$62,$01 = SET variable[$45][$62] = $01
                       ; $12,$1A,$00     = Command $12, entity $1A, param $00
                       ; $FF             = Terminator/end marker
                       ; $05,$40,$5F,$01 = SET variable[$40][$5F] = $01
                       ; $05,$11         = SET variable $11
                       ; $FF             = End marker

                       db $08,$F8,$80,$10,$5F,$01,$05,$BB,$78,$02,$71,$80,$19,$08,$12,$A4;0380B0|CALL with parameters|;
                       ; $08,$F8,$80     = CALL routine at $F880
                       ; $10,$5F,$01     = Parameter $10, value $5F, count $01
                       ; $05,$BB,$78,$02 = SET variable[$BB][$78] = $02
                       ; $71,$80         = Command $71, param $80
                       ; $19             = Entity ID $19
                       ; $08,$12,$A4     = CALL routine $12A4

                       db $0C,$1F,$00,$0B,$05,$30,$08,$F8,$80,$00,$19,$08,$12,$A4,$29,$93;0380C0|IF/THEN with CALL|00001F;
                       ; $0C,$1F,$00,$0B = IF variable[$1F] == $00, compare $0B
                       ; $05,$30         = SET variable[$30]
                       ; $08,$F8,$80     = CALL routine $F880
                       ; $00,$19         = Padding, entity $19
                       ; $08,$12,$A4     = CALL routine $12A4
                       ; $29,$93         = Command $29, param $93

                       db $0A,$B0,$80,$17,$93,$FF,$FF,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8;0380D0|LOOP + padding terminator|;
                       ; $0A,$B0,$80     = Command $0A (possibly FOR/LOOP), count $B0, param $80
                       ; $17,$93         = Command $17, value $93
                       ; $FF,$FF         = Double terminator (end of script block)
                       ; $D8 × 11        = Padding bytes (repeated $D8 = invalid/unused)

                       db $D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8;0380E0|Padding continuation|;
                       ; Continued padding with $D8 bytes - likely alignment for next data block

                       db $D8,$D8,$D8,$FF,$FF,$0A,$91,$80,$05,$24,$66,$01,$1A,$00,$02,$05;0380F0|Padding end + new script|;
                       ; $D8 × 3         = Padding end
                       ; $FF,$FF         = Script block terminator
                       ; $0A,$91,$80     = New script: LOOP command $0A, count $91, param $80
                       ; $05,$24,$66,$01 = SET variable[$24][$66] = $01
                       ; $1A,$00,$02     = Entity $1A, coords $00/$02
                       ; $05             = SET command prefix

; ==============================================================================
; ENTITY BEHAVIOR DATA BLOCK
; ==============================================================================
; This section contains entity AI/behavior definitions with movement patterns,
; battle configurations, and spawn conditions. The $05 commands set initial
; entity states, while $08/$09 commands control behavior loops.
; ==============================================================================
                       db $8B,$05,$24,$68,$01,$1A,$00,$02,$05,$8C,$05,$00,$09,$7F,$9A,$00;038100|Entity AI initialization|;
                       ; $8B             = Command $8B (possibly AI_TYPE or BEHAVIOR_MODE)
                       ; $05,$24,$68,$01 = SET variable[$24][$68] = $01
                       ; $1A,$00,$02     = Entity $1A, position $00/$02
                       ; $05,$8C         = SET variable[$8C]
                       ; $05,$00         = SET variable[$00]
                       ; $09,$7F,$9A,$00 = LOAD from address $7F9A, bank $00

                       db $00,$08,$BC,$81,$05,$35,$1B,$05,$EC,$00,$0C,$55,$20,$05,$EC,$00;038110|Behavior script|;
                       ; $00             = Null/padding
                       ; $08,$BC,$81     = CALL routine $BC81
                       ; $05,$35,$1B     = SET variable[$35] = $1B
                       ; $05,$EC,$00     = SET variable[$EC] = $00
                       ; $0C,$55,$20     = IF variable[$55] == $20
                       ; $05,$EC,$00     = SET variable[$EC] = $00

                       db $0E,$55,$02,$24,$00,$02,$20,$1B,$05,$32,$05,$00,$05,$E3,$3C,$0C;038120|Complex condition|000255;
                       ; $0E,$55,$02     = Command $0E (possibly ELSE/ENDIF), var $55, param $02
                       ; $24,$00,$02     = Parameter $24, value $00, count $02
                       ; $20,$1B         = Command $20, param $1B
                       ; $05,$32         = SET variable[$32]
                       ; $05,$00         = SET variable[$00]
                       ; $05,$E3,$3C     = SET variable[$E3] = $3C
                       ; $0C             = IF command prefix

                       db $C8,$00,$00,$0D,$B4,$00,$34,$00,$27,$07,$05,$81,$1E,$00,$20,$05;038130|Memory operations|;
                       ; $C8,$00,$00     = Command $C8 (possibly CLEAR/RESET), address $0000
                       ; $0D,$B4,$00,$34 = Extended command $0D, write $B4 to $0034
                       ; $00,$27,$07     = Padding, command $27, param $07
                       ; $05,$81,$1E,$00 = SET variable[$81][$1E] = $00
                       ; $20,$05         = Command $20, param $05

; ==============================================================================
; AUDIO/MUSIC TRIGGER BLOCK
; ==============================================================================
; Script commands that trigger music changes and sound effects. The $F9 pattern
; appears to be a music/audio command, while $A8/$24 control playback state.
; ==============================================================================
                       db $F9,$A8,$24,$24,$03,$15,$1A,$05,$18,$05,$36,$08,$08,$08,$08,$04;038140|Music command|0024A8;
                       ; $F9,$A8,$24     = Command $F9 (PLAY_MUSIC), track $A8, param $24
                       ; $24,$03         = Parameter $24, value $03
                       ; $15,$1A         = Command $15, entity $1A
                       ; $05,$18         = SET variable[$18]
                       ; $05,$36         = SET variable[$36]
                       ; $08 × 4         = Padding
                       ; $04             = Parameter value

                       db $09,$B1,$EB,$00,$05,$EB,$05,$00,$05,$E2,$05,$E3,$0D,$BE,$00,$00;038150|Memory read/write loop|;
                       ; $09,$B1,$EB,$00 = LOAD from address $B1EB, bank $00
                       ; $05,$EB         = SET variable[$EB]
                       ; $05,$00         = SET variable[$00]
                       ; $05,$E2         = SET variable[$E2]
                       ; $05,$E3         = SET variable[$E3]
                       ; $0D,$BE,$00,$00 = Extended command $0D, target $BE, params $00/$00

                       db $00,$00                           ;038160|Null padding|;
                       ; Script block terminator/alignment

; ==============================================================================
; GRAPHICS/PALETTE DATA REFERENCE BLOCK
; ==============================================================================
; These appear to be graphics-related commands that load/modify palettes,
; sprites, or tilemap data. The $F0/$F1 prefixes suggest graphics operations.
; (20% DATA FOCUS: Recognizing pattern but not deep-diving into hex values)
; ==============================================================================
                       db $0C,$90,$10,$FF,$0C,$A1,$10,$FF,$08,$EE,$85,$05,$F0,$63,$36,$7E;038162|Graphics load commands|;
                       ; $0C,$90,$10,$FF = IF command, graphics register $90, value $10, mask $FF
                       ; $0C,$A1,$10,$FF = IF command, graphics register $A1, value $10, mask $FF
                       ; $08,$EE,$85     = CALL graphics routine $EE85
                       ; $05,$F0,$63,$36 = SET graphics variable[$F0][$63] = $36
                       ; $7E             = Graphics bank/mode indicator

                       db $00,$05,$F1,$5F,$36,$7E,$00,$00,$05,$F1,$61,$36,$7E,$00,$00,$00;038172|Graphics configuration|;
                       ; $00             = Padding
                       ; $05,$F1,$5F,$36 = SET graphics variable[$F1][$5F] = $36
                       ; $7E,$00,$00     = Graphics bank $7E, coords $00/$00
                       ; $05,$F1,$61,$36 = SET graphics variable[$F1][$61] = $36
                       ; $7E,$00,$00,$00 = Graphics bank, padding

; ==============================================================================
; TILEMAP/LAYER CONTROL BLOCK
; ==============================================================================
; Commands that manipulate BG layers, scrolling, and tilemap updates.
; The $24 command appears to control layer properties/visibility.
; ==============================================================================
                       db $0F,$24,$00,$14,$08,$0B,$00,$95,$81,$05,$36,$08,$08,$08,$08,$08;038182|Layer control|;
                       ; $0F,$24,$00,$14 = Command $0F (possibly LAYER_CONFIG), layer $24, param $00, value $14
                       ; $08,$0B,$00     = CALL routine $0B00
                       ; $95,$81         = Command $95, param $81
                       ; $05,$36         = SET variable[$36]
                       ; $08 × 5         = Padding

                       db $04,$06,$00,$05,$36,$86,$08,$08,$08,$08,$04,$08,$00,$0F,$24,$00;038192|Layer config continued|;
                       ; $04,$06,$00     = Parameter $04, value $06, padding
                       ; $05,$36,$86     = SET variable[$36] = $86
                       ; $08 × 4         = Padding
                       ; $04,$08,$00     = Parameters
                       ; $0F,$24,$00     = Layer config command prefix

                       db $14,$08,$0B,$00,$B2,$81,$05,$36,$08,$84,$08,$08,$08,$08,$06,$00;0381A2|Layer + graphics mix|;
                       ; $14,$08         = Parameter $14, value $08
                       ; $0B,$00,$B2,$81 = CALL routine at $00B2, bank $81
                       ; $05,$36,$08     = SET variable[$36] = $08
                       ; $84             = Graphics command $84
                       ; $08 × 4         = Padding
                       ; $06,$00         = Parameter

                       db $05,$36,$86,$84,$08,$08,$08,$08,$08,$00,$37,$0D,$42,$00,$00,$58;0381B2|Graphics state setup|;
                       ; $05,$36,$86,$84 = SET variable[$36] = $86 (graphics mode $84)
                       ; $08 × 5         = Padding
                       ; $00,$37         = Padding, parameter $37
                       ; $0D,$42,$00,$00 = Extended command $0D, write to $42, params $00/$00
                       ; $58             = Graphics parameter

; ==============================================================================
; ITEM/INVENTORY EVENT BLOCK
; ==============================================================================
; Script commands that handle item acquisition, inventory checks, and rewards.
; The $EC variable appears to track item/inventory state.
; ==============================================================================
                       db $34,$00,$05,$EC,$66,$00,$FF,$08,$05,$6D,$00,$05,$EC,$66,$00,$03;0381C2|Item check/give|;
                       ; $34,$00         = Command $34 (possibly CHECK_ITEM), slot $00
                       ; $05,$EC,$66,$00 = SET variable[$EC][$66] = $00
                       ; $FF             = Terminator/invalid item
                       ; $08,$05,$6D,$00 = CALL routine $056D, bank $00
                       ; $05,$EC,$66,$00 = SET variable[$EC][$66] = $00
                       ; $03             = Item quantity/ID

                       db $08,$05,$6D,$00,$08,$CD,$81,$05,$18,$66,$00,$08,$00,$05,$06,$64;0381D2|Item give routine|;
                       ; $08,$05,$6D,$00 = CALL item routine $056D, bank $00
                       ; $08,$CD,$81     = CALL routine $CD81
                       ; $05,$18,$66,$00 = SET variable[$18][$66] = $00
                       ; $08,$00         = CALL/padding
                       ; $05,$06,$64     = SET variable[$06] = $64

                       db $E7,$81                           ;0381E2|Routine pointer|;
                       ; $E7,$81         = Routine address $E781 (item handler continuation)

                       db $05,$3B,$63                       ;0381E4|Item parameter|00003B;
                       ; $05,$3B,$63     = SET variable[$3B] = $63 (item ID or count)

; ==============================================================================
; BATTLE ENCOUNTER SETUP BLOCK
; ==============================================================================
; Script commands that initialize battle encounters, set enemy formations,
; and configure battle parameters. The $6C/$48 variables control encounter data.
; ==============================================================================
                       db $0C,$6C,$00,$31,$05,$6D,$10,$6C,$00,$05,$48,$10,$10,$05,$18,$9E;0381E7|Battle encounter init|;
                       ; $0C,$6C,$00,$31 = IF variable[$6C] == $00, compare $31
                       ; $05,$6D,$10     = SET variable[$6D] = $10 (encounter type)
                       ; $6C,$00         = Variable $6C, value $00
                       ; $05,$48,$10,$10 = SET variable[$48] = $10 (battle parameter), param $10
                       ; $05,$18,$9E     = SET variable[$18] = $9E

                       db $00,$02,$00,$05,$02,$39,$B6,$03,$25,$28,$27,$04,$15,$00,$2E,$19;0381F7|Battle formation data|;
                       ; $00,$02,$00     = Padding, count $02, padding
                       ; $05,$02,$39     = SET variable[$02] = $39 (formation ID)
                       ; $B6,$03         = Parameter $B6, count $03
                       ; $25,$28,$27,$04 = Enemy IDs: $25, $28, $27, count $04
                       ; $15,$00,$2E,$19 = Positioning parameters $15/$00, values $2E/$19

                       db $05,$8B,$0C,$1F,$00,$07,$05,$30,$08,$12,$A4,$05,$8C,$05,$F9,$B8;038207|Battle trigger check|;
                       ; $05,$8B         = SET variable[$8B] (battle state)
                       ; $0C,$1F,$00,$07 = IF variable[$1F] == $00, compare $07
                       ; $05,$30         = SET variable[$30]
                       ; $08,$12,$A4     = CALL battle routine $12A4
                       ; $05,$8C         = SET variable[$8C]
                       ; $05,$F9,$B8     = SET variable[$F9] = $B8 (music track for battle)

                       db $20,$0D,$28,$00,$01,$30,$15,$02,$30,$05,$24,$B2,$82,$F8,$00,$09;038217|Battle parameters|;
                       ; $20             = Command $20 (parameter set)
                       ; $0D,$28,$00,$01 = Extended command, write to $28, params $00/$01
                       ; $30,$15,$02,$30 = Battle parameters $30/$15/$02/$30
                       ; $05,$24,$B2,$82 = SET variable[$24][$B2] = $82
                       ; $F8,$00,$09     = Parameter $F8, padding, count $09

                       db $08,$FA,$81,$0D,$00,$0E,$55,$55,$0F,$31,$10,$0B,$FF,$46;038227|Battle start routine|;
                       ; $08,$FA,$81     = CALL battle start routine $FA81
                       ; $0D,$00,$0E,$55 = Extended command $0D, params $00/$0E, value $55
                       ; $55             = Parameter (enemy count or difficulty)
                       ; $0F,$31,$10     = Command $0F, param $31, value $10
                       ; $0B,$FF,$46     = CALL routine, terminator, param $46

                       db $82                               ;038235|Bank/routine pointer|038244;
                       ; $82             = Bank $82 indicator (points to code in bank $82)

; ==============================================================================
; DIALOG/TEXT EVENT BLOCK
; ==============================================================================
; Script commands that trigger dialog boxes, text display, and NPC conversations.
; The $0C/$0E commands check conditions before displaying text, $0F controls
; text box properties, and $19/$31 handle text flow/pagination.
; ==============================================================================
                       db $0C,$00,$0E,$00,$15,$0D,$31,$19,$FE,$FE,$01,$FE,$FE,$01,$FE,$FE;038236|Dialog trigger conditional|;
                       ; $0C,$00,$0E,$00 = IF variable[$00][$0E] == $00
                       ; $15             = Command $15 (possibly TEXT_BOX or DISPLAY)
                       ; $0D,$31,$19     = Extended command $0D, param $31, text ID $19
                       ; $FE,$FE,$01     = Text control bytes (line break, wait, continue)
                       ; $FE,$FE,$01     = Repeated text control
                       ; $FE,$FE         = Text end markers

                       db $0F,$90,$10,$0B,$FF,$64,$82,$0F,$B1,$10,$0B,$FF,$64;038246|Text box configuration|;
                       ; $0F,$90,$10     = Command $0F (TEXT_CONFIG), position $90, width $10
                       ; $0B,$FF,$64     = CALL routine $FF, param $64
                       ; $82             = Bank $82
                       ; $0F,$B1,$10     = TEXT_CONFIG, position $B1, width $10
                       ; $0B,$FF,$64     = CALL routine, param $64

                       db $82                               ;038253|Bank indicator|038362;
                       ; $82             = Bank $82 pointer

                       db $0C,$01,$0E,$00,$15,$1C,$31,$19,$FE,$FE,$01,$FE,$FE,$01,$FE,$FE;038254|Dialog variant 2|;
                       ; $0C,$01,$0E,$00 = IF variable[$01][$0E] == $00
                       ; $15,$1C         = TEXT_BOX command, type $1C
                       ; $31,$19         = Text reference $31, ID $19
                       ; $FE,$FE,$01 × 3 = Text control sequences

                       db $24,$01,$2E,$1E,$07,$05,$F3,$92,$82,$03,$00,$0C,$00,$20,$00,$2E;038264|Text with parameters|;
                       ; $24,$01         = Parameter $24, value $01
                       ; $2E,$1E,$07     = Command $2E, param $1E, value $07
                       ; $05,$F3,$92,$82 = SET variable[$F3][$92] = $82
                       ; $03,$00         = Parameter $03, padding
                       ; $0C,$00,$20,$00 = IF variable[$00] == $20, param $00
                       ; $2E             = Command $2E

                       db $F0,$83                           ;038274|Graphics/text mode|;
                       ; $F0,$83         = Graphics command $F0, bank $83

                       db $82                               ;038276|Bank indicator|03B87E;
                       ; $82             = Bank $82 pointer (possible far jump target)

; ==============================================================================
; SPRITE/ANIMATION DATA BLOCK
; ==============================================================================
; (20% DATA FOCUS) This section contains sprite animation data, object positioning,
; and visual effect parameters. Not deep-diving into hex but recognizing pattern.
; ==============================================================================
                       db $05,$36,$01,$00,$08,$04,$06,$06,$08,$0A,$8C,$82;038277|Sprite config|;
                       ; $05,$36,$01,$00 = SET sprite[$36] = $01, coords $00
                       ; $08,$04,$06,$06 = Animation frames: $08/$04/$06/$06
                       ; $08             = Frame count
                       ; $0A,$8C,$82     = Animation command $0A, param $8C, bank $82

                       db $05,$36,$01,$00,$08,$08,$08,$00,$08;038283|Animation frame data|000036;
                       ; $05,$36,$01,$00 = SET sprite[$36] = $01, coords $00
                       ; $08,$08,$08,$00 = Frame sequence: $08/$08/$08/$00
                       ; $08             = Frame count/delay

; ==============================================================================
; COORDINATE/POSITIONING TABLE
; ==============================================================================
; (20% DATA FOCUS) Sprite/entity coordinate lookup table. Each entry contains
; X/Y positions and sprite parameters for object placement on screen.
; ==============================================================================
                       db $15,$02,$31,$0A,$7E,$83,$68,$C0,$00,$30,$70,$C0,$01,$30,$68,$C8;03828C|Coordinate table start|;
                       ; $15,$02,$31,$0A = Header: command $15, type $02, param $31, count $0A
                       ; Following bytes are coordinate pairs:
                       ; $7E,$83         = Routine pointer/terminator
                       ; $68,$C0,$00,$30 = Entry 1: X=$68, Y=$C0, layer $00, sprite $30
                       ; $70,$C0,$01,$30 = Entry 2: X=$70, Y=$C0, layer $01, sprite $30
                       ; $68,$C8         = Entry 3: X=$68, Y=$C8

                       db $02,$30,$70,$C8,$03,$30,$E0,$C0,$04,$32,$E8,$C0,$05,$32,$E0,$C8;03829C|Coordinate entries|;
                       ; $02,$30         = Layer $02, sprite $30
                       ; $70,$C8,$03,$30 = Entry 4: X=$70, Y=$C8, layer $03, sprite $30
                       ; $E0,$C0,$04,$32 = Entry 5: X=$E0, Y=$C0, layer $04, sprite $32
                       ; $E8,$C0,$05,$32 = Entry 6: X=$E8, Y=$C0, layer $05, sprite $32
                       ; $E0,$C8         = Entry 7: X=$E0, Y=$C8

                       db $06,$32,$E8,$C8,$07,$32,$00,$10,$00,$80,$10,$00,$84,$0E,$00,$05;0382AC|Coordinate + script mix|;
                       ; $06,$32         = Layer $06, sprite $32
                       ; $E8,$C8,$07,$32 = Entry 8: X=$E8, Y=$C8, layer $07, sprite $32
                       ; $00,$10,$00,$80 = Script resume: padding, param $10, padding, value $80
                       ; $10,$00,$84     = Param $10, padding, command $84
                       ; $0E,$00,$05     = Command $0E, padding, param $05

; ==============================================================================
; MAP TRANSITION/WARP DATA BLOCK
; ==============================================================================
; Script commands controlling map transitions, warps, and scene changes.
; Variables $4D/$43/$EA track map state and transition parameters.
; ==============================================================================
                       db $4D,$10,$05,$43,$D0,$BE,$0C,$05,$EA,$10,$00,$08,$CE,$82,$05,$EA;0382BC|Map transition init|;
                       ; $4D,$10         = Command $4D (MAP_LOAD), map ID $10
                       ; $05,$43,$D0     = SET variable[$43] = $D0 (entrance point)
                       ; $BE,$0C         = Parameter $BE, value $0C
                       ; $05,$EA,$10,$00 = SET variable[$EA] = $10, coords $00
                       ; $08,$CE,$82     = CALL map routine $CE82
                       ; $05,$EA         = SET variable[$EA]

                       db $10,$00,$05,$6C,$01,$05,$43,$3B,$AF,$07,$05,$2D,$9E,$00,$05,$5A;0382CC|Map entrance config|;
                       ; $10,$00         = Param $10, padding
                       ; $05,$6C,$01     = SET variable[$6C] = $01 (map loaded flag)
                       ; $05,$43,$3B     = SET variable[$43] = $3B (spawn point)
                       ; $AF,$07         = Parameter $AF, value $07
                       ; $05,$2D,$9E,$00 = SET variable[$2D] = $9E, bank $00
                       ; $05,$5A         = SET variable[$5A]

                       db $FF,$FF,$05,$43,$1A,$B0,$07,$05,$2C,$9E,$00,$14,$3F,$05,$4D,$10;0382DC|Map config + jump|;
                       ; $FF,$FF         = Terminator/invalid marker
                       ; $05,$43,$1A     = SET variable[$43] = $1A
                       ; $B0,$07         = Parameter $B0, value $07
                       ; $05,$2C,$9E,$00 = SET variable[$2C] = $9E, bank $00
                       ; $14,$3F         = Command $14, param $3F
                       ; $05,$4D,$10     = SET variable[$4D] = $10 (map ID)

                       db $05,$43,$D0,$BE,$0C,$00,$29,$01,$25,$2C,$27,$03,$05,$F9,$A0,$18;0382EC|Map load with music|;
                       ; $05,$43,$D0     = SET variable[$43] = $D0
                       ; $BE,$0C,$00     = Parameters $BE/$0C/$00
                       ; $29,$01         = Command $29, param $01
                       ; $25,$2C,$27,$03 = Parameters (enemy/NPC IDs?)
                       ; $05,$F9,$A0     = SET variable[$F9] = $A0 (music track)
                       ; $18             = Parameter $18

                       db $24,$1A,$28,$04,$03,$15,$1B,$29,$05,$32,$05,$36,$08,$08,$08,$2E;0382FC|Entity spawn on map|;
                       ; $24,$1A,$28,$04 = Parameter $24, entity $1A, type $28, count $04
                       ; $03,$15,$1B     = Param $03, coords $15/$1B
                       ; $29,$05         = Command $29, param $05
                       ; $32,$05         = Parameter $32, value $05
                       ; $36,$08,$08,$08 = Sprite $36, animation frames
                       ; $2E             = Command $2E

                       db $F1,$4D                           ;03830C|Graphics command|;
                       ; $F1,$4D         = Graphics command $F1, param $4D

                       db $83                               ;03830E|Bank indicator|00000F;
                       ; $83             = Bank $83 pointer

; ==============================================================================
; COMPLEX EVENT SCRIPT BLOCK
; ==============================================================================
; Multi-stage event with nested conditions, map checks, and entity spawning.
; This appears to be a story progression or dungeon event trigger.
; ==============================================================================
                       db $0F,$91,$0E,$05,$6C,$01,$05,$43,$3B,$AF,$07,$05,$2D,$9E,$00,$05;03830F|Event condition check|;
                       ; $0F,$91,$0E     = Command $0F, param $91, value $0E
                       ; $05,$6C,$01     = SET variable[$6C] = $01
                       ; $05,$43,$3B     = SET variable[$43] = $3B
                       ; $AF,$07         = Parameter $AF, value $07
                       ; $05,$2D,$9E,$00 = SET variable[$2D] = $9E, bank $00
                       ; $05             = SET command prefix

                       db $5A,$FF,$FF,$05,$43,$18,$B0,$07,$05,$2C,$9E,$00,$14,$1F,$0B,$00;03831F|Event execution|;
                       ; $5A,$FF,$FF     = Variable $5A, double terminator
                       ; $05,$43,$18     = SET variable[$43] = $18
                       ; $B0,$07         = Parameter $B0, value $07
                       ; $05,$2C,$9E,$00 = SET variable[$2C] = $9E, bank $00
                       ; $14,$1F         = Command $14, param $1F
                       ; $0B,$00         = CALL/padding

                       db $4D,$83,$0B,$0A,$3A               ;03832F|Routine call|;
                       ; $4D,$83         = Command $4D, bank $83
                       ; $0B,$0A,$3A     = CALL routine $0A, param $3A

                       db $83                               ;038334|Bank marker|000005;
                       ; $83             = Bank $83

                       db $05,$09,$14,$46,$83               ;038335|Event continue|;
                       ; $05,$09,$14     = SET variable[$09] = $14
                       ; $46,$83         = Parameter $46, bank $83

                       db $05,$83,$2A,$00,$05,$84,$28,$00,$05,$84,$25,$00;03833A|Variable sets|000083;
                       ; $05,$83,$2A,$00 = SET variable[$83][$2A] = $00
                       ; $05,$84,$28,$00 = SET variable[$84][$28] = $00
                       ; $05,$84,$25,$00 = SET variable[$84][$25] = $00

                       db $18,$0F,$91,$0E,$08,$4E,$83,$00,$05,$6C,$01,$05,$43,$3B,$AF,$07;038346|Event stage 2|;
                       ; $18             = Parameter $18
                       ; $0F,$91,$0E     = Command $0F, param $91, value $0E
                       ; $08,$4E,$83     = CALL routine $4E83
                       ; $00             = Padding
                       ; $05,$6C,$01     = SET variable[$6C] = $01
                       ; $05,$43,$3B     = SET variable[$43] = $3B
                       ; $AF,$07         = Parameter $AF, value $07

                       db $05,$2D,$9E,$00,$05,$5A,$FF,$FF,$05,$43,$18,$B0,$07,$05,$2C,$9E;038356|Event continuation|;
                       ; $05,$2D,$9E,$00 = SET variable[$2D] = $9E, bank $00
                       ; $05,$5A,$FF,$FF = SET variable[$5A] = $FF (terminator)
                       ; $05,$43,$18     = SET variable[$43] = $18
                       ; $B0,$07         = Parameter $B0, value $07
                       ; $05,$2C,$9E     = SET variable[$2C] = $9E

                       db $00,$14,$1F,$0B,$00,$7D,$83,$05,$05,$0B,$76,$83,$9B,$0A,$D6,$81;038366|Event execution calls|;
                       ; $00,$14,$1F     = Padding, command $14, param $1F
                       ; $0B,$00,$7D,$83 = CALL routine at bank $83, offset $7D
                       ; $05,$05,$0B     = SET variable[$05] = $0B
                       ; $76,$83         = Parameter $76, bank $83
                       ; $9B             = Command $9B
                       ; $0A,$D6,$81     = Loop command $0A, count $D6, bank $81

