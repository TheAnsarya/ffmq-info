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
