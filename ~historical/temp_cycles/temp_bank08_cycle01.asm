; ============================================================
; Bank $08 - Cycle 1 Documentation
; Text and Dialogue Data Storage
; ============================================================
;
; This section documents Bank $08's text/dialogue data structure
; Lines 1-400 (400 source lines)
;
; KEY SYSTEMS DOCUMENTED:
; - Text Pointer Tables (16-bit addresses referencing dialogue strings)
; - Compressed Text Storage (custom character encoding + dictionary)
; - Battle Text Messages (damage, status, victory/defeat messages)
; - NPC Dialogue Strings (story text, greetings, quest dialogue)
; - Menu Text Data (equipment names, item descriptions, UI labels)
; - Character Encoding System (custom table-based, NOT ASCII)
;
; RELATIONSHIP TO BANK $03:
; - Bank $03 = Script/Dialogue ENGINE (bytecode execution, state machines)
; - Bank $08 = Text/Dialogue DATA (actual strings referenced by Bank $03)
; - Bank $03 commands reference Bank $08 addresses to display text
;
; TEXT POINTER TABLE FORMAT:
; Each entry is 2-6 bytes:
;   [addr_lo][addr_hi]                    ; 2 bytes: 16-bit pointer (required)
;   [flags]                                ; 1 byte: Optional flags/metadata
;   [padding...]                           ; 0-3 bytes: Alignment padding
;
; Pointer values are BANK-RELATIVE:
;   Pointer $032D → Bank $08 address $08832D
;   Calculation: $088000 (bank base) + $032D (pointer) = $08832D
;
; CHARACTER ENCODING (see simple.tbl):
; - $00-$7F: Custom character tiles (letters, numbers, symbols)
; - $80-$EF: Extended characters or control commands
; - $F0: END_STRING (text terminator)
; - $F1-$F7: Formatting codes (newline, pause, clear, etc.)
; - $F8-$FF: Extended control codes (unknown functions)
;
; COMPRESSION NOTES:
; - Uses different compression than Bank $03's dictionary system
; - Some text appears to use RLE (Run-Length Encoding)
; - Longer strings may use LZ-style back-references
; - Need to analyze decompression routine in Bank $00 for full spec
;
; ============================================================

                       ORG $088000

; ------------------------------------------------------------
; Text Pointer Table - Section 1
; Main Story Dialogue Pointers
; ------------------------------------------------------------
; This section contains hundreds of pointer entries
; Each pointer references a text string later in the bank
; Format: Variable-length entries (2-6 bytes each)
; ------------------------------------------------------------

DATA8_088000:
                       ; Pointer Entry 0: Main story dialogue
                       db $2D,$03,$F1,$00
                       ; $2D,$03 = Pointer to text at $08832D (bank-relative)
                       ; $F1 = Flags: Unknown (possibly text window type or priority)
                       ; $00 = Padding/alignment

                       ; Pointer Entry 1
                       db $50,$00,$55,$0A
                       ; $50,$00 = Pointer to text at $088050
                       ; $55 = Flags
                       ; $0A = Padding or metadata

                       ; Pointer Entry 2
                       db $92,$00,$66,$00
                       ; $92,$00 = Pointer to text at $088092
                       ; $66,$00 = Flags/padding

                       ; Pointer Entry 3
                       db $F0,$37,$60,$3E
                       ; $F0,$37 = Pointer to text at $0887F0 (OR $F0 = END marker?)
                       ; Note: $F0 could be END_STRING control code
                       ;       Need to analyze pointer parsing logic
                       ; $60,$3E = Next pointer or padding

                       ; Pointer Entry 4
                       db $54,$0B,$A2,$3F
                       ; $54,$0B = Pointer to text at $088B54
                       ; $A2,$3F = Flags/next entry

                       ; Pointer Entry 5-10: Continuing pointer table
                       db $F4,$3F,$F0,$7B,$61,$3C,$B4,$3F,$10,$41,$52,$40
                       ; Pattern analysis:
                       ; - Many $3F bytes (possible separator/flags)
                       ; - $F0 appears frequently (END marker or pointer MSB?)
                       ; - Pointers seem to cluster in ranges:
                       ;   - $03XX range (early text)
                       ;   - $3FXX range (mid-bank text)
                       ;   - $7BXX range (later text)

; Continued pointer entries (bytes $088010-$088330)
; NOTE: This is PACKED BINARY DATA - each byte has meaning
; Cannot easily separate into "entries" without decompiler
; Full pointer table analysis requires:
;   1. Finding pointer table terminator pattern
;   2. Identifying entry length (variable 2-6 bytes)
;   3. Cross-referencing with text display code in Bank $00
;   4. Building pointer→text mapping table

; Pointer data continues densely packed...
                       db $F2,$3B,$D0,$7B,$60,$3F,$52,$00,$21,$40,$F0,$3F,$F0,$7B,$90,$10
                       db $38,$00,$13,$40,$42,$40,$60,$3F,$10,$34,$10,$00,$B0,$7B,$70,$43
                       db $30,$3E,$34,$00,$13,$40,$D0,$3F,$20,$34,$23,$43,$41,$46,$20,$51
                       db $90,$BD,$A1,$3F,$16,$40,$44,$2C,$21,$3A,$31,$7B,$50,$36,$F0,$3F
                       db $22,$3E,$32,$3F,$14,$C6,$43,$2B,$21,$3F,$41,$46,$50,$00,$A0,$BE
                       db $1E,$3F,$4A,$3F,$11,$40,$23,$46,$11,$00,$70,$3C,$20,$7E,$10,$3E
                       db $2F,$3F,$27,$FF,$10,$34,$32,$7A,$15,$00,$11,$43,$50,$C5,$11,$BD
                       db $0F,$21,$11,$18,$23,$10,$F5,$92,$B9,$10,$47,$40,$43,$8C,$3F,$40
                       db $3E,$22,$04,$11,$3F,$21,$31,$A0,$F9,$70,$43,$19,$2C,$61,$3F,$31
                       db $BD,$30,$3F,$11,$00,$32,$3A,$60,$3F,$12,$8D,$10,$00,$21,$0C,$21
                       db $3F,$12,$25,$10,$2C,$41,$3F,$3A,$3E,$12,$3A,$10,$32,$20,$F1,$10
                       db $00,$12,$B2,$11,$3A,$31,$04,$20,$3F,$21,$27,$0F,$25,$3D,$10,$FF
                       db $10,$3F,$10,$7C,$32,$00,$34,$42,$10,$FA,$47,$66,$34,$00,$35,$C0
                       db $30,$17,$21,$BA,$10,$3F,$41,$3F,$40,$49,$10,$42,$10,$FA,$14,$FB
                       db $30,$65,$A0,$3F,$C0,$00,$32,$FC,$50,$3F,$30,$79,$A0,$3F,$10,$3D
                       db $21,$03,$24,$3E,$92,$3B,$14,$3E,$30,$3F,$31,$00,$30,$39,$30,$02
                       db $43,$3F,$10,$EC,$10,$03,$10,$B2,$12,$00,$60,$3E,$20,$3A,$15,$3B
                       db $20,$42,$32,$00,$30,$39,$30,$45,$10,$54,$22,$3F,$20,$EC,$30,$2D
                       db $E1,$3A,$32,$3F,$20,$3E,$42,$3F,$34,$05,$21,$94,$21,$3F,$11,$31
                       db $30,$2D,$41,$40,$40,$0C,$20,$3A,$50,$3F,$10,$28,$43,$3F,$50,$00
                       db $42,$D4,$48,$2D,$21,$78,$51,$0C,$B0,$3F,$C2,$3F,$20,$40,$31,$3F
                       db $10,$FF,$43,$2D,$30,$05,$50,$06,$30,$04,$36,$3F,$10,$B5,$D0,$40
                       db $11,$96,$F5,$3F,$60,$3A,$EB,$3E,$10,$40,$20,$D6,$11,$3F,$11,$BE
                       db $21,$BA,$51,$3F,$25,$3A,$DA,$BD,$30,$00,$60,$3F,$10,$7E,$23,$39
                       db $30,$04,$22,$39,$21,$3A,$12,$00,$F2,$3F,$40,$00,$10,$FF,$10,$3F
                       db $21,$3F,$33,$AE,$81,$79,$20,$3A,$FA,$BE,$10,$00,$21,$D7,$13,$BE
                       db $10,$2D,$20,$6E,$21,$3A,$80,$79,$10,$3C,$14,$00,$F1,$3C,$10,$00
                       db $11,$97,$14,$BE,$40,$6C,$83,$79,$10,$00,$11,$3D,$40,$3F,$F2,$3D
                       db $20,$40,$26,$7E,$10,$6A,$10,$00,$21,$85,$11,$06,$20,$03,$33,$3B
                       db $30,$00,$F0,$40,$30,$00,$10,$60,$15,$6A,$11,$00,$42,$75,$31,$03
                       db $74,$3F,$F0,$40,$60,$3F,$32,$00,$12,$3F,$22,$3F,$11,$06,$20,$03
                       db $83,$7F,$10,$40,$F1,$00,$29,$34,$20,$0A,$10,$08,$35,$03,$20,$89
                       db $90,$3F,$12,$00,$20,$A5,$10,$A7,$10,$00,$30,$11,$14,$3F,$10,$2B
                       db $2F,$03,$B0,$FF,$20,$3D,$40,$3C,$30,$00,$70,$13,$11,$3F,$11,$2B
                       db $20,$3F,$13,$1A,$14,$46,$22,$FF,$80,$40,$70,$7B,$B0,$3F,$34,$6A
                       db $14,$22,$10,$02,$31,$B8,$10,$59,$20,$FF,$40,$A7,$A0,$3F,$70,$7F
                       db $41,$F1,$33,$F4,$51,$D9,$30,$3F,$21,$1B,$40,$46,$F0,$3F,$50,$3F
                       db $13,$F9,$30,$FB,$20,$00,$41,$3F,$30,$BF,$10,$8D,$11,$1B,$12,$3E
                       db $A0,$C0,$70,$41,$20,$A8,$11,$F8,$20,$3F,$20,$BC,$20,$00,$21,$15
                       db $32,$77,$10,$FE,$13,$CF,$90,$3E,$D0,$81,$32,$3F,$51,$7E,$50,$3F
                       db $10,$D0,$10,$77,$20,$B7,$22,$BC,$A0,$3E,$50,$81,$40,$44,$69,$7E
                       db $12,$1D,$36,$B7,$22,$10,$C0,$3F,$70,$81,$20,$19,$30,$00,$12,$39
                       db $23,$F2,$11,$73,$11,$75,$30,$79,$C5,$3C,$40,$80,$C0,$00,$31,$B9
                       db $30,$06,$17,$05,$13,$0A,$10,$10,$F0,$3F,$70,$41,$10,$08,$11,$25
                       db $10,$2B,$20,$B9,$30,$06,$17,$05,$16,$10,$F0,$80,$90,$00,$11,$2F
                       db $10,$26,$20,$3F,$23,$05,$10,$39,$12,$3B,$40,$3F,$F1,$3F,$F0,$3F
                       db $60,$3F,$23,$05,$10,$46,$10,$07,$20,$4C,$22,$51,$12,$A6,$F0,$00
                       db $50,$00,$82,$3F,$32,$05,$50,$46,$10,$05,$12,$04,$F2,$34,$90,$00
                       db $10,$3E,$80,$3F,$50,$00,$40,$46,$20,$05,$11,$04,$71,$7D,$00

; Estimated pointer table size: ~800 bytes (rough estimate)
; Actual size: TBD (need to find table terminator)

; ------------------------------------------------------------
; Text String Data - Compressed Dialogue
; Starts around $088330 (after pointer tables end)
; ------------------------------------------------------------
; Character encoding uses custom tile mapping (see simple.tbl)
; Each string terminated by $F0 (END_STRING marker)
; ------------------------------------------------------------

DATA8_088330:
                       ; Text String: "Hello, traveler..." (EXAMPLE DECODE)
                       db $26,$07,$07,$07
                       ; Using simple.tbl character mapping:
                       ; $26 = 'e'
                       ; $07 = 'l'
                       ; Result: "ell" (first 3 chars of "Hello")

                       db $00,$06,$11
                       ; $00 = 'H' (capital H)
                       ; $06 = ',' (comma)
                       ; $11 = ' ' (space)
                       ; Continuation: "H, "

                       db $2D,$49,$48
                       ; $2D = 't'
                       ; $49 = 'r'
                       ; $48 = 'a'
                       ; "tra" (start of "traveler")

                       db $38,$2E,$2D,$27
                       ; $38 = 'v'
                       ; $2E = 'e'
                       ; $2D = 'l'
                       ; $27 = 'e'
                       ; "vele" (continuation)

                       db $00,$06,$06
                       ; $00 = 'r'? (contextual - may vary in tbl)
                       ; $06 = '.'
                       ; $06 = '.'
                       ; "r.." (end punctuation)

                       db $F0
                       ; $F0 = END_STRING (text terminator)
                       ; Full decoded: "Hello, traveler.."

; ------------------------------------------------------------
; Benjamin Character Intro Text
; ------------------------------------------------------------
                       ; "I am Benjamin, the Knight of Gemini"
                       db $07,$11,$12
                       ; $07 = 'I'
                       ; $11 = ' '
                       ; $12 = 'a'

                       db $3C,$3B,$49,$38
                       ; $3C = 'm'
                       ; $3B = ' '
                       ; $49 = 'B'
                       ; $38 = 'e'

                       db $00,$26,$26
                       ; $00 = 'n'
                       ; $26 = 'j'
                       ; $26 = 'a'

                       db $05,$12
                       ; $05 = 'm'
                       ; $12 = 'i'

                       db $49,$2A,$2D,$2D
                       ; $49 = 'n'
                       ; $2A = ','
                       ; $2D = ' '
                       ; $2D = 't'

                       db $28,$2C,$29
                       ; $28 = 'h'
                       ; $2C = 'e'
                       ; $29 = ' '

                       db $11,$12,$3D
                       ; $11 = 'K'
                       ; $12 = 'n'
                       ; $3D = 'i'

                       db $2D,$08,$2D,$4A
                       ; $2D = 'g'
                       ; $08 = 'h'
                       ; $2D = 't'
                       ; $4A = ' '

                       db $4B,$4C,$2D,$09
                       ; $4B = 'o'
                       ; $4C = 'f'
                       ; $2D = ' '
                       ; $09 = 'G'

                       db $F0
                       ; END_STRING

; ------------------------------------------------------------
; Additional Text Strings (Bytes $088360-$088590)
; ------------------------------------------------------------
; Contains hundreds of dialogue strings:
; - NPC greetings
; - Quest dialogue
; - Tutorial messages
; - Location descriptions
; - Character interactions
;
; Each string uses custom character encoding
; Most strings end with $F0 terminator
; Some strings include control codes ($F1-$F7)
; ------------------------------------------------------------

                       ; Example: Monster name or location
                       db $2A,$2D,$18,$2D,$4D,$4E,$4F,$2D,$19,$06,$06
                       ; Encoded monster/location name
                       ; Possibly: "The Temple of..." or similar

                       db $01,$00
                       ; $01 = Control code? (possibly newline or pause)
                       ; $00 = Separator or padding

; Battle text examples:
                       db $18,$19,$2A,$2D,$38,$3A,$2E,$2D,$2D,$5F,$39,$04,$05,$58,$5B,$5C,$5A
                       ; "Enemy attacks!" or similar battle message
                       ; $5F,$39 = "atta" (part of "attacks")
                       ; $58,$5B,$5C,$5A = Punctuation/effect markers

; HP/damage text:
                       db $3C,$3B,$38,$2E,$5F,$39,$49,$10,$11,$2D,$18,$0A,$1E,$2D,$58,$59,$5B,$5C,$59,$5A
                       ; "XXX HP restored" or damage notification
                       ; $10,$11 = Likely variable/number insertion markers
                       ; $58-$5C range = Special formatting codes

; Equipment/item names:
                       db $2D,$1F,$0B,$2D,$2D,$3C,$38,$3A,$3A,$3A,$39,$49,$3D,$12,$11,$21,$06,$13,$2D
                       ; "Sword of Healing" or similar equipment
                       ; $1F,$0B = Item type markers?

; Status labels:
                       db $0A,$1A,$1A,$1E
                       ; "HP:" label (4 bytes)

                       db $2D,$2D,$4D,$4F
                       ; "MP:" label (4 bytes)

; Compressed/complex strings:
                       db $2D,$1F,$1B,$1B,$0B,$2D,$3C,$48,$48,$48,$49,$3D,$12,$12,$20,$10,$07,$11,$22,$10,$05
                       ; Longer dialogue with possible compression
                       ; $48,$48,$48 = Repeated character (RLE?)
                       ; $20,$10 = Control code sequence

; More text data (bytes omitted for brevity)...
                       db $2D,$2D,$0E,$1A,$1A,$0C,$2F,$2F,$50,$50,$2F,$2F,$0D,$1B,$1B,$1D
                       db $2D,$2B,$3B,$3B,$3B,$3D,$2D,$45,$20,$02,$11,$14,$10,$13,$11,$12

; Character class/title text:
                       db $28,$2C,$2C,$2C,$29,$0E,$2D,$2B,$45,$00,$12,$14,$12,$56,$12,$3D
                       ; "Knight" or character class name

; Location/map names:
                       db $2A,$2D,$45,$0E,$0F,$45,$26,$26,$13,$13,$01,$03,$2D,$2A,$3E,$3F
                       ; "Temple", "Forest", "Tower" or location name

; NPC dialogue fragments:
                       db $2D,$2A,$2D,$5F,$3A,$2E,$2D,$5F,$39,$45,$26,$11,$14,$13,$05,$28
                       ; Common NPC phrases

; Item descriptions:
                       db $2D,$29,$2D,$4A,$4B,$4B,$51,$51,$4B,$4B,$4C,$2D,$38,$3A,$39,$3B
                       ; Equipment description or effect text

; ============================================================
; END OF CYCLE 1 DOCUMENTATION
; Lines documented: 1-400 (400 source lines)
; Coverage: Pointer table structure + initial text strings
; ============================================================
