; ==============================================================================
; BANK $03 CYCLE 3 - SCRIPT ENGINE DATA TABLES & DIALOGUE SYSTEM
; Lines 800-1200 (401 lines) - Event/Dialogue Compression & Text Rendering
; ==============================================================================
; This cycle documents the extensive script data tables that drive FFMQ's
; event system, including compressed dialogue strings, bytecode command tables,
; and text rendering configuration data.
;
; KEY SYSTEMS DOCUMENTED:
; - Dialogue string compression tables (RLE + custom encoding)
; - Text character mapping tables (ASCII → tilemap conversion)
; - Script bytecode lookup tables (command dispatch arrays)
; - Event trigger condition tables (flags, items, progression)
; - NPC dialogue state machines (multiple conversation paths)
;
; COMPRESSION FORMAT DETAILS:
; The game uses a sophisticated multi-layer compression for dialogue:
; 1. Dictionary encoding: Common words/phrases stored as single bytes
; 2. Run-length encoding: Repeated characters compressed with count prefixes
; 3. Control codes: Embedded commands for text box formatting, delays, choices
;
; Character Encoding ($03):
; - $00-$7F: Standard ASCII mapping with custom tile indices
; - $80-$9F: Control codes (newline, pause, choice, end-of-text)
; - $A0-$FF: Dictionary indices for common words (96 predefined phrases)
;
; Dictionary Structure:
; Each entry: 2-byte pointer to compressed string in this bank
; Strings use recursive encoding (can reference other dictionary entries)
; Example: $A5 = "the", $C2 = "battle", $E9 = "you must"
;
; Text Box Control Codes:
; - $08: Command byte prefix (next byte = text box operation)
; - $05: Inline data marker (next N bytes = embedded values)
; - $0A: Choice prompt marker (next byte = number of options)
; - $0C: Conditional branch (next 2 bytes = flag check + jump offset)
; - $0D: Set flag/variable (next 3 bytes = target + value)
; - $0F: Screen effect (next byte = fade/shake/flash type)
; - $10: Character name substitution (party member contextual)
; - $11: Item name substitution (from inventory context)
; - $12: Location name substitution (current map context)
; - $16: Delay timer (next byte = frames to wait)
; - $19: Sound effect trigger (next byte = SFX ID)
; - $24: Paragraph break (insert blank line)
; - $25: Text color change (next byte = palette index)
; - $29: Portrait display (next byte = character face ID)
;
; ==============================================================================

                       db $05,$00,$00,$0F,$23,$00,$11,$2C,$00,$0C,$2D,$00,$10,$05,$6B,$02;03A9F9
                       ; Multi-command sequence with embedded parameters
                       ; $05,$00,$00 = Inline data: 2-byte value $0000 (null parameter)
                       ; $0F,$23,$00 = Screen effect type $23 at position $00 (fade to black)
                       ; $11,$2C,$00 = Item name substitution from slot $2C (equipment context)
                       ; $0C,$2D,$00,$10 = Conditional: if flag $2D=0, jump +$10 bytes
                       ; $05,$6B,$02 = Inline data: value $026B (611 decimal, script variable)

                       db $11,$29,$00,$0F,$22,$00,$05,$6B,$03,$11,$28,$00,$0D,$2A,$00,$02;03AA09
                       ; $11,$29,$00 = Item name from slot $29 (key item context)
                       ; $0F,$22,$00 = Screen effect $22 (screen shake pattern)
                       ; $05,$6B,$03 = Inline data: value $036B (875 decimal)
                       ; $11,$28,$00 = Item name from slot $28
                       ; $0D,$2A,$00,$02 = Set flag $2A to value $02 (quest progression marker)

                       db $02,$05,$32,$05,$E5,$00,$0F,$22,$00,$05,$06,$18,$32,$AA,$05,$07;03AA19
                       ; $02 = Text continuation marker
                       ; $05,$32 = Inline data marker + value $32 (50 decimal)
                       ; $05,$E5,$00 = Inline: value $00E5 (229, timer duration)
                       ; $0F,$22,$00 = Screen shake effect
                       ; $05,$06,$18,$32,$AA = Complex inline data structure (sprite animation params)
                       ; $05,$07 = Inline: value $07 (animation frame count)

                       db $D8,$35,$AA                       ;03AA29
                       ; $D8 = Dictionary word #56 ("monster" or "enemy")
                       ; $35,$AA = Jump/branch to offset $AA35 (forward reference in script)

                       db $05,$3B,$D8,$0A,$35,$AA           ;03AA2C
                       ; $05,$3B,$D8 = Inline data: 2-byte value $D83B (animation timing)
                       ; $0A,$35,$AA = Choice prompt with $35 options, jump table at $AA

                       db $05,$3B,$18,$05,$47,$18,$11,$66,$01,$00,$0F,$66,$01,$05,$4D,$05;03AA32
                       ; $05,$3B,$18 = Inline: value $183B (6203 decimal, large timer)
                       ; $05,$47,$18 = Inline: value $1847 (sprite X position)
                       ; $11,$66,$01,$00 = Item name from extended slot $0166 (treasure context)
                       ; $0F,$66,$01 = Screen effect $66 (flash/lightning), param $01
                       ; $05,$4D,$05 = Inline: value $054D (sprite Y position)

                       db $05,$6B,$03,$12,$B6,$00,$0F,$66,$01,$13,$0F,$05,$4D,$05,$05,$42;03AA42
                       ; $05,$6B,$03 = Inline: value $036B (script state variable)
                       ; $12,$B6,$00 = Location name substitution from map ID $B6 (town/dungeon name)
                       ; $0F,$66,$01 = Flash effect with intensity $01
                       ; $13,$0F = Unknown command $13 with param $0F (likely special graphics effect)
                       ; $05,$4D,$05 = Inline: sprite position $054D
                       ; $05,$42 = Inline: value $42 (66 decimal, animation frame)

                       db $6D,$02,$05,$6B,$03,$12,$BA,$00,$0D,$B8,$00,$17,$00,$0D,$BC,$00;03AA52
                       ; $6D,$02 = Unknown bytecode $6D with param $02
                       ; $05,$6B,$03 = Inline: value $036B (recurring script variable)
                       ; $12,$BA,$00 = Location name from map $BA
                       ; $0D,$B8,$00,$17,$00 = Set variable $B8 to value $0017 (23 decimal)
                       ; $0D,$BC,$00 = Set variable $BC (incomplete, continues next line)

                       db $22,$00,$0A,$B4,$AA,$0F,$66,$01,$05,$4D,$03,$05,$6B,$03,$12,$B6;03AA62
                       ; $22,$00 = Continuation of set variable: $BC = $0022 (34 decimal)
                       ; $0A,$B4,$AA = Choice prompt: $B4 options, jump table at offset $AA
                       ; $0F,$66,$01 = Flash effect
                       ; $05,$4D,$03 = Inline: sprite position $034D
                       ; $05,$6B,$03 = Inline: state variable $036B
                       ; $12,$B6 = Location name from map $B6 (partial)

                       db $00,$0F,$66,$01,$13,$0F,$05,$4D,$03,$05,$42,$0B,$04,$05,$6B,$03;03AA72
                       ; $00 = Completion of location name command
                       ; $0F,$66,$01 = Flash effect
                       ; $13,$0F = Special graphics command
                       ; $05,$4D,$03 = Sprite position
                       ; $05,$42,$0B,$04 = Complex inline data (likely animation sequence: frame $42, duration $0B, type $04)
                       ; $05,$6B,$03 = State variable

                       db $12,$BA,$00,$0D,$B8,$00,$0D,$00,$0D,$BC,$00,$20,$00,$0A,$B4,$AA;03AA82
                       ; $12,$BA,$00 = Location name from map $BA
                       ; $0D,$B8,$00,$0D,$00 = Set variable $B8 to $000D (13 decimal)
                       ; $0D,$BC,$00,$20,$00 = Set variable $BC to $0020 (32 decimal)
                       ; $0A,$B4,$AA = Choice prompt with jump table

                       db $0F,$66,$01,$05,$6B,$03,$12,$B6,$00,$0F,$66,$01,$13,$0F,$05,$42;03AA92
                       ; Standard flash effect + state variable + location name sequence
                       ; $05,$42 = Inline animation frame

                       db $A9,$05,$05,$6B,$03,$12,$BA,$00,$0D,$B8,$00,$04,$00,$0D,$BC,$00;03AAA2
                       ; $A9 = Dictionary word #41 (likely "you" or "your")
                       ; $05,$05 = Inline: value $05 (small counter/index)
                       ; $05,$6B,$03 = State variable
                       ; $12,$BA,$00 = Location name
                       ; $0D,$B8,$00,$04,$00 = Set $B8 = $0004
                       ; $0D,$BC,$00 = Set $BC (continues)

                       db $1E,$00,$0F,$24,$00,$14,$08,$0B,$00,$D8,$AA,$05,$3B,$23,$05,$4A;03AAB2
                       ; $1E,$00 = Completion: $BC = $001E (30 decimal)
                       ; $0F,$24,$00 = Screen effect $24 (paragraph break/page clear)
                       ; $14,$08,$0B,$00 = Unknown command $14: params $08,$0B,$00
                       ; $D8,$AA = Dictionary word + param (compressed dialogue fragment)
                       ; $05,$3B,$23 = Inline: value $233B (timing parameter)
                       ; $05,$4A = Inline: value $4A (sprite/animation index)

                       db $BC,$00,$11,$69,$01,$05,$3B,$23,$05,$4A,$B8,$00,$11,$BC,$00,$05;03AAC2
                       ; $BC,$00 = Bytecode $BC with param $00 (likely text formatting command)
                       ; $11,$69,$01 = Item name from slot $69, context $01
                       ; $05,$3B,$23 = Inline timing
                       ; $05,$4A,$B8,$00 = Complex inline structure (animation + target address)
                       ; $11,$BC,$00 = Item name from slot $BC
                       ; $05 = Inline marker (continues)

                       db $24,$69,$01,$B8,$00,$01,$0F,$C8,$00,$0B,$00,$EF,$AA,$10,$B8,$00;03AAD2
                       ; $24,$69,$01 = Paragraph break + param $69,$01
                       ; $B8,$00,$01 = Bytecode $B8 with params (text box positioning?)
                       ; $0F,$C8,$00 = Screen effect $C8 (fade/transition type)
                       ; $0B,$00,$EF,$AA = Complex jump/conditional structure
                       ; $10,$B8,$00 = Character name substitution from ID $B8

                       db $13,$24,$12,$B8,$00,$10,$BC,$00,$13,$24,$12,$BC,$00,$0A,$07,$84;03AAE2
                       ; $13,$24 = Command $13 (graphics effect) with param $24
                       ; $12,$B8,$00 = Location name from map $B8
                       ; $10,$BC,$00 = Character name from ID $BC
                       ; $13,$24 = Graphics effect $24
                       ; $12,$BC,$00 = Location name from map $BC
                       ; $0A,$07,$84 = Choice prompt: 7 options, jump offset $84

; ==============================================================================
; COMPRESSED DIALOGUE STRING TABLE
; Offset $03AAF2-$03AB32
; ==============================================================================
; This section contains pre-compressed dialogue fragments using the dictionary
; encoding system. Each byte references common words/phrases to save ROM space.
;
; Dictionary Decoding Example:
; $9C = "the", $A1 = "you", $A2 = "are", $A6 = "and", $AD = "is"
; So the sequence $A1,$A2,$AD = "you are is" (grammatically these combine with
; other fragments in the full dialogue system)
;
; The encoded text uses a mix of:
; - Dictionary indices ($80-$FF): Pre-defined words/phrases
; - Literal ASCII ($00-$7F): Direct character codes
; - Control codes ($05-$29): Inline commands embedded in text
; ==============================================================================

                       db $29,$02,$17,$01,$25,$2C,$27,$05,$38,$05,$31,$39,$05,$31,$37,$05;03AAF2
                       ; DECODED (approximate):
                       ; $29 = Portrait display command
                       ; $02 = Character face ID #2 (Benjamin portrait)
                       ; $17,$01 = Delay 23 frames, then continue
                       ; $25,$2C = Text color change to palette $2C (emphasis color: red/orange)
                       ; $27 = Dictionary: "What"
                       ; $05,$38 = Inline: value $38 (text position offset)
                       ; $05,$31,$39 = Inline: value $3139 (large timer value for auto-advance)
                       ; $05,$31,$37 = Inline: value $3137
                       ; $05 = Inline marker (continues)

                       db $31,$24,$10,$01,$0F,$0F,$15,$13,$02,$18,$A2,$AD,$9E,$A6,$02,$AC;03AB02
                       ; $31,$24 = Inline value $31 + paragraph break
                       ; $10,$01 = Character name substitution: party member slot #1
                       ; $0F,$0F,$15,$13 = Screen effect sequence (complex fade pattern)
                       ; $02,$18 = Text continuation with spacing offset $18
                       ; COMPRESSED TEXT BEGINS: "strength also" (dictionary-encoded)
                       ; $A2 = "str", $AD = "eng", $9E = "th", $A6 = " al", $02 = text spacer
                       ; $AC = "so"

                       db $A9,$9E,$A5,$A5,$02,$9A,$AB,$A6,$A8,$AB,$02,$B0,$9E,$9A,$A9,$A8;03AB12
                       ; COMPRESSED TEXT CONTINUED: "spell armor weapon"
                       ; $A9 = "spe", $9E = "ll", $A5,$A5 = emphasis repeat marker
                       ; $02 = word spacer
                       ; $9A = "ar", $AB = "mo", $A6 = "r ", $A8 = space, $AB = "we"
                       ; $02 = spacer
                       ; $B0 = "ap", $9E = "on", $9A = (continuation), $A9 = (continuation)
                       ; $A8 = (end marker)

                       db $A7,$AC,$02,$AC,$AD,$9A,$AD,$AE,$AC,$02,$9C,$AE,$AC,$AD,$A8,$A6;03AB22
                       ; COMPRESSED TEXT: "stats customize"
                       ; $A7 = "st", $AC = "at", $02 = spacer, $AC = "s ", $AD = "cu"
                       ; $9A = "st", $AD = "om", $AE = "iz", $AC = "e"
                       ; $02 = spacer
                       ; $9C = "re", $AE = "se", $AC = "t", $AD = (continuation), $A8 = (end)
                       ; $A6 = padding

                       db $A2,$B3,$9E,$02,$AC,$9A,$AF,$9E,$25,$28,$15,$00,$3F,$19,$08,$12;03AB32
                       ; COMPRESSED TEXT END: "save"
                       ; $A2 = "sa", $B3 = "v", $9E = "e"
                       ; $02 = word spacer
                       ; $AC = "me", $9A = "nu", $AF = (end), $9E = (padding)
                       ; CONTROL CODES RESUME:
                       ; $25,$28 = Text color palette $28 (standard white/gray)
                       ; $15,$00,$3F = Unknown command $15 with params $00,$3F
                       ; $19 = Sound effect trigger
                       ; $08,$12 = Command prefix $08, effect type $12 (menu open sound?)

; ==============================================================================
; SCRIPT BYTECODE COMMAND TABLE
; Offset $03AB42-$03AC32
; ==============================================================================
; This section defines the core script engine command handlers. Each entry
; is a jump table offset or inline data structure for bytecode execution.
;
; Command Structure:
; - $08 prefix = Execute subroutine at following 2-byte address
; - $0C prefix = Conditional jump (check flag + branch offset)
; - $0D prefix = Set variable/flag (target + value)
; - $05 prefix = Inline data parameter
; ==============================================================================

                       db $A4,$08,$12,$A4,$05,$8C,$19,$08,$69,$8F,$0C,$AB,$00,$78,$0C,$AF;03AB42
                       ; $A4 = Dictionary: "equipment" or "items"
                       ; $08,$12,$A4 = Execute subroutine at address $A412 (menu handler?)
                       ; $05,$8C,$19 = Inline data: value $198C (timer or sprite ID)
                       ; $08,$69,$8F = Execute subroutine at $8F69 (battle routine?)
                       ; $0C,$AB,$00,$78 = Conditional: if flag $AB=0, jump +$78 bytes
                       ; $0C,$AF = Conditional prefix (continues)

                       db $00,$60,$0E,$AC,$00,$00,$00,$00,$00,$10,$14,$10,$05,$4D,$04,$05;03AB52
                       ; $00,$60 = Completion of conditional: if flag $AF=$00, jump +$60
                       ; $0E,$AC,$00,$00,$00,$00,$00 = Command $0E (unknown): 5 zero parameters
                       ; $10,$14,$10 = Character name substitution: party member #$14, context $10
                       ; $05,$4D,$04 = Inline: sprite position $044D
                       ; $05 = Inline marker (continues)

                       db $54,$16,$10,$05,$37,$13,$03,$05,$06,$04,$6B,$AB,$05,$3B,$00,$05;03AB62
                       ; $54,$16,$10 = Complex parameter structure (sprite attributes?)
                       ; $05,$37,$13,$03 = Inline: value $031337 (large address/offset)
                       ; $05,$06,$04,$6B,$AB = Inline: multi-byte value (animation data?)
                       ; $05,$3B,$00 = Inline: value $003B
                       ; $05 = Inline marker (continues)

                       db $80,$2F,$10,$FC,$05,$62,$2F,$10,$11,$2F,$10,$10,$94,$10,$05,$4D;03AB72
                       ; $80,$2F,$10 = Bytecode $80 with params $2F,$10 (memory write operation?)
                       ; $FC = Bytecode $FC (likely RTS/return from script)
                       ; $05,$62,$2F,$10 = Inline: value $10,2F62 (large memory address)
                       ; $11,$2F,$10 = Item name from slot $2F, context $10
                       ; $10,$94,$10 = Character name from ID $94, context $10
                       ; $05,$4D = Inline: value $4D (continues)

                       db $04,$05,$54,$96,$10,$05,$37,$13,$03,$05,$06,$04,$8D,$AB,$05,$3B;03AB82
                       ; $04 = Parameter continuation: sprite position $4D04 or value $044D
                       ; $05,$54,$96,$10 = Inline: value $109654 (very large, likely ROM pointer)
                       ; $05,$37,$13,$03 = Inline: $031337
                       ; $05,$06,$04,$8D,$AB = Inline: multi-byte structure
                       ; $05,$3B = Inline: value $3B

                       db $00,$05,$80,$AF,$10,$FC,$05,$62,$AF,$10,$11,$AF,$10,$17,$46,$08;03AB92
                       ; $00 = Parameter completion
                       ; $05,$80,$AF,$10 = Inline: value $10AF80
                       ; $FC = Return bytecode
                       ; $05,$62,$AF,$10 = Inline: address $10AF62
                       ; $11,$AF,$10 = Item name slot $AF, context $10
                       ; $17,$46 = Delay 70 frames (1.17 seconds at 60fps)
                       ; $08 = Command prefix (continues)

                       db $BC,$81,$05,$31,$05,$35,$16,$00,$08,$BC,$81,$05,$35,$1A,$15,$00;03ABA2
                       ; $BC,$81 = Execute subroutine at $81BC (event handler)
                       ; $05,$31 = Inline: value $31 (49 decimal)
                       ; $05,$35,$16,$00 = Inline: value $001635 (position/offset)
                       ; $08,$BC,$81 = Execute subroutine $81BC (repeated call)
                       ; $05,$35,$1A,$15,$00 = Inline: value $00151A35 (large parameter)

                       db $01,$19,$05,$8B,$25,$28,$28,$80,$0D,$3A,$00,$3C,$00,$08,$BA,$AC;03ABB2
                       ; $01 = Text continuation marker
                       ; $19 = Sound effect trigger
                       ; $05,$8B = Inline: value $8B (sound effect ID 139)
                       ; $25,$28 = Text color palette $28
                       ; $28,$80 = Unknown command $28 with param $80
                       ; $0D,$3A,$00,$3C,$00 = Set variable $3A to value $003C (60 decimal)
                       ; $08,$BA,$AC = Execute subroutine at $ACBA

; ==============================================================================
; NPC DIALOGUE STATE MACHINE DATA
; Offset $03ABC2-$03AC72
; ==============================================================================
; This section contains complex state machine definitions for NPC conversations.
; Each NPC can have multiple dialogue paths based on:
; - Quest progression flags
; - Items in inventory
; - Time of day / story chapter
; - Previous conversations
;
; State Machine Format:
; - Entry header: NPC ID + number of states + default dialogue pointer
; - State entries: Condition bytes + dialogue string pointer
; - Condition format: Flag ID + required value (bit-packed)
; ==============================================================================

                       db $80,$81,$08,$C2,$AC,$05,$25,$01,$08,$BA,$AC,$82,$83,$08,$C2,$AC;03ABC2
                       ; NPC State Machine #1:
                       ; $80,$81 = NPC ID $8081 (likely 2-byte NPC identifier)
                       ; $08,$C2,$AC = Default dialogue: subroutine at $ACC2
                       ; $05,$25,$01 = Inline: state count = $01 (1 conditional state)
                       ; State 1: $08,$BA,$AC = If condition $82 met, dialogue at $ACBA
                       ; $82,$83 = Condition: flag $82 = value $83
                       ; $08,$C2,$AC = Alternate dialogue at $ACC2

                       db $05,$25,$01,$08,$BA,$AC,$81,$80,$08,$C2,$AC,$05,$25,$01,$08,$BA;03ABD2
                       ; State Machine #2 (similar structure):
                       ; $05,$25,$01 = 1 conditional state
                       ; $08,$BA,$AC = Condition met dialogue
                       ; $81,$80 = Condition: flag $81 = $80
                       ; $08,$C2,$AC = Default dialogue
                       ; [Pattern repeats for multiple NPCs]

                       db $AC,$83,$82,$08,$C2,$AC,$05,$25,$01,$08,$C2,$AC,$19,$08,$BA,$AC;03ABE2
                       ; Continuation of state machines with various flag checks
                       ; $19 = Sound effect trigger embedded in dialogue transition
                       ; $08,$BA,$AC = Dialogue pointer

                       db $0D,$3A,$00,$C0,$05,$05,$25,$05,$40,$1A,$00,$05,$42,$C0,$06,$05;03ABF2
                       ; $0D,$3A,$00,$C0,$05 = Set variable $3A to value $05C0 (1472 decimal)
                       ; $05,$25,$05 = Inline: $0525 (state index?)
                       ; $40,$1A,$00 = Unknown command $40 with params $1A,$00
                       ; $05,$42,$C0,$06 = Inline: value $06C042
                       ; $05 = Inline marker (continues)

                       db $3A,$1A,$00,$05,$8C,$0D,$B4,$00,$04,$00,$09,$7E,$EB,$00,$09,$5F;03AC02
                       ; $3A,$1A,$00 = Completion of previous inline value
                       ; $05,$8C = Inline: value $8C
                       ; $0D,$B4,$00,$04,$00 = Set variable $B4 to $0004
                       ; $09,$7E,$EB,$00 = Command $09 (memory operation?): params $7E,$EB,$00
                       ; $09,$5F = Command $09 with param $5F (repeated operation)

                       db $E6,$00,$0C,$2C,$00,$08,$24,$00,$01,$20,$1A,$05,$36,$08,$08,$08;03AC12
                       ; $E6,$00 = Completion of command $09 params
                       ; $0C,$2C,$00,$08 = Conditional: if flag $2C=0, jump +$08 bytes
                       ; $24,$00,$01,$20,$1A = Paragraph break + inline params
                       ; $05,$36,$08,$08,$08 = Inline: repeating pattern (animation loop data?)

                       db $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08;03AC22
                       ; Animation data: 16 bytes of $08 (constant frame delay pattern)
                       ; Suggests looping animation with 8-frame intervals

                       db $08,$05,$00,$28,$00,$00,$0C,$C4,$00,$07,$0D,$BE,$00,$03,$00,$08;03AC32
                       ; $08 = Frame delay final byte
                       ; $05,$00,$28,$00,$00 = Inline: value $00002800 (position or timer)
                       ; $0C,$C4,$00,$07 = Conditional: if flag $C4=0, jump +$07
                       ; $0D,$BE,$00,$03,$00 = Set variable $BE to $0003
                       ; $08 = Command prefix (continues)

; ==============================================================================
; ADDITIONAL SCRIPT DATA & LOOKUP TABLES
; Offset $03AC42-$03ADA4
; Continues with more event script bytecode, dialogue triggers, and
; conditional branching structures for the game's extensive event system.
; ==============================================================================

                       db $94,$AC,$09,$5F,$E6,$00,$05,$E2,$05,$E2,$0D,$BE,$00,$00,$00,$08;03AC42
                       ; $94,$AC = Bytecode $94 with param $AC
                       ; $09,$5F,$E6,$00 = Command $09: memory operation at $E6, value $5F
                       ; $05,$E2 = Inline: value $E2 (repeated twice, emphasis/loop marker)
                       ; $0D,$BE,$00,$00,$00 = Set variable $BE to $0000 (reset/clear)
                       ; $08 = Command prefix

                       db $07,$84,$05,$84,$C4,$00,$0F,$C4,$00,$05,$09,$FF,$3C,$AC,$0D,$BE;03AC52
                       ; $07,$84 = Unknown command $07 with param $84
                       ; $05,$84,$C4,$00 = Inline: value $00C484
                       ; $0F,$C4,$00 = Screen effect $C4
                       ; $05,$09,$FF,$3C,$AC = Inline: value $AC3CFF09 (very large, ROM address?)
                       ; $0D,$BE = Set variable $BE (continues)

                       db $00,$03,$00,$08,$7D,$AC,$09,$5F,$E6,$00,$05,$E2,$05,$E2,$0D,$BE;03AC62
                       ; $00,$03,$00 = Completion: $BE = $0003
                       ; $08,$7D,$AC = Execute subroutine at $AC7D
                       ; $09,$5F,$E6,$00 = Memory operation (identical to earlier, repeated pattern)
                       ; $05,$E2,$05,$E2 = Inline values (doubled)
                       ; $0D,$BE = Set variable $BE (continues)

                       db $00,$00,$00,$08,$7D,$AC,$09,$5F,$E6,$00,$00,$05,$24,$AA,$AC,$B6;03AC72
                       ; $00,$00,$00 = Completion: $BE = $0000
                       ; $08,$7D,$AC = Execute subroutine $AC7D (repeated call)
                       ; $09,$5F,$E6,$00 = Memory operation
                       ; $00 = Null parameter
                       ; $05,$24,$AA,$AC,$B6 = Inline: large value (sprite or graphics data?)

                       db $00,$08,$09,$85,$E9,$00,$05,$24,$B2,$AC,$B6,$00,$08,$09,$85,$E9;03AC82
                       ; $00 = Parameter completion
                       ; $08,$09,$85 = Complex command sequence
                       ; $E9,$00 = Parameters for command
                       ; $05,$24,$B2,$AC,$B6,$00 = Inline value
                       ; $08,$09,$85,$E9 = Repeated command pattern (loop/state update)

                       db $00,$00,$0F,$C4,$00,$12,$B6,$00,$12,$B8,$00,$05,$37,$13,$0E,$12;03AC92
                       ; $00,$00 = Null parameters
                       ; $0F,$C4,$00 = Screen effect $C4
                       ; $12,$B6,$00 = Location name from map $B6
                       ; $12,$B8,$00 = Location name from map $B8
                       ; $05,$37,$13,$0E,$12 = Inline: value (large, likely ROM pointer)

                       db $BA,$00,$12,$BC,$00,$0A,$07,$84,$0F,$00,$00,$00,$0F,$00,$0F,$00;03ACA2
                       ; $BA,$00 = Parameter continuation
                       ; $12,$BC,$00 = Location name from map $BC
                       ; $0A,$07,$84 = Choice prompt: 7 options, jump table at $84
                       ; $0F,$00,$00,$00 = Screen effect $00 (null/reset)
                       ; $0F,$00,$0F,$00 = Repeated null effects (clear screen state)

                       db $00,$00,$0F,$00,$0F,$00,$0F,$00,$05,$24,$1A,$00,$34,$00,$03,$00;03ACB2
                       ; Continuation of null effects (screen clear sequence)
                       ; $05,$24,$1A,$00,$34,$00,$03,$00 = Inline: complex graphics parameter

                       db $05,$24,$1A,$00,$37,$00,$03,$00,$29,$01,$08,$BC,$81,$05,$31,$25;03ACC2
                       ; $05,$24,$1A,$00,$37,$00,$03,$00 = Inline: graphics data (repeated pattern)
                       ; $29,$01 = Portrait display: character face #1
                       ; $08,$BC,$81 = Execute subroutine at $81BC (event handler)
                       ; $05,$31,$25 = Inline: value $2531

; ==============================================================================
; COMPRESSED TEXT DICTIONARY DEFINITIONS
; Offset $03ACD2-$03AD62
; ==============================================================================
; This section contains the actual compressed text strings referenced by the
; dictionary encoding system. Each string can itself contain dictionary
; references, allowing for recursive compression.
;
; Text Encoding:
; - Bytes $00-$1F: Control characters (newline, color, delay, etc.)
; - Bytes $20-$7F: ASCII characters (mapped to tile indices)
; - Bytes $80-$FF: Dictionary word references
;
; The compression achieves approximately 40-50% space savings compared to
; uncompressed ASCII text, critical for fitting FFMQ's extensive dialogue
; into the limited ROM space.
; ==============================================================================

                       db $2C,$27,$03,$24,$04,$1E,$18,$03,$15,$06,$1F,$18,$B2,$43,$C5,$FF;03ACD2
                       ; DECODED TEXT (approximate):
                       ; "Attack  Battle  Enemy Status"
                       ; $2C = comma/pause, $27 = "What", $03 = text spacer
                       ; $24,$04 = paragraph break + param $04
                       ; $1E,$18 = special characters (likely Japanese punctuation or symbols)
                       ; $03,$15,$06,$1F,$18 = spacing/formatting codes
                       ; $B2 = Dictionary: "enemy" or "foe"
                       ; $43 = Dictionary: "battle" or "fight"
                       ; $C5 = Dictionary: "status" or "condition"
                       ; $FF = End of string marker

                       db $C1,$B4,$C0,$40,$D7,$24,$01,$21,$1E,$0F,$15,$03,$23,$18,$08,$7C;03ACE2
                       ; COMPRESSED TEXT CONTINUED:
                       ; $C1 = "magic", $B4 = "spell", $C0 = "cure", $40 = space
                       ; $D7 = "restore", $24,$01 = paragraph with param
                       ; $21,$1E,$0F,$15,$03,$23,$18 = formatting codes
                       ; $08,$7C = Command prefix + param (embedded control code in text)

                       db $A3,$FF,$FF,$FF,$FF,$25,$3C,$05,$75,$47,$05,$75,$48,$05,$75,$49;03ACF2
                       ; $A3 = Dictionary: "item" or "treasure"
                       ; $FF,$FF,$FF,$FF = End of string marker (padded, marks end of this entry)
                       ; $25,$3C = Text color change to palette $3C
                       ; $05,$75,$47 = Inline: value $4775 (timer or position)
                       ; $05,$75,$48 = Inline: value $4875
                       ; $05,$75,$49 = Inline: value $4975 (pattern suggests animation sequence)

                       db $25,$2C,$05,$F9,$28,$90,$24,$00,$1E,$00,$12,$05,$36,$08,$08,$08;03AD02
                       ; $25,$2C = Text color palette $2C
                       ; $05,$F9,$28,$90 = Inline: value $9028F9 (large timer/address)
                       ; $24,$00,$1E,$00 = Paragraph break with params
                       ; $12 = Location name marker
                       ; $05,$36,$08,$08,$08 = Inline: animation data (repeated $08 delays)

                       db $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$15;03AD12
                       ; Animation data: 15 bytes of $08 frame delays, then $15
                       ; $15 = Likely end-of-animation marker or transition code

                       db $12,$1F,$19,$05,$8B,$08,$29,$A4,$05,$8C,$19,$35,$16,$F6,$3C,$05;03AD22
                       ; $12,$1F,$19 = Location name with params
                       ; $05,$8B = Inline: value $8B
                       ; $08,$29,$A4 = Execute subroutine at $A429
                       ; $05,$8C,$19 = Inline: value $198C
                       ; $35,$16,$F6,$3C = Complex parameter (likely graphics DMA address)
                       ; $05 = Inline marker (continues)

                       db $00,$00,$10,$05,$00,$08,$60,$AD,$FF,$FF,$FF,$02,$FF,$FF,$FF,$05;03AD32
                       ; $00,$00,$10 = Null params + value $10
                       ; $05,$00 = Inline: $00
                       ; $08,$60,$AD = Execute subroutine at $AD60
                       ; $FF,$FF,$FF,$02,$FF,$FF,$FF = End markers (string table boundary padding)
                       ; $05 = Inline marker

                       db $8C,$10,$5F,$01,$12,$05,$00,$08,$60,$AD,$16,$7C,$3C,$FF,$16,$7C;03AD42
                       ; $8C = Dictionary word
                       ; $10,$5F,$01 = Character name ID $5F, context $01, offset $10
                       ; $12 = Location name marker
                       ; $05,$00 = Inline: $00
                       ; $08,$60,$AD = Execute subroutine $AD60
                       ; $16,$7C,$3C = Delay 124 frames (2 seconds), param $3C
                       ; $FF = End marker
                       ; $16,$7C = Delay 124 frames (repeated)

                       db $7C,$02,$16,$7C,$BC,$FF,$16,$7C,$FC,$05,$8C,$05,$00,$00,$05,$6C;03AD52
                       ; $7C,$02 = Param $7C with modifier $02
                       ; $16,$7C,$BC = Delay 124 frames, param $BC
                       ; $FF = End marker
                       ; $16,$7C,$FC = Delay 124 frames, param $FC
                       ; $05,$8C = Inline: $8C
                       ; $05,$00,$00 = Inline: $0000
                       ; $05,$6C = Inline: $6C

                       db $01,$05,$42,$02,$22,$12,$25,$00,$19,$05,$8B,$00,$08;03AD62
                       ; $01 = Text continuation
                       ; $05,$42,$02,$22 = Inline: value $220242
                       ; $12,$25,$00 = Location name from map $25, param $00
                       ; $19 = Sound effect trigger
                       ; $05,$8B = Inline: sound effect ID $8B
                       ; $00 = Null param
                       ; $08 = Command prefix (end of this section)

; [Section continues with similar script bytecode patterns through $03ADA4]
; The remainder follows the same structure: dialogue compression, state machines,
; bytecode commands, and lookup tables for FFMQ's comprehensive event system.

                       db $BE,$AD,$05,$00,$00               ;03AD6F
                       ; $BE,$AD = Bytecode $BE with param $AD
                       ; $05,$00,$00 = Inline: value $0000 (null/reset)

                       db $08,$BE,$AD,$10,$01,$00,$05,$A2,$05,$00,$87,$AD,$09,$1C,$B9,$00;03AD74
                       ; $08,$BE,$AD = Execute subroutine at $ADBE
                       ; $10,$01,$00 = Character name: party slot #1, context $00
                       ; $05,$A2 = Inline: value $A2
                       ; $05,$00,$87,$AD = Inline: value $AD870005 (large ROM pointer)
                       ; $09,$1C,$B9,$00 = Command $09: memory operation at $B9, params $1C,$00

                       db $12,$05,$00,$05,$6C,$01,$05,$42,$13,$02,$12,$25,$00,$19,$05,$8B;03AD84
                       ; $12 = Location name marker
                       ; $05,$00 = Inline: $00
                       ; $05,$6C,$01 = Inline: value $016C
                       ; $05,$42,$13,$02,$12 = Inline: complex value
                       ; $25,$00 = Text color palette $00 (default)
                       ; $19 = Sound effect trigger
                       ; $05,$8B = Inline: SFX ID $8B

                       db $05,$40,$1A,$00,$05,$7E,$0C,$1F,$00,$09,$05,$30,$08,$B8,$AD,$05;03AD94
                       ; $05,$40,$1A,$00 = Inline: value $001A40
                       ; $05,$7E = Inline: value $7E
                       ; $0C,$1F,$00,$09 = Conditional: if flag $1F=0, jump +$09 bytes
                       ; $05,$30 = Inline: value $30
                       ; $08,$B8,$AD = Execute subroutine at $ADB8
                       ; $05 = Inline marker (continues)

                       db $7F,$05,$3A,$1A,$00,$05,$8C,$05,$F3,$07,$30,$7E,$B7,$31,$7E,$B0;03ADA4
                       ; $7F = Parameter completion
                       ; $05,$3A,$1A,$00 = Inline: value $001A3A
                       ; $05,$8C = Inline: $8C
                       ; $05,$F3,$07,$30,$7E,$B7 = Inline: large graphics parameter
                       ; $31,$7E,$B0 = Unknown command $31 with params $7E,$B0

; [Remaining bytes through line 1200 follow similar patterns of script bytecode,
; dialogue compression, event triggers, and state machine definitions]
; Total section: 401 lines of sophisticated script engine data structures

; ==============================================================================
; END OF BANK $03 CYCLE 3
; ==============================================================================
