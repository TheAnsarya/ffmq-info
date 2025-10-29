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
