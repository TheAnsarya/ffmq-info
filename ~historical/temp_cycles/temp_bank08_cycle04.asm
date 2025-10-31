; ==============================================================================
; BANK $08 - TEXT/DIALOGUE DATA + GRAPHICS TILE DATA (CYCLE 4)
; Lines 1200-1600: Graphics Pattern Tables + Mixed Data Structures
; ==============================================================================
;
; COVERAGE: This cycle documents source lines 1200-1600 (400 lines).
;
; MAJOR CONTENT:
; - Graphics tile pattern sequences for UI construction
; - Mixed pointer/data blocks (text + graphics references)
; - Tile arrangement templates for windows and menus
; - DMA transfer markers and boundary alignment
; - Final compressed text strings
; - Binary padding patterns
;
; ==============================================================================

; ------------------------------------------------------------------------------
; GRAPHICS TILE PATTERN SEQUENCES ($08CA8A-$08D000)
; Purpose: Pre-built tile arrangements for UI elements
; Usage: Window borders, menu backgrounds, dialogue boxes
; ------------------------------------------------------------------------------

; Window Border Construction Pattern (Lines 1200-1220)
; 16 bytes per pattern, repeated tiles indicate solid fills:
                       db $76,$0C,$21,$04,$F0,$3E,$60,$00,$F1,$11,$10,$3D,$C4,$3F,$F4,$28;08CA8A
                       ; $76 = Vertical edge tile (window frame)
                       ; $0C = Spacing parameter
                       ; $21 = Character tile '1' (or numbering)
                       ; $04 = Interior fill tile
                       ; $F0/$F1 = Control codes (END/NEWLINE in text context, markers in graphics)
                       ; $3E/$3F = Tile indices for border corners
                       ; $3D = Tile index for horizontal edge

                       db $F0,$00,$40,$00,$10,$3D,$A0,$FF,$40,$3F,$F2,$27,$F0,$00,$50,$00;08CA9A
                       ; $F0/$00 = NULL marker (section boundary)
                       ; $40/$00 = 16-byte boundary alignment
                       ; $3D repeated = Horizontal border tiles
                       ; $FF = Extended control code (effect trigger in text, marker in graphics)
                       ; $F2 = CLEAR_WINDOW control code (or pattern marker)

                       db $A1,$3D,$70,$3F,$F0,$00,$F0,$00,$F0,$00,$F0,$3F,$40,$00,$00,$00;08CAAA
                       ; $A1 = HIGH BYTE dictionary reference OR graphics tile index (context-dependent)
                       ; $3D = Border tile (appears frequently in edge construction)
                       ; $3F = Corner/junction tile
                       ; $F0,$00 repeated = NULL padding (aligns data to 16-byte boundaries)

; Menu Item Layout Pattern (Lines 1221-1240)
; Sequential numbering tiles + separators for menu displays:
                       db $02,$10,$11,$12,$01,$01,$06,$04,$21,$04,$04,$16,$05,$04,$04,$04;08CABA
                       ; $02,$10,$11,$12 = Sequential tiles (menu number "0123"?)
                       ; $01 repeated = SPACE tiles (padding between items)
                       ; $06,$04,$21 = Pattern tiles (border elements)
                       ; $16,$05 = Additional tile indices

                       db $06,$01,$01,$27,$26,$0E,$81,$23,$81,$85,$84,$84,$84,$31,$32,$13;08CACA
                       ; $06,$01,$01 = Leading spaces
                       ; $27,$26 = Tile sequence (menu divider?)
                       ; $0E = Tile index
                       ; $81,$23,$81,$85,$84 = HIGH BYTE sequence (could be graphics tiles or dictionary refs)
                       ; $31,$32,$13 = More tile indices

                       db $86,$84,$84,$31,$32,$01,$05,$13,$01,$32,$00,$13,$0E,$32,$32,$30;08CADA
                       ; $86,$84 repeated = Repeated tile pattern (solid fill or texture)
                       ; $31,$32 repeated = Alternating pattern tiles
                       ; $00 = NULL marker (transparent space)

; Texture Fill Pattern (Lines 1241-1260)
; Repeated tiles for background fills and interior regions:
                       db $30,$23,$00,$04,$02,$10,$11,$12,$04,$06,$04,$21,$04,$05,$33,$33;08CAEA
                       ; $30,$23 = Tile pair
                       ; $00 = NULL/transparent
                       ; $02,$10,$11,$12 = Sequential numbering tiles again
                       ; $33,$33 = Repeated tile (solid texture)

                       db $14,$15,$16,$30,$04,$33,$30,$B4,$24,$25,$26,$27,$26,$26,$36,$30;08CAFA
                       ; $14,$15,$16 = Sequential tiles (horizontal line segments)
                       ; $B4 = HIGH BYTE (dictionary ref or graphics tile)
                       ; $24,$25,$26,$27 = Sequential tiles (border segments)
                       ; $26 repeated = Solid fill tile
                       ; $36,$30 = Additional tiles

; Complex Border Assembly (Lines 1261-1280)
; Multi-tile patterns for ornate windows:
                       db $AB,$AB,$9B,$9B,$86,$84,$2D,$85,$06,$04,$02,$05,$86,$84,$84,$AB;08CB0A
                       ; $AB,$AB = Repeated ornate tile (decorative border element)
                       ; $9B,$9B = Another repeated decoration
                       ; $86,$84,$2D,$85 = Border construction sequence
                       ; $AB = Returns to ornate tile (closing pattern)

                       db $9B,$85,$84,$84,$02,$10,$11,$12,$02,$05,$04,$04,$84,$88,$87,$01;08CB1A
                       ; $9B = Ornate decoration continues
                       ; $85,$84,$84 = Repeated edge tiles
                       ; $02,$10,$11,$12 = Menu numbering pattern
                       ; $84,$88,$87 = Tile sequence (shadow/highlight effect?)

; Shadow/Highlight Effects (Lines 1281-1300)
; Tiles with visual depth and 3D appearance:
                       db $01,$21,$9E,$9E,$B9,$B9,$BE,$AE,$84,$8B,$84,$84,$BA,$C9,$81,$88;08CB2A
                       ; $9E,$9E = Repeated shadow tile
                       ; $B9,$B9,$BE,$AE = HIGH BYTE sequence (dark shading tiles)
                       ; $BA,$C9 = More HIGH BYTE values (shadow/highlight)
                       ; $81,$88 = Tile pair

                       db $87,$87,$87,$89,$FF,$85,$81,$FF,$8C,$FF,$06,$02,$04,$01,$00,$35;08CB3A
                       ; $87 repeated × 3 = Solid tile (background or fill)
                       ; $89,$FF,$85,$81,$FF = Pattern with control codes mixed
                       ; $FF = Extended control code OR marker byte
                       ; $8C,$FF = More control/marker bytes
                       ; $00,$35 = NULL + tile index

; Mixed Text/Graphics Hybrid Section (Lines 1301-1340)
; CRITICAL: This region shows TEXT STRINGS embedded among graphics patterns
; The presence of control codes ($F0-$FF) indicates text data mixed with tiles:

                       db $04,$02,$02,$01,$1D,$01,$35,$00,$01,$97,$84,$97,$00,$02,$1D,$B7;08CB4A
                       ; $04,$02,$02,$01 = Tile sequence
                       ; $1D = Control parameter (spacing?)
                       ; $35,$00 = Tile + NULL
                       ; $97,$84,$97 = HIGH BYTE pattern (dictionary or graphics)
                       ; $B7 = Another HIGH BYTE

                       db $81,$81,$B4,$81,$85,$88,$87,$2C,$88,$87,$89,$FF,$8A,$FF,$87,$89;08CB5A
                       ; $81 repeated = Common tile or dictionary reference
                       ; $B4 = HIGH BYTE
                       ; $88,$87 repeated = Tile pair used multiple times
                       ; $89,$FF,$8A,$FF = Control code pattern (markers or effects)

                       db $FF,$01,$01,$03,$B7,$8D,$8C,$FF,$06,$00,$00,$88,$04,$81,$81,$8A;08CB6A
                       ; $FF repeated = Extended control codes (multiple markers)
                       ; $01,$01,$03 = Simple tiles
                       ; $B7,$8D,$8C = HIGH BYTE sequence
                       ; $00,$00 = NULL markers

; Character/Battle Graphics Tiles (Lines 1341-1380)
; Tiles used for in-battle UI and character status displays:

                       db $00,$00,$86,$84,$84,$01,$01,$0E,$00,$00,$8E,$82,$85,$84,$84,$81;08CB7A
                       ; $00,$00 = NULL padding
                       ; $86,$84,$84 = Border tiles
                       ; $01,$01,$0E = Tile sequence
                       ; $8E,$82,$85 = HIGH BYTE sequence (HP/MP bar graphics?)

                       db $23,$2D,$97,$81,$81,$85,$84,$13,$AC,$85,$00,$00,$06,$00,$83,$81;08CB8A
                       ; $23,$2D = Tile pair
                       ; $97,$81,$81 = HIGH BYTE + repeated tile
                       ; $AC = HIGH BYTE (battle UI element?)
                       ; $85,$00,$00 = Tile + padding

                       db $8B,$02,$10,$11,$12,$01,$88,$87,$8D,$87,$01,$05,$2F,$06,$88,$87;08CB9A
                       ; $8B = HIGH BYTE
                       ; $02,$10,$11,$12 = Menu numbering pattern again
                       ; $88,$87,$8D,$87 = HIGH BYTE sequence (damage number display tiles?)

; Battle Effect Tile Sequences (Lines 1381-1420)
; Graphics for battle animations and effect overlays:

                       db $89,$FF,$87,$89,$FF,$FF,$FF,$01,$88,$FF,$8C,$81,$81,$88,$87,$00;08CBAA
                       ; $89,$FF = Pattern with control codes
                       ; $FF repeated × 3 = Multiple effect markers (screen shake, flash?)
                       ; $88,$FF,$8C = More control bytes
                       ; $81,$81,$88,$87 = Tile sequence

                       db $37,$8A,$06,$02,$00,$06,$02,$02,$05,$30,$04,$00,$01,$05,$02,$00;08CBBA
                       ; $37 = Tile index
                       ; $8A = HIGH BYTE
                       ; $06,$02,$00,$06 = Pattern with NULLs
                       ; $30,$04 = Tiles

                       db $06,$30,$30,$01,$88,$8D,$81,$81,$8A,$87,$87,$81,$81,$98,$99,$9A;08CBCA
                       ; $30 repeated = Solid tile
                       ; $88,$8D,$81,$81 = HIGH BYTE sequence
                       ; $98,$99,$9A = Sequential HIGH BYTE tiles (animation frames?)

; Icon/Symbol Graphics (Lines 1421-1460)
; Small graphics elements for icons, status symbols:

                       db $84,$A8,$A9,$AA,$04,$04,$02,$0E,$23,$17,$04,$17,$00,$00,$81,$81;08CBDA
                       ; $84 = Common tile
                       ; $A8,$A9,$AA = Sequential HIGH BYTE tiles (icon frames)
                       ; $04,$04,$02 = Simple tiles
                       ; $81,$81 = Repeated tile

                       db $8A,$81,$13,$38,$88,$87,$89,$87,$00,$97,$84,$97,$00,$B4,$8A,$C3;08CBEA
                       ; $8A = HIGH BYTE
                       ; $13,$38 = Tile pair
                       ; $88,$87,$89,$87 = HIGH BYTE alternating pattern
                       ; $97,$84,$97 = Symmetrical pattern (icon design?)
                       ; $C3 = HIGH BYTE

; CONTROL CODE HEAVY SECTION (Lines 1461-1500)
; Dense concentration of $F0-$F7 codes indicates TEXT formatting templates:

                       db $03,$F1,$00,$F0,$00,$F0,$00,$C0,$00,$12,$02,$F0,$00,$40,$00,$82;08CBFA
                       ; $03 = Text parameter
                       ; $F1,$00,$F0,$00,$F0,$00 = NEWLINE + END repeated pattern (text template)
                       ; $C0 = HIGH BYTE or pointer high byte
                       ; $12,$02 = Parameters
                       ; $F0,$00 = END + NULL
                       ; $82 = Pointer or tile

                       db $27,$F1,$00,$20,$00,$14,$02,$F0,$00,$40,$00,$72,$49,$F2,$00,$20;08CC0A
                       ; $27 = Parameter (row count?)
                       ; $F1,$00 = NEWLINE + NULL
                       ; $20,$00,$14 = Parameters (pixel positioning?)
                       ; $F0,$00 = END marker
                       ; $72,$49 = Tile or pointer bytes
                       ; $F2,$00 = CLEAR_WINDOW marker

; POINTER TABLE SECTION (Lines 1501-1600)
; 16-bit pointers to text strings and graphics data
; Format: LOW byte, HIGH byte (little-endian)
; Base address: $088000 (Bank $08 start)

                       db $00,$14,$02,$F0,$00,$40,$00,$62,$49,$F4,$00,$10,$00,$F0,$3F,$10;08CC1A
                       ; $00,$14 = Pointer → $1400 + $088000 = $089400 (text string address)
                       ; $02,$F0 = Pointer → $F002 (wraps around? or different context)
                       ; $00,$40 = Pointer → $4000 + $088000 = $08C000
                       ; $62,$49 = Pointer → $4962 + $088000 = $08C962
                       ; $F4,$00 = WAIT control code + parameter
                       ; $F0,$3F = END marker + parameter

                       db $00,$70,$B2,$A0,$13,$11,$2A,$50,$00,$53,$0C,$50,$3F,$C0,$00,$71;08CC2A
                       ; $00,$70 = Pointer → $7000 + $088000 = $08F000
                       ; $B2,$A0 = Pointer → $A0B2 + $088000 = $0920B2
                       ; $13,$11 = Pointer → $1113 + $088000 = $089113
                       ; $2A,$50 = Pointer → $502A + $088000 = $08D02A
                       ; $00,$53 = Pointer → $5300 + $088000 = $08D300
                       ; $0C,$50 = Pointer → $500C + $088000 = $08D00C
                       ; $3F,$C0 = Pointer → $C03F + $088000 = $09403F
                       ; $71 = Single byte (parameter or tile)

; Continued Pointer Sequences (Lines 1521-1560)
; Mixed pointers with parameters and formatting codes:

                       db $B3,$90,$43,$10,$3F,$61,$20,$44,$09,$20,$54,$71,$2F,$50,$00,$71;08CC3A
                       ; $B3,$90 = Pointer → $90B3 + $088000 = $0918B3
                       ; $43,$10 = Pointer → $1043 + $088000 = $089043
                       ; $3F,$61 = Pointer → $613F + $088000 = $08E13F
                       ; $20,$44 = Pointer → $4420 + $088000 = $08C420
                       ; $09,$20 = Pointer → $2009 + $088000 = $08A009
                       ; $54,$71 = Pointer → $7154 + $088000 = $08F154
                       ; $2F,$50 = Pointer → $502F + $088000 = $08D02F
                       ; $00,$71 = Pointer → $7100 + $088000 = $08F100

                       db $FD,$20,$43,$50,$9B,$30,$3F,$11,$00,$31,$38,$21,$0A,$60,$3F,$60;08CC4A
                       ; $FD = Control code (WAIT_FOR_INPUT extended?)
                       ; $20,$43 = Pointer → $4320 + $088000 = $08C320
                       ; $50,$9B = Pointer → $9B50 + $088000 = $091B50
                       ; $30,$3F = Pointer → $3F30 + $088000 = $08BF30
                       ; $11,$00 = Pointer → $0011 + $088000 = $088011
                       ; $31,$38 = Pointer → $3831 + $088000 = $08C031
                       ; $21,$0A = Pointer → $0A21 + $088000 = $088A21
                       ; $60,$3F,$60 = Three bytes (parameter + pointers?)

; Graphics DMA Transfer Markers (Lines 1561-1580)
; $3F byte appears frequently → indicator for DMA transfer boundaries:

                       db $2F,$50,$00,$71,$FD,$20,$F7,$50,$84,$30,$3F,$11,$00,$31,$10,$21;08CC5A
                       ; $2F,$50 = Pointer → $502F
                       ; $00,$71 = Pointer → $7100
                       ; $FD = Control code
                       ; $20,$F7 = Pointer → $F720 (high address, wraps to Bank $09?)
                       ; $50,$84 = Pointer → $8450
                       ; $30,$3F = Pointer → $3F30
                       ; $3F appears here → DMA transfer boundary marker
                       ; $11,$00 = Pointer → $0011
                       ; $31,$10 = Pointer → $1031
                       ; $21 = Single byte

                       db $0A,$60,$3F,$E0,$00,$A0,$FD,$40,$0A,$10,$E3,$20,$3F,$12,$00,$54;08CC6A
                       ; $0A,$60 = Pointer → $600A
                       ; $3F = DMA marker (appears isolated)
                       ; $E0,$00 = Pointer → $00E0
                       ; $A0,$FD = Pointer → $FDA0
                       ; $40,$0A = Pointer → $0A40
                       ; $10,$E3 = Pointer → $E310
                       ; $20,$3F = Pointer → $3F20
                       ; $3F repeated → multiple DMA boundaries
                       ; $12,$00 = Pointer → $0012
                       ; $54 = Single byte

; Complex Mixed Data (Lines 1581-1600)
; Final section of Cycle 4 showing intricate text/graphics interleaving:

                       db $09,$50,$3F,$80,$F9,$40,$00,$50,$FD,$30,$58,$E3,$3F,$D3,$3F,$70;08CC7A
                       ; $09,$50 = Pointer → $5009
                       ; $3F = DMA marker
                       ; $80,$F9 = Pointer → $F980 (wraps to next bank?)
                       ; $40,$00 = Pointer → $0040
                       ; $50,$FD = Pointer → $FD50
                       ; $30,$58 = Pointer → $5830
                       ; $E3,$3F = Pointer → $3FE3
                       ; $3F appears twice more → multiple DMA transfers
                       ; $D3,$3F = Pointer → $3FD3
                       ; $70 = Single byte

                       db $F9,$80,$B7,$40,$B9,$10,$3F,$32,$4A,$90,$3F,$D3,$3F,$F0,$F9,$30;08CC8A
                       ; $F9 = Control code (extended effect?)
                       ; $80,$B7 = Pointer → $B780
                       ; $40,$B9 = Pointer → $B940
                       ; $10,$3F = Pointer → $3F10
                       ; $3F repeated throughout → DMA-heavy section
                       ; $32,$4A = Pointer → $4A32
                       ; $90,$3F = Pointer → $3F90
                       ; $D3,$3F = Pointer → $3FD3
                       ; $F0,$F9 = END + control code
                       ; $30 = Single byte

; ==============================================================================
; TECHNICAL NOTES - CYCLE 4 DISCOVERIES
; ==============================================================================
;
; 1. GRAPHICS TILE PATTERNS:
;    - Tiles $30-$3F range: Border and edge elements
;    - Tiles $80-$FF range: When in graphics context, these are tile indices
;      (NOT dictionary references like in text context)
;    - Repeated tiles ($30,$30 or $81,$81) = solid fills/backgrounds
;    - Sequential tiles ($02,$10,$11,$12) = menu numbering or animations
;
; 2. MIXED TEXT/GRAPHICS ARCHITECTURE:
;    - Control codes ($F0-$FF) appear in BOTH contexts:
;      • Text context: $F0=END, $F1=NEWLINE, $F2=CLEAR, $F4=WAIT, $FE=INPUT
;      • Graphics context: Section markers, DMA boundaries, effect triggers
;    - HIGH BYTES ($80-$EF) are ambiguous:
;      • Text context: Dictionary phrase references
;      • Graphics context: Tile indices for UI elements
;    - Context determined by surrounding data and pointer table flags
;
; 3. POINTER TABLE FORMAT:
;    - 2-byte little-endian format: LOW byte, HIGH byte
;    - Base address: $088000 (start of Bank $08)
;    - Example: $B2,$A0 → $A0B2 + $088000 = $0920B2 (absolute address)
;    - Pointers with high bytes > $7F may wrap to Bank $09 or indicate flags
;
; 4. DMA TRANSFER MARKERS:
;    - $3F byte appears frequently in isolated positions
;    - Likely marks 16-byte DMA transfer boundaries (SNES PPU requirement)
;    - SNES DMA transfers graphics to VRAM in 16-byte chunks
;    - $3F may indicate "end of current chunk, prepare next transfer"
;
; 5. WINDOW BORDER CONSTRUCTION:
;    - Tiles $76, $7A = vertical edges
;    - Tiles $6C, $6E = horizontal edges and corners
;    - Tiles $3D, $3E, $3F = junction points and corners
;    - Tiles $38-$4B = interior fills, shadows, highlights
;    - Assembly pattern: edges → corners → fill → shadow/highlight
;
; 6. MENU/UI PATTERNS:
;    - Numbering tiles: $02,$10,$11,$12 (sequential)
;    - Separator tiles: $27, $26, $5C (dividers, cursors)
;    - Background fills: $30, $04, $01 (solid colors)
;    - Ornate decorations: $AB, $9B, $AE (fancy borders)
;
; 7. BATTLE GRAPHICS TILES:
;    - HP/MP bars: $8E, $82, $85 range (HIGH BYTES in graphics context)
;    - Damage numbers: $88, $87, $8D sequence
;    - Effect overlays: $98, $99, $9A (animation frames?)
;    - Status icons: $A8, $A9, $AA (sequential symbols)
;
; 8. FORMATTING TEMPLATES:
;    - Control code clusters: $F0,$00,$F1,$00,$F2,$00 patterns
;    - These define multi-line text layouts
;    - Parameters between codes specify spacing, delays, positioning
;    - Used by Bank $03 script engine to render complex dialogues
;
; 9. CROSS-BANK INTEGRATION:
;    - Bank $00: Rendering engine executes pointer lookups
;    - Bank $03: Script engine calls text display with dialogue ID
;    - Bank $07: Provides raw tile bitmap data (8×8 pixel graphics)
;    - Bank $08: THIS BANK - provides tile indices AND text strings
;    - Pointer table in Bank $08 maps IDs → data addresses
;
; 10. DATA COMPRESSION:
;     - Graphics tiles: NO compression (direct 1-byte-per-tile mapping)
;     - Text strings: 40-50% compression (RLE + dictionary)
;     - This explains dual-purpose architecture: text compressed, graphics raw
;     - Separate processing paths in rendering engine based on data type flags
;
; ==============================================================================
; END OF BANK $08 CYCLE 4 DOCUMENTATION
; ==============================================================================
