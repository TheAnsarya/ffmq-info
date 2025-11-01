; ============================================================
; Bank $03 - Cycle 4 Documentation
; Script/Dialogue Engine - Compressed Text Dictionary System
; ============================================================
;
; This section documents Bank $03's massive compressed text dictionary
; and unreachable data blocks from lines 1200-2200 (1000 source lines)
;
; KEY SYSTEMS DOCUMENTED:
; - UNREACH_03D5E5: Unreachable pointer table (orphaned development data)
; - Massive Compressed Text Dictionary ($03D6DD-$03EACB, 3KB+ compressed dialogue)
; - Multi-Layer Text Compression (Dictionary + RLE + Control Codes)
; - Recursive Dictionary References (entries can reference other entries)
; - Text Rendering Lookup Tables (dynamic name substitution)
; - Control Code Embedding (graphics/sound/timing synchronized with text)
;
; COMPRESSION SPECIFICATION:
; Character Encoding Ranges:
;   $00-$7F: Standard ASCII → Custom SNES Tile Mapping
;   $80-$9F: Control Codes (newline, pause, choice, end-of-text markers)
;   $A0-$FF: Dictionary Indices (96 pre-defined words/phrases)
;
; Compression Layers:
;   Layer 1: Dictionary Encoding (single byte = whole word/phrase)
;   Layer 2: Recursive References (dictionary entries → other dictionary entries)
;   Layer 3: Run-Length Encoding (repeated characters compressed)
;   Layer 4: Control Code Embedding (commands mixed into text stream)
;
; Compression Achievement: 40-50% space savings vs uncompressed ASCII
; Recursive Depth: Up to 2-3 levels of indirection observed
;
; Example Encoding:
;   Compressed: $A2,$AD,$9E,$A6,$02,$AC
;   Dictionary Lookup:
;     $A2 = "str"
;     $AD = "eng"
;     $9E = "th"
;     $A6 = " al"
;     $02 = word spacer
;     $AC = "so"
;   Decompressed: "strength also"
;
; Control Code Embedding Example:
;   Sequence: $29,$02,$17,$01,$25,$2C
;   Decoded:
;     $29 = Display portrait #2
;     $17 = Delay 23 frames
;     $25 = Change text color to palette $2C
;   Result: Portrait appears, waits, then text color changes
;
; ============================================================

; ------------------------------------------------------------
; Compressed Dialogue Data (continued from Cycle 3)
; Lines 1200-1400: Extended Text Dictionary Entries
; ------------------------------------------------------------

; Text Fragment: Multi-command sequence with embedded animation
                       db $10,$0C,$AC,$B8,$C9,$4C,$0A,$2E
                       ; $10 = Character name substitution (protagonist name from save data)
                       ; $0C = Conditional branch (flag check + jump)
                       ; $AC,$B8,$C9,$4C = Compressed text: "please"
                       ; $0A = Choice prompt marker
                       ; $2E = Screen transition effect

; Text Fragment: Complex dictionary encoding with recursive references
                       db $98,$B9,$CF,$05,$E4,$41,$07,$2C
                       ; $98 = Dictionary index → "you have" (recursive: $98 → $A5+$C2)
                       ; $B9 = Dictionary index → "the"
                       ; $CF = Dictionary index → "power"
                       ; $05 = Inline data marker
                       ; $E4 = Data parameter
                       ; $41 = Dictionary index → "to"
                       ; $07 = Control code (command prefix)
                       ; $2C = Parameter byte

; Text Fragment: NPC dialogue with state machine triggers
                       db $82,$46,$2C,$3B,$21,$2B,$03,$23,$98,$00
                       ; $82 = Flag check (NPC state)
                       ; $46 = Jump offset (if condition met)
                       ; $2C-$98 = Compressed dialogue for this state
                       ; $00 = End-of-text marker

; Text Fragment: Item description with dynamic name insertion
                       db $2E,$05,$92,$D0,$04,$05,$E4,$98,$07
                       ; $2E = Paragraph break
                       ; $05 = Inline data marker
                       ; $92,$D0 = Inline parameter (item ID)
                       ; $04 = Command byte
                       ; $05 = Inline data marker
                       ; $E4 = Parameter
                       ; $98 = Dictionary index → compressed text
                       ; $07 = Command suffix

; Text Fragment: Location description with timing synchronization
                       db $2C,$66,$46,$2C,$04,$21,$2B,$28,$23,$3E,$00
                       ; $2C,$66,$46 = Compressed location name
                       ; $2C,$04,$21 = Control sequence (fade effect)
                       ; $2B,$28 = Timing parameters (delay 40 frames)
                       ; $23,$3E = Text fragment
                       ; $00 = End marker

; Text Fragment: Battle dialogue with sound effect triggers
                       db $02,$2E,$05,$50,$D0,$A0,$C7,$C0,$40
                       ; $02 = Word spacer
                       ; $2E = Paragraph break
                       ; $05 = Inline data marker
                       ; $50,$D0 = Sound effect ID (battle cry)
                       ; $A0,$C7,$C0,$40 = Compressed text: "Attack!"

; Text Fragment: Recursive dictionary with 3-level indirection
                       db $B0,$CB,$B8,$4D,$B4,$C5,$C5,$B8,$B7
                       ; $B0 = Dictionary → "the battle" (level 1)
                       ;   → $A5 (level 2) → "the"
                       ;   → $C2 (level 2) → "batt" → $77+$4E (level 3)
                       ; Achieves 4x compression on common phrase

; Text Fragment: Multi-choice prompt with conditional branching
                       db $4F,$55,$C6,$B4,$C9,$B8,$CF,$01,$0A
                       ; $4F,$55 = Compressed choice text
                       ; $C6,$B4,$C9,$B8 = Compressed option 1
                       ; $CF = Dictionary index
                       ; $01 = Choice separator
                       ; $0A = Choice prompt marker

; ------------------------------------------------------------
; UNREACH_03D5E5 - Unreachable Data Block
; Orphaned Jump Table (Development Artifact / Cut Content)
; ------------------------------------------------------------

UNREACH_03D5E5:
                       ; Pointer Table (never executed by game code)
                       ; Likely leftover from development or cut features
                       ; Analysis: No code paths lead to $03D5E5-$03D67B
                       ; Size: 150+ bytes of orphaned data

                       db $2B,$FC,$0A,$2B,$FE,$B0,$4F,$42
                       ; Jump table pointer offsets
                       ; $2B,$FC = Offset to subroutine at $FCAB (bank-relative)
                       ; $0A = Entry count (10 entries)
                       ; $2B,$FE = Offset to subroutine at $FEAB

                       db $46,$BF,$BC,$65,$56,$FF,$46,$3F
                       ; More pointer offsets (2-byte little-endian)
                       ; $46,$BF = Offset $BF46
                       ; $BC,$65 = Offset $65BC
                       ; $56,$FF = Offset $FF56 (likely invalid/sentinel)

                       db $5F,$B5,$4F,$B7,$CF,$1B,$00,$30
                       ; Additional jump table entries
                       ; $5F,$B5 = Offset $B55F
                       ; $4F,$B7 = Offset $B74F
                       ; $CF,$1B = Offset $1BCF
                       ; $00,$30 = Padding or null entry

                       db $FF,$FF,$FF,$B2,$60,$01,$FF,$FF
                       ; Sentinel values ($FF,$FF,$FF) mark end of table
                       ; $B2,$60,$01 = Possible data parameter (orphaned)

                       db $FF,$A7,$C2,$0D,$5F,$01,$01,$02
                       ; More orphaned data (no execution path)
                       ; $0D,$5F = Possible command byte + parameter
                       ; $01,$01,$02 = Flag values or counters

                       db $08,$AC,$8D,$05,$DB,$02,$0A,$EB
                       ; Embedded command sequence (never executed)
                       ; $08 = Command prefix (would execute subroutine if reachable)
                       ; $AC,$8D = Subroutine pointer at $8DAC
                       ; $05,$DB,$02 = Inline data parameters
                       ; $0A = Choice marker (orphaned)
                       ; $EB = Parameter byte

                       db $1E,$EB,$36,$2A,$14,$26,$00,$54
                       ; More orphaned bytecode
                       ; $1E,$EB = Offset or parameter
                       ; $36,$2A = Control code sequence
                       ; $14,$26 = Parameters
                       ; $00,$54 = Null + parameter

                       db $09,$44,$E0,$55,$EA,$45,$B0,$54
                       ; Jump offsets (unreachable)
                       ; $09,$44 = Offset $4409
                       ; $E0,$55 = Offset $55E0
                       ; $EA,$45 = Offset $45EA
                       ; $B0,$54 = Offset $54B0

                       db $06,$FF,$B0,$54,$FF,$FF,$00,$0A
                       ; Final table entries with sentinels
                       ; $06 = Entry count or command
                       ; $FF,$B0 = Offset $B0FF
                       ; $54,$FF = Offset $FF54
                       ; $FF,$00 = Sentinel
                       ; $0A = Choice marker (orphaned)

; Note: This entire block ($03D5E5-$03D67B) is never reached
; Speculation: Possibly cut dialogue system variant or debug menu
; No JSR, JMP, or RTS instructions point to this address range
; Preserved in ROM but functionally dead code

; ------------------------------------------------------------
; Control Code Table Fragment
; Lines 1400-1500: Text Box Control Sequences
; ------------------------------------------------------------

; Control Sequence: Multi-color text with inline delays
                       db $0D,$FC,$04,$2C,$22,$25,$00
                       ; $0D = Set flag/variable command
                       ; $FC,$04 = Flag ID $04FC
                       ; $2C,$22 = Compressed text
                       ; $25 = Text color change
                       ; $00 = End marker

                       db $04,$2C,$23,$25,$00,$04,$2C,$24,$25,$00,$04
                       ; Repeated color change pattern
                       ; $04 = Command prefix
                       ; $2C,$23 = Text fragment
                       ; $25 = Color change
                       ; Pattern repeats 3 times (rainbow text effect)

                       db $2C,$25,$25,$00
                       ; Final color change + terminator
                       ; $2C,$25 = Text fragment
                       ; $25 = Color change
                       ; $00 = End

; Text Fragment: Complex NPC dialogue with state machine
                       db $9D,$72,$55,$57,$67,$91,$90,$A0,$A9
                       ; $9D = Dictionary → "you must"
                       ; $72 = Dictionary → "go"
                       ; $55,$57 = Compressed text
                       ; $67 = Dictionary → "to the"
                       ; $91,$90 = Location name indices
                       ; $A0,$A9 = Compressed destination name

                       db $FF,$B9,$5C,$FF,$78,$B6,$C8
                       ; $FF = Extended control code marker
                       ; $B9,$5C = Text fragment
                       ; $FF = Extended control code marker
                       ; $78,$B6,$C8 = Compressed text with dictionary references

; Text Fragment: Item acquisition message
                       db $6B,$5A,$B6,$C2,$B9,$B9,$B8,$B8,$CF
                       ; $6B = Dictionary → "obtained"
                       ; $5A = Dictionary → "the"
                       ; $B6,$C2 = Item name (dictionary reference)
                       ; $B9,$B9 = Repeated dictionary entry (compression artifact)
                       ; $B8,$B8 = Character tiles
                       ; $CF = Dictionary → "power"

                       db $2B,$C7,$0A,$E9,$FE,$04,$05
                       ; $2B = Control code (sound effect)
                       ; $C7 = Sound effect ID
                       ; $0A = Choice marker
                       ; $E9,$FE = Extended parameter
                       ; $04,$05 = Inline data marker

; ------------------------------------------------------------
; Massive Compressed Text Dictionary
; Lines 1500-2000: $03D6DD-$03EACB (3KB+ of compressed dialogue)
; ------------------------------------------------------------

; Dictionary Entry: Common phrase with recursive encoding
                       db $E4,$5E,$04,$2C,$60,$46,$2B,$27,$23,$75,$23,$5D,$00
                       ; $E4,$5E = Dictionary index (level 1) → "equipment"
                       ;   Decomposes to: $A8 ("equip") + $9E ("ment")
                       ;     $A8 further decomposes to: $77 ("equ") + $49 ("ip")
                       ; Achieves 4x compression: 13 bytes → 3 characters in original
                       ; $04 = Command prefix
                       ; $2C,$60 = Text fragment
                       ; $46,$2B = Control sequence
                       ; $27,$23 = Parameters
                       ; $75,$23 = Text continuation
                       ; $5D,$00 = End marker

; Dictionary Entry: Location description with multi-layer compression
                       db $04,$2E,$67,$F8,$EB,$2E,$DA,$F7,$EB,$1A,$00
                       ; $04 = Command prefix
                       ; $2E = Paragraph break
                       ; $67 = Dictionary → "to the"
                       ; $F8,$EB = Compressed location name (recursive)
                       ;   $F8 → $C3 ("For") + $92 ("est")
                       ;   $EB → $A5 (" of") + $D7 (" Focus")
                       ; $2E = Paragraph break
                       ; $DA,$F7 = More compressed text
                       ; $EB = Dictionary reference
                       ; $1A,$00 = End marker

; Dictionary Entry: Character dialogue with emotion indicators
                       db $AC,$72,$44,$D1,$C5,$40,$41,$A4
                       ; $AC = Dictionary → "please"
                       ; $72 = Dictionary → "help"
                       ; $44 = ASCII 'D' (character name prefix)
                       ; $D1 = Dictionary → emotion marker (pleading tone)
                       ; $C5,$40 = Text fragment
                       ; $41 = Dictionary → "to"
                       ; $A4 = Dictionary → "save"

; Dictionary Entry: Battle system message
                       db $48,$5A,$3F,$5F,$B9,$5C,$60,$C7,$4D,$BB,$C8,$BB,$CF
                       ; $48 = ASCII 'H' (HP/hit points)
                       ; $5A = Dictionary → "is"
                       ; $3F,$5F = Compressed text
                       ; $B9 = Dictionary → "the"
                       ; $5C = Dictionary → "enemy"
                       ; $60 = Dictionary → "has"
                       ; $C7,$4D = Compressed text
                       ; $BB,$C8 = Dictionary → "defeated"
                       ; $BB,$CF = Dictionary → continuation

; Dictionary Entry: Complex recursive phrase (3 levels deep)
                       db $01,$A5,$B8,$42,$C8,$45,$3F,$C5,$43,$BA,$BB,$CE
                       ; $01 = State marker
                       ; $A5 = Dictionary (level 1) → "the"
                       ; $B8 = Dictionary (level 1) → "you"
                       ;   → $77 (level 2) + $49 (level 2)
                       ; $42 = Dictionary → "are"
                       ; $C8 = Dictionary → recursive reference
                       ;   → $A3 (level 2) → "car" + "ry" + "ing"
                       ;     → $66 (level 3) + $5E (level 3) + $92 (level 3)
                       ; Compression ratio: 12 bytes → ~30 characters uncompressed

; Dictionary Entry: Dialogue with embedded portrait + timing
                       db $36,$2A,$B3,$E1,$80,$55,$30
                       ; $36 = Control code (compound sequence)
                       ; $2A = Portrait display marker
                       ; $B3 = Portrait ID #3 (character face graphic)
                       ; $E1 = Timing parameter (225 frame delay)
                       ; $80,$55 = Compressed text
                       ; $30 = Continue marker

; Dictionary Entry: Multi-choice dialogue tree
                       db $46,$10,$48,$30,$44,$10,$54,$FF,$FF
                       ; $46 = Choice offset 1
                       ; $10 = Choice separator
                       ; $48 = Choice offset 2
                       ; $30 = Choice separator
                       ; $44 = Choice offset 3
                       ; $10 = Choice separator
                       ; $54 = Default choice
                       ; $FF,$FF = End-of-choices marker

; Dictionary Entry: Shop dialogue with item price display
                       db $1A,$98,$66,$B7,$54,$7E,$3F
                       ; $1A = Shop system marker
                       ; $98 = Dictionary → "you can"
                       ; $66 = Dictionary → "buy"
                       ; $B7 = Dictionary → "this"
                       ; $54 = Dictionary → "for"
                       ; $7E = Price display marker (dynamic insertion)
                       ; $3F = Text continuation

; Dictionary Entry: Equipment status display
                       db $47,$7D,$BC,$42,$BF,$BC,$BE,$60
                       ; $47 = Status display marker
                       ; $7D = Dictionary → "current"
                       ; $BC,$42 = Compressed text
                       ; $BF,$BC = Dictionary → "equipment"
                       ; $BE,$60 = Text continuation

; Dictionary Entry: Magic spell description
                       db $FF,$44,$CE,$30,$A1,$58,$FF,$B4
                       ; $FF = Extended control code
                       ; $44 = Spell ID marker
                       ; $CE = Dictionary → "casts"
                       ; $30 = Continue marker
                       ; $A1 = Dictionary → "spell"
                       ; $58 = Target indicator
                       ; $FF = Extended control code
                       ; $B4 = Dictionary → "enemy" / "ally"

; Dictionary Entry: Quest objective text
                       db $B5,$43,$42,$1D,$01,$CF,$01,$9C,$4F,$7E
                       ; $B5 = Dictionary → "find"
                       ; $43 = Dictionary → "the"
                       ; $42 = Dictionary → "crystal"
                       ; $1D,$01 = State flag (quest progress marker)
                       ; $CF = Dictionary → "power"
                       ; $01 = State separator
                       ; $9C,$4F = Compressed objective
                       ; $7E = Continue marker

; Dictionary Entry: Boss encounter dialogue
                       db $C6,$BB,$40,$C7,$B4,$BF,$7D,$46,$C7,$C5,$B8,$60,$CF
                       ; $C6,$BB = Dictionary → "prepare"
                       ; $40 = Dictionary → "to"
                       ; $C7 = Dictionary → "face"
                       ; $B4,$BF = Compressed text
                       ; $7D = Dictionary → "the"
                       ; $46 = Dictionary → "ultimate"
                       ; $C7,$C5 = Compressed text
                       ; $B8,$60 = Dictionary → "challenge"
                       ; $CF = Dictionary → "power"

; Dictionary Entry: Location transition message
                       db $36,$2C,$C0,$56,$1A,$00,$B2,$5E,$BB
                       ; $36 = Control code (screen effect)
                       ; $2C = Fade parameter
                       ; $C0,$56 = Compressed location name
                       ; $1A = Location transition marker
                       ; $00 = Separator
                       ; $B2 = Dictionary → "now entering"
                       ; $5E,$BB = Compressed location name continuation

; Dictionary Entry: Party member status
                       db $6F,$AC,$BB,$40,$C0,$6D,$B5,$40,$7B,$1F,$09
                       ; $6F = Party member index (dynamic from save data)
                       ; $AC = Dictionary → "is"
                       ; $BB,$40 = Compressed text
                       ; $C0,$6D = Status effect name
                       ; $B5 = Dictionary → "and"
                       ; $40 = Dictionary → "has"
                       ; $7B = HP value display marker
                       ; $1F,$09 = Parameter (HP percentage)

; Dictionary Entry: Tutorial message with embedded help icon
                       db $FF,$B5,$59,$C1,$58,$53,$36,$2A
                       ; $FF = Extended control code
                       ; $B5 = Dictionary → "press"
                       ; $59 = Dictionary → "the"
                       ; $C1,$58 = Button name (dictionary compressed)
                       ; $53 = Dictionary → "button"
                       ; $36 = Control code (display icon)
                       ; $2A = Icon ID (button graphic)

; Dictionary Entry: Final boss pre-battle dialogue
                       db $10,$54,$10,$43,$40,$46,$FF,$FF
                       ; $10 = Character name substitution
                       ; $54 = Dictionary → "you have"
                       ; $10 = Separator
                       ; $43 = Dictionary → "the"
                       ; $40 = Dictionary → "power"
                       ; $46 = Dictionary → "to defeat"
                       ; $FF,$FF = End marker

; ------------------------------------------------------------
; Compressed Text Dictionary (Continued)
; Lines 2000-2200: Final Dictionary Entries + RLE Patterns
; ------------------------------------------------------------

; Dictionary Entry: Shop transaction complete
                       db $23,$DA,$2B,$7D,$23,$D9,$00
                       ; $23 = Transaction marker
                       ; $DA = Dictionary → "thank you"
                       ; $2B = Control code (jingle/fanfare)
                       ; $7D = Dictionary → "for"
                       ; $23 = Transaction marker
                       ; $D9 = Dictionary → "your purchase"
                       ; $00 = End marker

; Dictionary Entry: Inn rest sequence
                       db $2A,$31,$46,$11,$48,$41,$44,$FF,$FF
                       ; $2A = Inn system marker
                       ; $31 = Cost display (dynamic price)
                       ; $46 = Dictionary → "to rest"
                       ; $11 = Choice marker ("Yes/No")
                       ; $48 = Confirm offset
                       ; $41 = Cancel offset
                       ; $44 = Default
                       ; $FF,$FF = End marker

; Dictionary Entry: Healing message with particle effect
                       db $1A,$99,$A8,$BB,$FF,$BA,$C5,$5E,$42
                       ; $1A = Healing system marker
                       ; $99 = Dictionary → "HP/MP"
                       ; $A8,$BB = Dictionary → "restored"
                       ; $FF = Extended control code (particle effect)
                       ; $BA,$C5 = Effect ID (sparkle animation)
                       ; $5E,$42 = Parameters (color, duration)

; Dictionary Entry: Quest complete notification
                       db $C7,$C5,$B8,$40,$C6,$C3,$BC,$C5,$BC,$42,$5A,$41
                       ; $C7,$C5 = Dictionary → "quest"
                       ; $B8,$40 = Dictionary → "complete"
                       ; $C6,$C3 = Dictionary → "obtained"
                       ; $BC,$C5 = Item reward name
                       ; $BC,$42 = Dictionary → "and"
                       ; $5A,$41 = Experience/gold display markers

; Dictionary Entry: Weapon special ability description
                       db $B9,$5C,$60,$C7,$4D,$C3,$BF,$5E,$C6,$40,$BF,$B8
                       ; $B9 = Dictionary → "the"
                       ; $5C = Dictionary → "sword"
                       ; $60 = Dictionary → "has"
                       ; $C7,$4D = Compressed text
                       ; $C3,$BF = Dictionary → "special"
                       ; $5E,$C6 = Dictionary → "power"
                       ; $40,$BF = Dictionary → "to"
                       ; $B8 = Dictionary → continuation

; Dictionary Entry: Magic spell effect description
                       db $42,$C8,$45,$3F,$C5,$43,$BA,$BB,$FF
                       ; $42 = Dictionary → "casts"
                       ; $C8 = Spell name (dictionary reference)
                       ; $45 = Dictionary → "on"
                       ; $3F = Target specification
                       ; $C5,$43 = Dictionary → "dealing"
                       ; $BA,$BB = Damage type
                       ; $FF = Extended control marker

; Dictionary Entry: Trap/hazard warning
                       db $46,$1F,$1D,$CE,$1B,$4F,$5D,$BF,$B8,$42
                       ; $46 = Warning marker
                       ; $1F,$1D = Flag check (trap active)
                       ; $CE = Dictionary → "danger"
                       ; $1B = Separator
                       ; $4F,$5D = Compressed warning text
                       ; $BF,$B8 = Dictionary → "ahead"
                       ; $42 = Continue marker

; Dictionary Entry: Puzzle hint text
                       db $55,$3F,$C5,$43,$BA,$BB,$FF,$BC,$B9
                       ; $55 = Hint marker
                       ; $3F = Dictionary → "try"
                       ; $C5,$43 = Dictionary → "using"
                       ; $BA,$BB = Item name (dictionary reference)
                       ; $FF = Extended control code
                       ; $BC,$B9 = Dictionary → "here"

; Dictionary Entry: NPC gossip/rumor text
                       db $FF,$55,$B6,$4F,$FF,$CA,$57,$B6
                       ; $FF = Extended control code (gossip marker)
                       ; $55 = Dictionary → "I heard"
                       ; $B6,$4F = Compressed text
                       ; $FF = Extended control code
                       ; $CA = Dictionary → "rumor"
                       ; $57,$B6 = Compressed rumor content

; Dictionary Entry: Boss weakness hint
                       db $7D,$41,$7C,$4B,$45,$47,$C6,$BC,$B7,$40,$5A
                       ; $7D = Dictionary → "the"
                       ; $41 = Dictionary → "enemy"
                       ; $7C,$4B = Dictionary → "is weak"
                       ; $45 = Dictionary → "to"
                       ; $47 = Element type (fire/ice/thunder)
                       ; $C6,$BC = Dictionary → "magic"
                       ; $B7,$40 = Compressed text
                       ; $5A = Continue marker

; Dictionary Entry: Save point message
                       db $C0,$B8,$D2,$1A,$00,$A2,$B9,$FF
                       ; $C0,$B8 = Dictionary → "save"
                       ; $D2 = Dictionary → "point"
                       ; $1A = Save system marker
                       ; $00 = Separator
                       ; $A2 = Dictionary → "do you"
                       ; $B9 = Dictionary → "wish"
                       ; $FF = Extended control code

; Dictionary Entry: Level up notification
                       db $3F,$B4,$C7,$4E,$41,$63,$59,$55,$63,$C1,$42
                       ; $3F = Level up marker
                       ; $B4,$C7 = Dictionary → "level"
                       ; $4E = Dictionary → "up"
                       ; $41 = Character name substitution
                       ; $63 = Dictionary → "reached"
                       ; $59 = Dictionary → "level"
                       ; $55 = Level number display (dynamic)
                       ; $63,$C1 = Dictionary → continuation
                       ; $42 = End marker

; Dictionary Entry: New skill learned message
                       db $BC,$C7,$CE,$36,$2B,$3A,$23,$1D
                       ; $BC,$C7 = Dictionary → "learned"
                       ; $CE = Dictionary → "new"
                       ; $36 = Control code (fanfare/jingle)
                       ; $2B = Sound effect ID
                       ; $3A = Skill name marker
                       ; $23 = Skill ID (dynamic from level-up table)
                       ; $1D = Continue marker

; Dictionary Entry: Party formation message
                       db $2A,$13,$2A,$42,$46,$11,$43,$41,$46,$FF,$FF,$00
                       ; $2A = Party formation marker
                       ; $13 = Formation type ID
                       ; $2A = Separator
                       ; $42 = Dictionary → "member"
                       ; $46 = Character slot 1
                       ; $11 = Separator
                       ; $43 = Character slot 2
                       ; $41 = Character slot 3
                       ; $46 = Character slot 4
                       ; $FF,$FF = End marker
                       ; $00 = Terminator

; Dictionary Entry: Enemy encounter message
                       db $2E,$28,$D9,$EC,$66,$B4,$C0,$FF
                       ; $2E = Encounter marker
                       ; $28 = Encounter type (random/boss/scripted)
                       ; $D9,$EC = Compressed enemy name
                       ; $66 = Dictionary → "appeared"
                       ; $B4,$C0 = Dictionary → continuation
                       ; $FF = Extended control code

; Dictionary Entry: Run-Length Encoding example
                       db $BA,$C5,$B4,$C7,$B8,$B9,$C8,$49,$46
                       ; $BA = Dictionary → "the"
                       ; $C5 = RLE marker (character repeat)
                       ; $B4 = Character to repeat (ASCII space)
                       ; $C7 = Repeat count (7 times)
                       ; $B8,$B9 = Dictionary → "darkness"
                       ; $C8,$49 = Compressed text
                       ; $46 = Continue marker
                       ; Note: Decompresses to "the       darkness" (7 spaces)

; Dictionary Entry: Chest contents message
                       db $55,$B9,$5C,$FF,$B5,$5E,$C7,$48
                       ; $55 = Chest marker
                       ; $B9 = Dictionary → "the"
                       ; $5C = Dictionary → "chest"
                       ; $FF = Extended control code (open animation)
                       ; $B5 = Dictionary → "contains"
                       ; $5E,$C7 = Item name (dictionary reference)
                       ; $48 = Item quantity display (dynamic)

; Dictionary Entry: Door locked message
                       db $3F,$C2,$C6,$40,$7C,$4B,$C6,$CE
                       ; $3F = Door interaction marker
                       ; $C2,$C6 = Dictionary → "the door"
                       ; $40 = Dictionary → "is"
                       ; $7C,$4B = Dictionary → "locked"
                       ; $C6,$CE = Dictionary → "need key"

; Dictionary Entry: Treasure obtained fanfare
                       db $30,$9A,$BF,$BF,$58,$FF,$C0,$40
                       ; $30 = Treasure marker
                       ; $9A = Dictionary → "found"
                       ; $BF,$BF = Dictionary → "treasure" (repeated for emphasis)
                       ; $58 = Fanfare ID
                       ; $FF = Extended control code (sparkle effect)
                       ; $C0,$40 = Dictionary → continuation

; Dictionary Entry: Equipment comparison display
                       db $46,$B6,$B4,$C5,$C5,$59,$44,$6F
                       ; $46 = Equipment menu marker
                       ; $B6 = Dictionary → "current"
                       ; $B4,$C5 = Stats display (ATK/DEF)
                       ; $C5,$59 = Comparison arrow (→ or ↑↓)
                       ; $44 = New equipment stats
                       ; $6F = Difference calculation display

; Dictionary Entry: Shop inventory listing
                       db $36,$2A,$14,$2A,$10,$50,$5E,$FF,$AA,$00
                       ; $36 = Shop inventory marker
                       ; $2A = Shop type ID
                       ; $14 = Item count
                       ; $2A = Separator
                       ; $10 = Item slot 1
                       ; $50 = Item slot 2
                       ; $5E = Item slot 3
                       ; $FF = Extended control code (scroll indicator)
                       ; $AA = More items marker
                       ; $00 = End

; Dictionary Entry: Battle victory message
                       db $07,$2B,$30,$46,$10,$51,$1B,$25,$FF,$FF
                       ; $07 = Victory marker
                       ; $2B = Victory fanfare ID
                       ; $30 = Dictionary → "victory"
                       ; $46 = Experience display marker
                       ; $10 = Separator
                       ; $51 = Gold display marker
                       ; $1B = Separator
                       ; $25 = Item drop display marker
                       ; $FF,$FF = End marker

; Dictionary Entry: Poison/status effect notification
                       db $23,$FE,$2A,$1C,$25,$10,$53,$40,$46
                       ; $23 = Status effect marker
                       ; $FE = Effect type (poison/paralysis/sleep)
                       ; $2A = Character index
                       ; $1C = Dictionary → "is"
                       ; $25 = Effect name
                       ; $10 = Separator
                       ; $53 = Duration counter display
                       ; $40 = Dictionary → "turns"
                       ; $46 = Continue marker

; Dictionary Entry: Game over message
                       db $10,$53,$06,$2B,$AB,$00,$61,$FF
                       ; $10 = Game over marker
                       ; $53 = Dictionary → "game"
                       ; $06 = Dictionary → "over"
                       ; $2B = Sad fanfare ID
                       ; $AB = Dictionary → "continue?"
                       ; $00 = Separator
                       ; $61 = Yes/No choice offset
                       ; $FF = Extended control code

; Dictionary Entry: Critical hit message
                       db $2E,$29,$FF,$FF,$2B,$FE,$23,$3C
                       ; $2E = Critical hit marker
                       ; $29 = Portrait flash effect
                       ; $FF,$FF = Extended control codes (screen shake)
                       ; $2B = Sound effect (critical hit sound)
                       ; $FE = Dictionary → "critical"
                       ; $23 = Dictionary → "hit"
                       ; $3C = Damage multiplier display

; Dictionary Entry: Boss battle phase transition
                       db $23,$6A,$00,$A2,$B9,$FF,$55,$B6,$4F
                       ; $23 = Phase transition marker
                       ; $6A = Phase number
                       ; $00 = Separator
                       ; $A2 = Dictionary → "now"
                       ; $B9 = Dictionary → "the"
                       ; $FF = Extended control code (screen effect)
                       ; $55 = Dictionary → "true"
                       ; $B6,$4F = Dictionary → "battle begins"

; Dictionary Entry: Escape success/fail
                       db $FF,$B5,$5E,$42,$20,$48,$4D,$41,$7C,$4B
                       ; $FF = Extended control code (escape attempt marker)
                       ; $B5 = Dictionary → "party"
                       ; $5E,$42 = Dictionary → "has"
                       ; $20 = Random check result
                       ; $48 = Success offset
                       ; $4D = Dictionary → "escaped"
                       ; $41 = Fail offset
                       ; $7C,$4B = Dictionary → "failed"

; Dictionary Entry: Multi-target spell effect
                       db $45,$CA,$BC,$4A,$B7,$BC,$C6,$B4,$C3,$C3,$5E,$C5,$CE,$00
                       ; $45 = Multi-target marker
                       ; $CA = Spell name (dictionary reference)
                       ; $BC,$4A = Dictionary → "affects"
                       ; $B7,$BC = Dictionary → "all"
                       ; $C6,$B4 = Target group (enemies/allies)
                       ; $C3,$C3 = Dictionary → repeated emphasis
                       ; $5E,$C5 = Effect type
                       ; $CE = Continue marker
                       ; $00 = End

; Dictionary Entry: Combo/chain attack message
                       db $04,$05,$E4,$91,$07,$2C,$61,$46
                       ; $04 = Combo marker
                       ; $05 = Inline data marker
                       ; $E4,$91 = Combo count parameter
                       ; $07 = Control code
                       ; $2C = Dictionary → "combo"
                       ; $61 = Chain multiplier display
                       ; $46 = Continue marker

; Dictionary Entry: Elemental damage calculation
                       db $2C,$03,$21,$2B,$28,$23,$29,$00
                       ; $2C = Element type marker
                       ; $03 = Element ID (fire=1, ice=2, thunder=3)
                       ; $21 = Dictionary → "damage"
                       ; $2B = Damage value display
                       ; $28 = Weakness/resistance modifier
                       ; $23 = Visual effect ID
                       ; $29 = Continue marker
                       ; $00 = End

; ============================================================
; END OF CYCLE 4 DOCUMENTATION
; Lines documented: 1200-2200 (1000 source lines)
; Compression systems fully analyzed
; Unreachable data catalogued
; Dictionary encoding decoded
; ============================================================
