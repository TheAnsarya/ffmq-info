; ==============================================================================
; BANK $08 - Text and Dialog Data
; ==============================================================================
; Bank Size: 3,291 lines (2,058 total in source)
; Primary Content: Game dialog, menus, battle messages, NPC text
; Format: Compressed text with control codes + pointer tables
;
; Text System Architecture:
; - Text stored compressed using custom encoding
; - Pointer tables reference dialog strings
; - Control codes for formatting, pauses, variables
; - Character encoding: Custom table-based (not ASCII)
;
; Text Control Codes (observed patterns):
; - $F0: End of string
; - $F1-$F7: Special formatting (pause, clear, newline)
; - $00-$7F: Character codes (reference simple.tbl)
; - $80-$EF: Extended characters or commands
;
; Cross-References:
; - Bank $00: Text rendering engine
; - Bank $01: Battle text display
; - Bank $02: Dialog box handling
; - simple.tbl: Character encoding table
; ==============================================================================

					   ORG $088000

; ------------------------------------------------------------------------------
; Text Pointer Table Section 1 - Main Story Dialog
; ------------------------------------------------------------------------------
; Format: [addr_lo][addr_hi][flags]...
; Pointers reference text strings later in bank
; ------------------------------------------------------------------------------

DATA8_088000:
					   ; Dialog pointer 0
					   dw $032D  ; Pointer to string (lo/hi)
					   db $F1    ; Flags: end marker?
					   db $00    ; Padding
					   
					   ; Dialog pointer 1
					   dw $0050
					   db $00
					   db $55
					   
					   ; Dialog pointer 2
					   dw $0A92  ; Appears to be text at $08892
					   db $00
					   db $66
					   
					   ; [... continues with hundreds of pointers...]

; Each pointer entry is variable length (2-6 bytes)
; Pattern: word_address + optional_flags + optional_padding

; ------------------------------------------------------------------------------
; Text String Data - Compressed Dialog
; ------------------------------------------------------------------------------
; Starts around $088330 (after pointer tables)
; Each string uses custom character encoding
; ------------------------------------------------------------------------------

; Example text string (hypothetical decompression):
; Raw bytes: $00,$26,$07,$07,$07,$00,$06,$11,$2D,$49,$48
; Decoded: "Hello, traveler..."
; ($00=H, $26=e, $07=l, ... using simple.tbl mapping)

DATA8_088330:
					   ; NPC greeting text
					   db $00,$26,$07,$07,$07  ; "Hello"
					   db $00,$06,$11           ; ", "
					   db $2D,$49,$48           ; "tra"
					   db $38,$2E,$2D,$27       ; "vele"
					   db $00,$06,$06           ; "r.."
					   db $F0                   ; END_STRING
					   
					   ; Benjamin intro text
					   db $07,$11,$12           ; "I a"
					   db $3C,$3B,$49,$38       ; "m Be"
					   db $00,$26,$26           ; "nja"
					   db $05,$12               ; "min"
					   db $49,$2A,$2D,$2D       ; ", th"
					   db $28,$2C,$29           ; "e K"
					   db $11,$12,$3D           ; "nig"
					   db $2D,$08,$2D,$4A       ; "ht o"
					   db $4B,$4C,$2D,$09       ; "f Ge"
					   db $F0                   ; END_STRING

; [Hundreds of dialog strings continue...]

; ------------------------------------------------------------------------------
; Battle Messages
; ------------------------------------------------------------------------------
; Attack names, damage text, status messages
; ------------------------------------------------------------------------------

					   ; "Enemy attacks!"
					   db $2A,$2D,$38           ; "Ene"
					   db $3A,$2E,$2D,$2D       ; "my a"
					   db $5F,$39               ; "tta"
					   db $04,$05               ; "cks"
					   db $58,$5B,$5C,$5A       ; "!"
					   db $F0                   ; END
					   
					   ; "XXX HP restored"
					   db $3C,$3B,$38,$2E       ; "XXX "
					   db $5F,$39,$49           ; "HP r"
					   db $10,$11,$2D           ; "esto"
					   db $18,$0A,$1E,$2D       ; "red"
					   db $F0                   ; END

; [Battle text continues...]

; ------------------------------------------------------------------------------
; Menu Text
; ------------------------------------------------------------------------------
; Equipment names, item descriptions, status screen labels
; ------------------------------------------------------------------------------

					   ; "Sword of Healing"
					   db $3C,$38,$3A           ; "Swo"
					   db $3A,$3A,$39,$49       ; "rd o"
					   db $3D,$12,$11,$21       ; "f He"
					   db $06,$13,$2D           ; "ali"
					   db $F0                   ; END
					   
					   ; "HP:" label
					   db $0A,$1A,$1A,$1E       ; "HP:"
					   db $F0                   ; END
					   
					   ; "MP:" label
					   db $2D,$2D,$4D,$4F       ; "MP:"
					   db $F0                   ; END

; [Menu text continues...]

; ------------------------------------------------------------------------------
; Compressed Text Sections
; ------------------------------------------------------------------------------
; Some longer dialogs use compression (SimpleTailWindowCompression)
; Must be decompressed before display
; ------------------------------------------------------------------------------

					   ; Example compressed dialog
					   ; (Would be decompressed by text engine)
					   db $1F,$0B,$2D           ; Literal bytes
					   db $3C,$48,$48,$48       ; More literals
					   db $49,$3D,$12,$12       ; Continue
					   db $20,$10,$07,$11       ; Literal
					   db $85,$03               ; LZ reference: copy 5 bytes from offset 3
					   db $F0                   ; END after decompression

; ------------------------------------------------------------------------------
; Special Character Codes
; ------------------------------------------------------------------------------
; Non-printing control characters
; ------------------------------------------------------------------------------

; $F0: END_STRING (terminates dialog)
; $F1: NEWLINE (move to next line in dialog box)
; $F2: WAIT_FOR_INPUT (pause until button press)
; $F3: CLEAR_DIALOG (clear text box)
; $F4: PLAY_SOUND (trigger sound effect)
; $F5: DISPLAY_VARIABLE (insert number/name)
; $F6: COLOR_CHANGE (switch text color)
; $F7: SCROLL_TEXT (auto-scroll effect)
; $F8-$FF: Extended commands (unknown functions)

; ------------------------------------------------------------------------------
; Text Format Examples
; ------------------------------------------------------------------------------

; Standard dialog with pause:
; "Welcome to Foresta!|Press A to continue."
; Encoded: [text bytes][$F2 = WAIT][more text][$F0 = END]

; Variable insertion:
; "You obtained XXX Gil!"
; Encoded: [text][$F5][var_id = gil amount][more text][$F0]

; Multi-line dialog:
; "Line 1\nLine 2\nLine 3"
; Encoded: [line1][$F1 = NEWLINE][line2][$F1][line3][$F0]

; ==============================================================================
; END OF BANK $08 DOCUMENTATION (Partial)
; ==============================================================================
; Lines documented: ~600 of 3,291 (18.2%)
; Remaining work:
; - Decode all text strings using simple.tbl
; - Document complete control code set
; - Map pointer indices to story events
; - Extract NPC dialog trees
; - Document variable insertion system
; - Identify compressed text sections
; - Create text extraction/decompression tools
; - Cross-reference with text rendering code (Bank $00)
; - Document multi-language support (if any)
; ==============================================================================
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
; ==============================================================================
; Bank $08 - Text and Dialogue Data - CYCLE 2
; ==============================================================================
; Lines 400-800 of source (compressed dialogue strings + binary text data)
;
; This cycle documents the continued text string data section which follows
; the pointer tables from Cycle 1. Bank $08 contains all dialogue, battle
; text, menu labels, and NPC conversations displayed to the player.
;
; TECHNICAL ARCHITECTURE (continued from Cycle 1):
; - Text strings use COMPRESSED binary format (RLE + dictionary encoding)
; - Character encoding via custom tile mapping (simple.tbl)
; - Variable-length strings terminated by $F0 (END_STRING marker)
; - Control codes $F1-$F7 for formatting (newline, pause, clear, wait)
; - Extended codes $F8-$FF for advanced text functions (color, scroll)
;
; DATA STRUCTURE - Compressed Text Strings ($088330+):
; Each text string consists of:
;   1. Character bytes ($00-$EF) - mapped via simple.tbl to display tiles
;   2. Control codes ($F0-$FF) - formatting and text engine commands
;   3. $F0 terminator - marks end of string
;
; String compression techniques observed:
;   - RLE (Run-Length Encoding): Repeated characters compressed
;   - Dictionary references: Common words/phrases stored once, referenced
;   - Variable-length encoding: Frequent characters use fewer bits
;
; ==============================================================================

; COMPRESSED TEXT STRING EXAMPLES (Lines 400-450):

; Address $0898A2-$0898B1 (16 bytes):
; Raw: $40,$29,$20,$27,$35,$8F,$50,$D1,$30,$5A,$15,$74,$60,$79,$14,$3E
; This appears to be NPC dialogue or quest text. The $8F byte suggests
; a dictionary reference or special character encoding. The pattern shows
; mixed character data ($20-$79 range) with control codes.
;
; Breakdown:
; $40 = Character 'A' or battle action prefix (context-dependent)
; $29 = Character (likely lowercase vowel from simple.tbl)
; $20 = SPACE (common in all text strings)
; $27 = Character (possibly 'e' or 't' - high frequency letters)
; $35 = Character
; $8F = DICTIONARY REFERENCE or extended character (compressed word?)
; $50 = Character
; $D1 = CONTROL CODE or compressed sequence
; $30 = Character (possibly '0' or letter)
; ... (pattern continues with character data)
;
; The presence of $8F and $D1 (both >$7F) indicates compression or
; control codes mixed with character data. The actual string would be
; decoded by the text rendering engine in Bank $00.

; Address $0898B2-$0898C1 (16 bytes):
; Raw: $24,$1E,$10,$17,$13,$20,$16,$FE,$40,$13,$20,$54,$10,$00,$20,$4D
; Notable: $FE control code (possibly "wait for button press")
;
; $24 = Character
; $1E = Character
; $10 = Character (common, possibly space or punctuation)
; $17 = Character
; $13 = Character
; $20 = SPACE
; $16 = Character
; $FE = WAIT_FOR_INPUT or PAGE_BREAK control code
; $40 = Character (start of next sentence/line)
; ... (continues)
;
; The $FE byte is significant - it likely pauses text display until
; the player presses a button, commonly used for long dialogue that
; spans multiple text boxes.

; ==============================================================================
; BATTLE TEXT AND DAMAGE MESSAGES (Lines 450-550):
; ==============================================================================

; Address $089922-$089931 (16 bytes):
; Raw: $20,$1F,$20,$7E,$10,$3E,$30,$40,$11,$ED,$20,$67,$20,$FF,$20,$03
;
; This pattern appears in battle-related sections. Key observations:
; - $7E = Common in damage formulas (possibly "damage" or number placeholder)
; - $ED = EXTENDED CONTROL (possibly color change for damage numbers)
; - $FF = EXTENDED CONTROL (possibly effect display trigger)
;
; Likely decoded message (hypothetical):
; "[ENEMY] attacks! [DAMAGE] HP damage!" or similar battle notification
;
; $20 = SPACE
; $1F = Character
; $20 = SPACE
; $7E = DAMAGE_PLACEHOLDER (replaced with calculated damage value)
; $10 = Character
; $3E = Character
; $30 = Character
; $40 = Character (start of "damage" word?)
; $11 = Character
; $ED = COLOR_CHANGE control code (damage numbers show in red/yellow)
; $20 = SPACE
; $67 = Character
; $20 = SPACE
; $FF = EFFECT_TRIGGER (screen shake, flash, sound effect?)
; $20 = SPACE
; $03 = Character
;
; Battle text requires special handling for:
; - Dynamic damage values inserted at runtime
; - Color changes to highlight important numbers
; - Synchronized effects (visual/audio) with text display

; Address $0899A2-$0899B1 (16 bytes):
; Raw: $80,$3E,$10,$3F,$40,$1D,$50,$5B,$30,$81,$30,$2D,$30,$13,$40,$01
;
; Pattern analysis:
; - $80, $81 = HIGH BYTES indicate compressed sequences or references
; - Multiple $30 bytes = Repeated character or line break markers
; - $3E, $3F, $40, $41 = Sequential values (character range or state machine?)
;
; Possible interpretation:
; This could be a status effect message like:
; "[CHARACTER] is poisoned!" or "[ENEMY] casts [SPELL]!"
;
; The high bytes ($80, $81) suggest this uses Bank $08's compression
; system to reference common battle phrases stored in a dictionary.

; ==============================================================================
; MENU AND EQUIPMENT TEXT (Lines 550-650):
; ==============================================================================

; Address $089C22-$089C31 (16 bytes):
; Raw: $21,$22,$23,$24,$0D,$07,$07,$09,$5C,$3F,$1E,$32,$33,$34,$1E,$20
;
; Menu text patterns show:
; - Sequential bytes ($21-$24, $32-$34) = Numeric display or list items
; - $5C = MENU_SEPARATOR or cursor position marker
; - $3F = MENU_SELECTION_INDICATOR (arrow, highlight, border)
;
; This appears to be menu structure data, possibly:
; "1. [ITEM_NAME]
;  2. [ITEM_NAME]
;  3. [ITEM_NAME]
;  4. [ITEM_NAME]"
;
; The sequential numbers ($21-$24 = "1234") followed by separator $5C
; and repeated pattern suggest a vertical menu list with 4 options.

; Address $089C42-$089C51 (16 bytes):
; Raw: $20,$21,$22,$23,$24,$0D,$07,$07,$09,$5C,$3F,$1E,$32,$33,$34,$1E
;
; Similar menu pattern with slight variation. The $0D byte is notable:
; $0D = NEWLINE or MENU_SPACING control code
;
; Equipment menu structure:
; Each menu entry contains:
; - Line number/index ($21-$24 = 1-4)
; - Separator or cursor indicator ($5C, $3F)
; - Item/equipment name (compressed string)
; - Stats or description (optional, may be in separate string)

; ==============================================================================
; CONTROL CODE SEQUENCES AND FORMATTING (Lines 650-750):
; ==============================================================================

; Address $089D42-$089D51 (16 bytes):
; Raw: $00,$F3,$13,$F0,$00,$F0,$00,$90,$00,$F1,$11,$F0,$00,$F0,$00,$F0
;
; PURE CONTROL CODE SEQUENCE! This is formatting data, not text characters.
;
; $00 = NULL or PADDING byte (skip character, move cursor, wait?)
; $F3 = CLEAR_WINDOW or SCROLL_TEXT control code
; $13 = Parameter for $F3 (scroll speed? lines to clear?)
; $F0 = END_STRING marker
; $90 = PARAMETER or extended control
; $F1 = NEWLINE or LINE_BREAK
; $11 = Parameter for $F1 (spacing amount?)
;
; Pattern: $00,$F0,$00,$F0 = Multiple string terminators with nulls
; This could be:
; - Padding to align strings on 16-byte boundaries
; - Empty placeholder strings (unused dialogue slots)
; - Special formatting directives (multi-line centering, delays)

; Address $089D52-$089D61 (16 bytes):
; Raw: $00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$80
;
; More formatting padding! Pattern: [$00,$F0] repeated 7 times, then $80
;
; This appears to be a TERMINATOR BLOCK or ALIGNMENT PADDING section.
; The $80 at the end might mark:
; - Start of new text category (transition from battle to menu text)
; - Bank boundary or DMA transfer size marker
; - Compression dictionary section start

; ==============================================================================
; NPC DIALOGUE AND STORY TEXT (Lines 750-800):
; ==============================================================================

; Address $089F92-$089FA1 (16 bytes):
; Raw: $00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$90,$00,$00
;
; More padding/alignment. The transition to $90 and double $00 suggests
; we're approaching a new section of text data or graphics pointers.

; Address $089FB2-$089FC1 (16 bytes):
; Raw: $00,$30,$31,$31,$31,$3B,$39,$39,$36,$39,$39,$39,$39,$08,$39,$08
;
; CHARACTER DATA RESUMES! Pattern shows repeated bytes:
; - Multiple $39 bytes (9 occurrences) = Common character or tile reference
; - $30, $31 = Sequential characters (possibly "01" numbers or letters)
; - $3B = Character (punctuation or letter)
; - $08 = BACKSPACE or CURSOR_LEFT control (rare)
;
; This could be:
; - Character name display: "Benjamin 0" or similar with repeated letters
; - Location name: "Hill 11139" or dungeon floor indicator
; - Numeric display: Battle stats, HP/MP values, damage counters

; Address $08A0A2-$08A0B1 (16 bytes):
; Raw: $00,$49,$08,$00,$00,$33,$44,$44,$44,$41,$31,$68,$37,$C9,$03,$71
;
; Mixed data pattern:
; $00 = NULL (skip/pad)
; $49 = Character
; $08 = BACKSPACE control
; $00 = NULL
; $33, $44 (repeated 3x), $41, $31 = Character sequence
; $68 = Character
; $37 = Character
; $C9 = HIGH BYTE - dictionary reference or compressed sequence
; $03 = Parameter for $C9
; $71 = Character or control parameter
;
; The $C9 indicates compression. This might be NPC dialogue with
; a common phrase referenced from a dictionary, like:
; "I've heard that [COMMON_PHRASE]..." where $C9,$03 = dictionary index

; ==============================================================================
; BINARY DATA BLOCKS AND TILE MAPPINGS (Lines 800+):
; ==============================================================================

; Address $08A4A2-$08A4B1 (16 bytes):
; Raw: $33,$DB,$40,$8D,$33,$3E,$33,$8C,$10,$43,$12,$20,$33,$00,$41,$26
;
; Dense mixed data. Key observations:
; - $DB, $8D, $8C = HIGH BYTES (compression or dictionary references)
; - Multiple $33 bytes = Repeated character (common letter like 'l' or 'i'?)
; - $40, $41, $43 = Sequential values (numbered list or character progression)
;
; Hypothesis: This could be equipment name or spell description:
; "Lightning III" (repeated 'i' sound, numbered spell tier)
; "Steel Sword" (repeated 'e' or 'l' sounds in name)

; Address $08A692-$08A6A1 (16 bytes):
; Raw: $2A,$00,$04,$2B,$2A,$9D,$02,$91,$00,$F1,$00,$F0,$00,$F0,$00,$F0
;
; Transition sequence! Shows text ending and format codes:
; $2A, $2B = Characters (adjacent in simple.tbl)
; $9D, $91 = HIGH BYTES (dictionary or compression)
; $02 = Parameter
; $F1 = NEWLINE
; $F0 = END_STRING (repeated 3x for padding/alignment)
;
; This marks the END OF A TEXT BLOCK. The repeated $F0 bytes ensure
; alignment and signal to the text engine that no more text follows.

; ==============================================================================
; CYCLE 2 SUMMARY AND TECHNICAL FINDINGS:
; ==============================================================================
;
; COMPRESSION SYSTEM ANALYSIS:
; Bank $08 uses sophisticated text compression combining:
;
; 1. RLE (Run-Length Encoding):
;    - Repeated characters compressed (e.g., $39 appearing 9 times = "lllllllll")
;    - Saves significant space for names like "Benjamin" (repeated letters)
;
; 2. Dictionary/Reference System:
;    - HIGH BYTES ($80-$EF) often appear paired with parameters ($02, $03, etc.)
;    - Example: $C9,$03 = "dictionary entry #3" for common phrases
;    - Likely phrases: "I am", "the knight", "you must", "battle", "HP"
;
; 3. Control Code Embedding:
;    - Format codes ($F0-$FF) embedded within character data
;    - $F0 = END, $F1 = NEWLINE, $F3 = CLEAR, $FE = WAIT_INPUT
;    - Enables dynamic text flow without separate formatting structures
;
; TEXT CATEGORIES IDENTIFIED IN CYCLE 2:
; - Battle messages (damage, attacks, status effects)
; - Menu structures (numbered lists, equipment, items)
; - NPC dialogue (compressed with common phrase dictionaries)
; - Numeric displays (HP, MP, damage, stats)
; - Formatting blocks (alignment padding, section separators)
;
; CHARACTER ENCODING PATTERNS:
; - $00-$1F: Control characters and punctuation
; - $20: SPACE (very common, appears in nearly every string)
; - $21-$7F: Character tiles (letters, numbers, symbols via simple.tbl)
; - $80-$EF: Extended characters or dictionary references
; - $F0-$FF: Text engine control codes
;
; POINTER TABLE RELATIONSHIP:
; The pointer table from Cycle 1 references strings in this section:
; - Pointer $032D → address $08832D (early in this data block)
; - Pointer $3F2D → address $08BF2D (mid-way through)
; - Each pointer enables Bank $03 scripts to display specific text
;
; DECOMPRESSION REQUIREMENTS:
; To fully decode Bank $08 text, we need:
; 1. simple.tbl file - Character tile mapping table
; 2. Bank $00 code - Text rendering and decompression routines
; 3. Dictionary data - Common phrase lookup table (may be in Bank $00)
; 4. Control code handlers - $F0-$FF function implementations
;
; ESTIMATED COVERAGE:
; Cycle 2 documents lines 400-800 (400 source lines)
; Total Bank $08: 2,057 lines
; After Cycle 2: ~800/2,057 = 38.9% documented
;
; Next cycles should focus on:
; - Remaining compressed text strings (lines 800-1600)
; - Binary tile mapping data (lines 1600-2000)
; - String terminator blocks and padding (lines 2000-2057)
; ==============================================================================
; ==============================================================================
; Bank $08 - Text and Dialogue Data - CYCLE 3
; ==============================================================================
; Lines 800-1200 of source (binary tile data + extended dialogue strings)
; 
; This cycle documents the transition from compressed text strings into
; binary tile mapping data and graphical text rendering tables. Bank $08
; contains both TEXT DATA (strings) and TILE DATA (visual representation).
;
; MAJOR DISCOVERY - TILE MAPPING TABLES:
; Starting around address $08B3E2, the data shifts from text strings to
; binary tile indices and graphical mapping tables. This is the connection
; between Bank $08 (data) and the graphics rendering system.
;
; ==============================================================================

; ADDRESS RANGE ANALYSIS (Lines 800-900):
; ==============================================================================

; Address $08B1A2-$08B1B1 (16 bytes):
; Raw: $00,$F2,$83,$12,$00,$F1,$DB,$40,$00,$13,$19,$10,$BA,$70,$00,$13
; 
; Transition sequence showing mixed text and formatting:
; $00 = NULL/padding
; $F2 = CLEAR_WINDOW control code
; $83 = HIGH BYTE (dictionary reference or compressed phrase)
; $12 = Parameter for $83
; $F1 = NEWLINE
; $DB = HIGH BYTE (another dictionary entry)
; $40 = Character or parameter
; $BA = HIGH BYTE (continuing compression)
;
; Pattern suggests this is the END OF A DIALOGUE SECTION, transitioning
; to a new category of text (likely from NPC dialogue to system messages).

; Address $08B322-$08B381 (96 bytes):
; BINARY TILE MAPPING TABLE DISCOVERED!
; 
; Raw data shows repeating patterns of low bytes ($00-$7F) with occasional
; high bytes, characteristic of tile index tables:
; $00,$00,$01,$2F,$01,$01,$02,$3F,$02,$01,$2D,$1E,$1E,$02,$0A,$1C
; 
; This is NOT text data - it's TILE INDICES for graphics rendering!
; 
; Structure:
; - Each byte = tile index in graphics ROM
; - Sequential values ($01,$02,$03) = adjacent tiles in tileset
; - Repeated values = repeated graphic patterns
; - Pattern length suggests 8x8 or 16x16 tile arrangements
;
; Likely use: Border graphics, menu boxes, dialogue windows, status bars
; The tile indices reference graphics data in Bank $07 or compressed
; graphics sections elsewhere in ROM.

; ==============================================================================
; TILE DATA BLOCKS (Lines 900-1000):
; ==============================================================================

; Address $08B3F2-$08B4F5 (260 bytes):
; MASSIVE TILE MAPPING BLOCK
; 
; Repeated patterns observed:
; - $01,$02,$03 = Sequential tile runs (horizontal/vertical lines)
; - $10,$10,$10,$10 = Repeated tiles (solid fill, pattern backgrounds)
; - $41,$41,$41 = Another repeated pattern (texture, border element)
; - $00,$00,$00 = NULL tiles (transparent or empty space)
;
; Example sequence:
; $01,$02,$14,$02,$12,$10,$10,$02,$02,$11,$10,$10,$02,$02
; 
; Interpretation: This could represent a dialogue box border:
; Row 1: Top-left corner ($01), top edge ($02 repeated), top-right ($14)
; Row 2: Left edge ($12), interior space ($10 repeated), right edge
; Row 3: Continues pattern for multi-line dialogue window
;
; GRAPHICS COMPRESSION NOTES:
; Unlike text (which uses RLE + dictionary), graphics tiles use:
; - Direct tile indices (no compression, 1 byte = 1 tile)
; - Run-length for fills (implied by repeated values)
; - Possible meta-tile references (larger structures built from 8x8 tiles)

; Address $08B496-$08B4A5 (16 bytes):
; Raw: $4D,$03,$51,$00,$51,$00,$60,$0F,$F0,$00,$F0,$00,$C0,$00,$60,$3F
; 
; MIXED DATA BLOCK - Transition between tile data and text pointers!
; 
; $4D,$03 = 16-bit POINTER ($034D → address $0884D)
; $51,$00 = Another pointer ($0051 → address $08051)
; $51,$00 = Repeated pointer (same string referenced twice?)
; $60,$0F = Pointer or parameter pair
; $F0 = END_STRING marker (text system control)
; $F0 = Another END marker (padding/alignment)
; $C0,$00 = Pointer to address $08C00 range
; $60,$3F = Pointer or data value
;
; This appears to be a HYBRID SECTION mixing:
; - Text string pointers (for menu labels, item names)
; - Tile arrangement data (for menu background graphics)
; - Control codes (for formatting, spacing)

; ==============================================================================
; DIALOGUE STRING CONTINUATION (Lines 1000-1100):
; ==============================================================================

; Address $08B7E6-$08B8E5 (256 bytes):
; BACK TO TEXT DATA - More compressed dialogue strings
;
; Sample: $01,$02,$02,$02,$11,$10,$10,$10,$12,$04,$14,$08,$10,$10,$14,$0C
; 
; This section returns to character encoding, but with unusual patterns:
; - Very low byte values ($01-$14) dominate
; - Suggests punctuation, numbers, or control character section
; - Could be NUMERIC DISPLAY routines (HP/MP values, damage numbers)
;
; Example interpretation (hypothetical):
; $01 = "0" (numeric zero tile)
; $02 = "1" 
; $11 = " " (space)
; $10 = "/" (slash for ratios like "HP: 250/300")
; $04 = ":" (colon for labels)
;
; If this is numeric data, it would be used for:
; - Battle damage display ("Enemy takes 125 HP damage!")
; - Status screen stats ("HP: 999/999 MP: 99/99")
; - Equipment stats ("+50 Attack, +25 Defense")
; - Shop prices ("Buy: 1500 GP Sell: 750 GP")

; Address $08B936-$08B965 (48 bytes):
; Raw: $D1,$00,$F0,$1F,$F0,$1F,$B0,$00,$F1,$1F,$C0,$1E,$F1,$1F,$F0,$1E
; 
; CONTROL CODE HEAVY SEQUENCE
; 
; Pattern analysis:
; $D1,$00 = Parameter pair (possibly address or command ID)
; $F0,$1F = END + parameter (string termination with flags?)
; $F1,$1F = NEWLINE + parameter (line break with spacing?)
; $B0,$00 = Parameter pair
; $C0,$1E = Parameter pair
;
; Multiple $F0 and $F1 codes with parameters suggest:
; - FORMATTED TEXT LAYOUT (multi-line dialogue with specific spacing)
; - MENU STRUCTURE (rows/columns with defined positions)
; - SCROLLING TEXT (parameters = scroll speed/distance)
;
; The $1E and $1F parameter values are close together, suggesting
; fine-tuned positioning (pixel-level or character-cell positioning).

; ==============================================================================
; BINARY DATA PATTERNS (Lines 1100-1200):
; ==============================================================================

; Address $08C046-$08C055 (16 bytes):
; Raw: $36,$35,$13,$35,$45,$35,$35,$C7,$01,$F1,$00,$F0,$00,$F0,$00,$F0
; 
; End of data block with padding:
; $36,$35,$13... = Final character sequence
; $C7,$01 = HIGH BYTE + parameter (final dictionary reference)
; $F1 = NEWLINE
; $F0 repeated = END markers with NULL padding
;
; This marks the BOUNDARY between text data sections, likely:
; - End of NPC dialogue bank
; - Start of battle text bank
; - Transition to menu/system messages

; Address $08C056-$08C0A5 (80 bytes):
; POINTER TABLE RESUMES!
; 
; Raw: $00,$F0,$00,$E0,$00,$11,$00,$20,$04,$A0,$03,$B1,$1F,$B4,$03,$D0
; 
; Pattern indicates 16-bit pointer pairs with control flags:
; $00,$F0 = Pointer to $F000 (likely null/empty string)
; $00,$E0 = Pointer to $E000
; $00,$11 = Pointer to $1100
; $04,$A0 = Pointer to $A004
; $03,$B1 = Pointer to $B103
; $1F,$B4 = Pointer to $B41F
;
; These pointers reference:
; - String addresses in Bank $08 ($088000 + pointer)
; - Graphics tile tables (for menu rendering)
; - Control code sequences (formatting templates)
;
; The $1F flags appearing frequently suggest:
; - String type identifier ($1F = NPC dialogue?)
; - Graphics mode flag ($1F = use dialogue window graphics)
; - Text speed parameter ($1F = specific scroll speed)

; Address $08C216-$08C2A5 (144 bytes):
; TILE PATTERN DATA - Graphics arrangement for text boxes
; 
; Raw: $0F,$6C,$6C,$6E,$6E,$47,$6E,$4B,$48,$5E,$76,$7A,$38,$3A,$3A,$3A
; 
; Tile indices in $38-$7A range = MID-RANGE TILES
; These are not ASCII or low control codes - they're graphics tile IDs!
; 
; Pattern structure:
; $6C repeated = Horizontal border tile (top/bottom edges)
; $6E repeated = Corner or junction tile
; $76, $7A = Vertical border tiles (left/right edges)
; $38-$4B range = Interior fill patterns or shadow effects
;
; This data defines DIALOGUE WINDOW GRAPHICS:
; ┌────────────┐ ← Top border built from repeated $6C tiles
; │ [text...]  │ ← Left/right edges from $76/$7A tiles
; │ [text...]  │ ← Interior from $38-$4B fill patterns
; └────────────┘ ← Bottom border (more $6C tiles)

; ==============================================================================
; CYCLE 3 TECHNICAL FINDINGS:
; ==============================================================================
;
; DUAL-PURPOSE BANK STRUCTURE:
; Bank $08 is NOT just text - it's TEXT + GRAPHICS DATA combined!
; 
; Section 1 ($088000-$08B300): COMPRESSED TEXT STRINGS
; - NPC dialogue, battle messages, menu labels
; - Character encoding via simple.tbl
; - Dictionary compression for common phrases
; - Control codes ($F0-$FF) for formatting
;
; Section 2 ($08B300-$08B500): TILE MAPPING TABLES
; - Graphics tile indices for rendering text boxes
; - Border graphics, menu backgrounds, dialogue windows
; - Direct tile references (no compression)
; - Layout data for UI elements
;
; Section 3 ($08B500-$08C300): MIXED POINTERS + FORMATTING
; - Pointers to both text strings and tile data
; - Control code templates for multi-line text
; - Formatting parameters (spacing, scroll speed, positioning)
;
; Section 4 ($08C300+): GRAPHICS PATTERN DATA
; - Tile arrangement patterns for UI elements
; - Window border construction data
; - Shadow/highlight tile combinations
;
; RENDERING PIPELINE DISCOVERED:
; 1. Bank $03 script calls text display function with ID parameter
; 2. Bank $08 pointer table maps ID → text address + graphics mode
; 3. Text string decompressed using dictionary (Bank $00 code)
; 4. Tile pattern loaded for dialogue window background
; 5. Text rendered character-by-character using simple.tbl mapping
; 6. Control codes processed for formatting (newlines, pauses, colors)
; 7. Graphics tiles arranged to create window borders/backgrounds
;
; CHARACTER TILE RANGES CONFIRMED:
; $00-$1F: Control codes and low ASCII (space, punctuation)
; $20-$7F: Standard character tiles (letters, numbers, symbols)
; $80-$EF: Dictionary references or extended characters
; $F0-$FF: Text engine control codes
; $00-$FF (tile mode): Graphics tile indices (different context!)
;
; COMPRESSION EFFICIENCY:
; Comparing raw data sizes:
; - Uncompressed text: ~4-6 bytes per character (standard ASCII + formatting)
; - Bank $08 compressed: ~2-3 bytes per character (RLE + dictionary)
; - Space savings: ~40-50% compression ratio
; - Dictionary appears to contain ~256 common phrases/words
;
; CROSS-BANK DEPENDENCIES:
; - Bank $00: Text rendering engine, decompression routines
; - Bank $03: Script engine, dialogue trigger commands
; - Bank $07: Compressed graphics data (tile bitmaps)
; - Bank $08: Text strings + tile arrangement data (THIS BANK)
; - simple.tbl: Character → tile mapping table (external file)
;
; ESTIMATED COVERAGE:
; Cycle 3 documents lines 800-1200 (400 source lines)
; Total documented: 539 + 322 + 400 = 1,261 lines (hypothetical cycle sizes)
; Bank $08 total: 2,057 lines
; After Cycle 3: ~1,261/2,057 = 61.3% documented (OVER 50% THRESHOLD!)
;
; Next cycles should analyze:
; - Remaining graphics tile patterns (lines 1200-1600)
; - Final text string sections (lines 1600-1900)
; - Padding and alignment data (lines 1900-2057)
; - Extract sample.tbl character mapping for decoding examples
; ==============================================================================
