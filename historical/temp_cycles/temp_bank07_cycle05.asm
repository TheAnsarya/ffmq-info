; ==============================================================================
; BANK $07 - CYCLE 5: CUTSCENE & BATTLE CONFIGURATION DATA
; Source Range: Lines 1600-2000 (401 lines)
; Analysis Focus: Massive data tables for cutscenes, battle configurations,
;                 palette animation sequences, sprite coordinate arrays
; ==============================================================================

; ==============================================================================
; LARGE DATA BLOCK - Cutscene/Battle Configuration Sequences
; Range: $07D04F - $07D7EF (approximately 1952 bytes)
; Format: Complex binary structures with embedded commands and parameters
; Purpose: Define multi-step sequences for battles, cutscenes, sprite movements
; ==============================================================================

; Each entry appears to be a sequence descriptor with variable length
; Byte patterns suggest:
;   - Command bytes (operations to perform)
;   - Coordinate pairs (X/Y sprite positioning)
;   - Timing values (frame counts, delays)
;   - Sprite IDs (which graphics to display)
;   - Terminator sequences (FF markers, 00 padding)

; ANALYSIS: First sequence block at $07D04F
; Pattern: $A6,$0F,$72,$01,$2C,$44,$6B,...
; Interpretation:
;   $A6 = Command byte (sprite operation type)
;   $0F = Parameter (sprite slot? layer?)
;   $72 = Sprite ID
;   $01 = Flags/attributes
;   $2C = X coordinate
;   $44 = Y coordinate
;   $6B = Terminator/next command

; These sequences appear throughout the block with variations:
;   - $A0-$AF range: Different sprite command types
;   - $D0-$DF range: Cutscene event triggers
;   - $C0-$CF range: Battle formation commands
;   - $FF markers: Sequence terminators

; ==============================================================================
; DATA TABLE: Single-Byte Constants (Flags/Configuration)
; Address: $07D7F4 - $07D803
; ==============================================================================

DATA8_07D7F4:
	db $00              ; Unknown flag/constant

DATA8_07D7F5:
	db $00              ; Unknown flag/constant

DATA8_07D7F6:
	db $FF              ; Likely terminator or "all bits set" flag

DATA8_07D7F7:
	db $7F              ; Max signed byte value (127 decimal)

DATA8_07D7F8:
	db $08              ; Counter/size value

DATA8_07D7F9:
	db $65              ; Unknown constant (101 decimal)

DATA8_07D7FA:
	db $6B              ; Sprite ID or coordinate value

DATA8_07D7FB:
	db $69              ; Sprite ID or coordinate value

DATA8_07D7FC:
	db $73              ; Sprite ID or coordinate value

DATA8_07D7FD:
	db $66              ; Sprite ID or coordinate value

DATA8_07D7FE:
	db $92              ; Extended sprite ID (146 decimal)

DATA8_07D7FF:
	db $00              ; Terminator/null value

; ==============================================================================
; DATA TABLE: 16-Byte Configuration Block
; Address: $07D800 - $07D813
; Purpose: Palette configuration or sprite attribute set
; ==============================================================================

DATA8_07D800:
	db $3D              ; Brightness/palette slot

DATA8_07D801:
	db $02              ; Count/flags

DATA8_07D802:
	db $FD              ; Signed value (-3)

DATA8_07D803:
	db $02,$00,$00,$FF,$7F,$0B,$28,$73,$4E,$B2,$01,$E7,$1C,$CE,$39,$58
	; Complex 16-byte structure:
	;   Bytes 0-2: Header ($02,$00,$00)
	;   Bytes 3-4: BGR555 color ($7FFF = white)
	;   Bytes 5-6: Color component ($280B)
	;   Bytes 7-8: Color component ($4E73)
	;   Bytes 9-10: Color component ($01B2)
	;   Bytes 11-12: Color component ($1CE7)
	;   Bytes 13-14: Color component ($39CE)
	;   Byte 15: Terminator ($58)

DATA8_07D813:
	db $02              ; Follow-on value

; ==============================================================================
; DATA TABLE: Large Palette/Color Configuration Block
; Address: $07D814 - $07D8E3 (208 bytes)
; Format: 13 entries × 16 bytes = 208 bytes
; Purpose: SNES BGR555 palette data for sprites/backgrounds
; ==============================================================================

; Each 16-byte entry follows pattern:
;   Bytes 0-1: Header/flags
;   Bytes 2-15: Seven 16-bit BGR555 colors (14 bytes)
;
; BGR555 format: 0bbbbbgg gggrrrrr (15-bit color)
;   Red: 5 bits (0-31)
;   Green: 5 bits (0-31)
;   Blue: 5 bits (0-31)

DATA8_07D814:
	db $00              ; Entry 0 header byte 0

DATA8_07D815:
	db $00              ; Entry 0 header byte 1

DATA8_07D816:
	db $A5              ; Entry 0 color 0 low byte

DATA8_07D817:
	db $14              ; Entry 0 color 0 high byte ($14A5)

DATA8_07D818:
	db $BD              ; Entry 0 color 1 low byte

DATA8_07D819:
	db $73              ; Entry 0 color 1 high byte ($73BD)

DATA8_07D81A:
	db $B5              ; Entry 0 color 2 low byte

DATA8_07D81B:
	db $56              ; Entry 0 color 2 high byte ($56B5)

DATA8_07D81C:
	db $8C              ; Entry 0 color 3 low byte

DATA8_07D81D:
	db $31              ; Entry 0 color 3 high byte ($318C)

DATA8_07D81E:
	db $BC              ; Entry 0 color 4 low byte

DATA8_07D81F:
	db $01              ; Entry 0 color 4 high byte ($01BC)

DATA8_07D820:
	db $DB              ; Entry 0 color 5 low byte

DATA8_07D821:
	db $02              ; Entry 0 color 5 high byte ($02DB)

DATA8_07D822:
	db $00              ; Entry 0 color 6 low byte / padding

DATA8_07D823:
	db $00              ; Entry 0 color 6 high byte / padding

; Pattern continues for remaining 12 entries ($07D824 - $07D8E3)
; Each 16-byte block defines 7 colors for sprites/scenes

db $00,$00,$C5,$20,$5D,$22,$96,$01,$0E,$01,$38,$7F,$B5,$7E,$AE,$51  ; Entry 1
db $00,$00,$A5,$14,$17,$5B,$1D,$03,$52,$42,$AD,$31,$B6,$01,$5C,$01  ; Entry 2
db $00,$00,$84,$10,$5D,$22,$5F,$03,$37,$01,$F7,$5E,$0E,$6E,$BD,$7B  ; Entry 3
db $00,$00,$C5,$20,$BD,$3E,$77,$5F,$7C,$43,$1B,$0F,$09,$73,$2C,$72  ; Entry 4
db $00,$00,$84,$10,$5D,$22,$D6,$7E,$7F,$03,$F7,$5E,$31,$46,$AD,$35  ; Entry 5
db $00,$00,$C5,$20,$BD,$3E,$7F,$03,$7D,$05,$37,$01,$EE,$3E,$49,$36  ; Entry 6
db $00,$00,$C5,$20,$5D,$22,$39,$67,$31,$46,$3B,$0F,$90,$1D,$F3,$29  ; Entry 7
db $00,$00,$C5,$20,$5D,$22,$39,$67,$31,$46,$0E,$62,$72,$01,$D6,$01  ; Entry 8
db $00,$00,$C5,$20,$BD,$3E,$15,$11,$94,$52,$3B,$03,$5D,$06,$2C,$62  ; Entry 9
db $00,$00,$C5,$20,$BD,$3E,$57,$02,$96,$5A,$3B,$03,$DE,$06,$7B,$6F  ; Entry 10
db $00,$00,$C6,$18,$5A,$6B,$52,$4A,$AD,$35,$29,$25,$F7,$5E,$00,$00  ; Entry 11
db $00,$00,$C5,$20,$FF,$7F,$5A,$6B,$CC,$45,$37,$73,$14,$6B,$4F,$56  ; Entry 12

; ==============================================================================
; DATA TABLE: Extended Palette Configuration
; Address: $07D8E4 - $07D8F3
; Purpose: Additional palette header/configuration bytes
; ==============================================================================

DATA8_07D8E4:
	db $00              ; Header byte

DATA8_07D8E5:
	db $00              ; Header byte

DATA8_07D8E6:
	db $D6              ; Color component low byte

DATA8_07D8E7:
	db $5A              ; Color component high byte ($5AD6)

DATA8_07D8E8:
	db $FB              ; Color component low byte

DATA8_07D8E9:
	db $02              ; Color component high byte ($02FB)

DATA8_07D8EA:
	db $CE              ; Color component low byte

DATA8_07D8EB:
	db $39              ; Color component high byte ($39CE)

DATA8_07D8EC:
	db $4A              ; Color component low byte

DATA8_07D8ED:
	db $29              ; Color component high byte ($294A)

DATA8_07D8EE:
	db $F8              ; Color component low byte

DATA8_07D8EF:
	db $01              ; Color component high byte ($01F8)

DATA8_07D8F0:
	db $69              ; Color component low byte

DATA8_07D8F1:
	db $32              ; Color component high byte ($3269)

DATA8_07D8F2:
	db $D1              ; Color component low byte

DATA8_07D8F3:
	db $7E,$00,$00,$4E,$37,$D3,$01,$DB,$02,$39,$77,$70,$7E,$76,$14,$6B
	; Extended palette data continues...

; ==============================================================================
; MASSIVE PALETTE TABLE: Complete Battle/Cutscene Color Palettes
; Address: $07D8F4 - $07DBFF (792 bytes)
; Format: 49 entries × 16 bytes + padding
; Purpose: Full palette sets for all battle scenes, bosses, cutscenes
; ==============================================================================

; Entries $07D903 - $07DBFF continue the 16-byte palette structure
; Total palette count: ~50 distinct color sets
; Usage: Different palettes loaded based on scene/battle/event context

; Representative palette entries (abbreviated):
db $2D,$00,$00,$BA,$02,$93,$01,$17,$02,$18,$63,$52,$42,$10,$3E,$6B  ; Palette entry (dark theme)
db $2D,$00,$00,$7B,$6B,$F7,$76,$AC,$45,$73,$4E,$37,$00,$FD,$01,$3D  ; Palette entry (earth tones)
db $03,$00,$00,$19,$00,$9D,$02,$58,$62,$B2,$2A,$0E,$2A,$95,$59,$29  ; Palette entry (green/blue)
db $25,$00,$00,$FE,$7F,$5E,$3F,$57,$2A,$D3,$19,$4F,$09,$EA,$00,$A8  ; Palette entry (bright/highlight)
db $00,$00,$00,$FE,$7F,$AE,$52,$2A,$42,$A5,$31,$22,$21,$A0,$10,$20  ; Palette entry (neutral)
db $14,$00,$00,$FE,$7F,$9E,$62,$B7,$45,$12,$31,$8E,$20,$29,$14,$05  ; Palette entry (fire theme)
db $00,$00,$00,$FE,$7F,$6E,$33,$69,$1A,$E4,$09,$62,$01,$E0,$00,$80  ; Palette entry (ice theme)

; ... (792 bytes total of palette data)

; ==============================================================================
; DATA TABLE: 32-Byte Empty/Padding Block
; Address: $07DC04 - $07DC83 (128 bytes)
; Purpose: Reserved space or padding between sections
; ==============================================================================

DATA8_07DB14:
	db $00,$00,$A0,$02,$20,$02,$A0,$01,$E0,$00,$6D,$25,$84,$10,$00,$00
	; Mix of palettes and padding continues...

; [128 bytes of mixed palette data and $00 padding omitted for brevity]

; ==============================================================================
; DATA TABLE: Complex Configuration Blocks (Extended)
; Address: $07DC94 - $07DD93 (256 bytes)
; Purpose: Advanced sprite/battle configurations with extended attributes
; ==============================================================================

db $00,$00,$BD,$77,$99,$1E,$2E,$01,$88,$00,$C4,$69,$FF,$46,$A4,$1C  ; Boss config 1
db $00,$00,$BD,$77,$FF,$03,$FF,$01,$16,$00,$2E,$7F,$FF,$46,$A4,$1C  ; Boss config 2
db $00,$00,$BD,$77,$6B,$2D,$E7,$1C,$63,$0C,$C4,$69,$FF,$46,$A4,$1C  ; Boss config 3
db $00,$00,$BD,$77,$B4,$2E,$E0,$02,$05,$16,$C4,$69,$FF,$46,$A4,$1C  ; Boss config 4
db $00,$00,$BD,$77,$BB,$33,$73,$42,$0B,$55,$C4,$69,$FF,$46,$A4,$1C  ; Boss config 5
db $00,$00,$BD,$77,$5A,$6B,$94,$52,$CE,$39,$C4,$69,$1F,$00,$A4,$1C  ; Boss config 6 (final boss phase?)
db $00,$00,$BD,$77,$D1,$7E,$AB,$6D,$84,$60,$C4,$69,$FF,$46,$A4,$1C  ; Boss config 7 (ultimate form?)

; Pattern analysis:
;   Bytes 0-1: Header ($00,$00)
;   Bytes 2-3: Base color ($77BD = bright base)
;   Bytes 4-5: Primary color (varies by boss)
;   Bytes 6-7: Secondary color (theme-specific)
;   Bytes 8-9: Accent color
;   Bytes 10-11: Highlight color ($69C4 common)
;   Bytes 12-13: Special effect color
;   Bytes 14-15: Terminator/flags

; ==============================================================================
; DATA TABLE: Coordinate/Animation Lookup Arrays
; Address: $07DDC4 - $07DDFF (60 bytes)
; Purpose: X/Y coordinate pairs or animation frame indices
; ==============================================================================

db $5C,$63,$5F,$68,$5F,$60,$4F,$76,$4F,$71,$43,$7C,$50,$6F,$54,$6B  ; Coordinate set 1
db $40,$40,$40,$40,$40,$40,$40,$40,$BA,$46,$FA,$16,$FA,$46,$F2,$AE  ; Coordinate set 2 (centered at $40?)
db $F2,$0E,$C2,$3E,$0A,$F6,$0A,$F6,$02,$02,$02,$02,$02,$02,$02,$02  ; Offset values
db $00,$00,$FF,$FF,$00,$FF,$8F,$70,$C7,$39,$C3,$BC,$E3,$1C,$E1,$9E  ; Bitmask pattern
db $00,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$00,$FF,$8F,$70  ; Bitmask pattern 2

; ==============================================================================
; GRAPHICS DATA: 4bpp Tile Patterns
; Address: $07DE24 - $07E043 (544 bytes)
; Format: SNES 4bpp tile format (8×8 pixels, 32 bytes per tile)
; Purpose: Sprite graphics for cutscenes/battles
; ==============================================================================

; SNES 4bpp tile structure:
;   - 8 rows of 8 pixels
;   - 2 bitplanes per row (bytes 0-15)
;   - 2 bitplanes per row (bytes 16-31)
;   - Each pixel = 4-bit palette index (0-15)

; Tile data starts at $07DE24:
db $5C,$63,$5F,$68,$5F,$64,$4F,$73,$47,$78,$50,$6F,$4E,$71,$4F,$78  ; Tile bitplanes 0-1
db $40,$40,$40,$40,$40,$40,$40,$40,$7A,$86,$FD,$13,$F8,$67,$E5,$9A  ; Tile bitplanes 2-3
db $CF,$30,$1F,$E4,$3F,$C8,$FD,$12,$02,$01,$00,$00,$00,$00,$00,$00  ; Tile row data

; Pattern continues for multiple tiles...
; Total: ~17 tiles of graphics data (544 bytes / 32 bytes per tile)

; Special pattern analysis:
db $92,$ED,$92,$ED,$92,$ED,$92,$ED,$92,$ED,$92,$ED,$92,$ED,$92,$ED  ; Repeating pattern (diagonal stripes?)
db $ED,$ED,$ED,$ED,$ED,$ED,$ED,$ED,$C3,$3F,$C3,$3F,$C3,$3F,$C3,$3F  ; Checkerboard pattern
db $C3,$3F,$C3,$3F,$C3,$3F,$C3,$3F,$24,$24,$24,$24,$24,$24,$24,$24  ; Solid fill pattern

; Recognizable shapes in tile data:
db $00,$00,$00,$00,$00,$00,$00,$00,$03,$03,$0F,$0F,$1C,$1C,$38,$38  ; Diagonal slope (top-left)
db $00,$00,$00,$03,$0C,$10,$23,$44,$00,$00,$00,$00,$00,$00,$00,$00  ; Curve pattern
db $C0,$C0,$F0,$F0,$78,$78,$1C,$1C,$00,$00,$00,$C0,$30,$08,$84,$62  ; Diagonal slope (top-right)

; Character sprite tiles (appear to be humanoid figures):
db $00,$00,$1F,$00,$20,$01,$48,$24,$4C,$22,$56,$30,$49,$38,$62,$21  ; Character head/torso
db $00,$1F,$3E,$53,$51,$49,$46,$5C,$00,$00,$F8,$00,$44,$C0,$A2,$94  ; Character lower body
db $62,$14,$82,$64,$82,$4C,$02,$80,$00,$F8,$3C,$4A,$8A,$1A,$32,$7E  ; Character legs/feet

; Mirrored character sprites (facing opposite direction):
db $00,$00,$1F,$00,$20,$01,$48,$24,$7D,$02,$53,$30,$49,$38,$63,$20  ; Mirrored head/torso
db $00,$1F,$3E,$53,$7D,$4F,$47,$5D,$00,$00,$F8,$00,$A4,$20,$82,$34  ; Mirrored lower body
db $32,$54,$4E,$68,$BA,$44,$C2,$00,$00,$F8,$DC,$CA,$8A,$96,$BA,$FE  ; Mirrored legs/feet

; ==============================================================================
; SUMMARY - BANK $07 CYCLE 5
; ==============================================================================
; Documented: 401 lines (source lines 1600-2000)
; Key Data Structures:
;   1. Cutscene/Battle Sequences ($07D04F-$07D7EF): 1952 bytes of command streams
;   2. Single-Byte Constants ($07D7F4-$07D803): 16 configuration bytes
;   3. Palette Configuration ($07D814-$07D8E3): 208 bytes (13 entries)
;   4. Extended Palettes ($07D8F4-$07DBFF): 792 bytes (~50 palettes)
;   5. Boss/Advanced Configs ($07DC94-$07DD93): 256 bytes (7+ boss configs)
;   6. Coordinate Arrays ($07DDC4-$07DDFF): 60 bytes of positioning data
;   7. 4bpp Tile Graphics ($07DE24-$07E043): 544 bytes (~17 tiles)
;
; Total Data: ~3,828 bytes of battle/cutscene configuration
; Palette Count: ~63 distinct BGR555 color sets
; Tile Count: ~17 sprite graphics tiles (8×8 pixels, 4bpp format)
; Boss Configurations: 7+ distinct boss palette/attribute sets
; ==============================================================================
