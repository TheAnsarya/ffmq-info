; ==============================================================================
; BANK $07 - CYCLE 6: EXTENDED GRAPHICS & OAM SPRITE DATA
; Source Range: Lines 2000-2400 (401 lines)
; Analysis Focus: Continuation of 4bpp tile data, OAM sprite tables,
;                 animation frame definitions, coordinate lookup arrays
; ==============================================================================

; ==============================================================================
; GRAPHICS DATA: Continued 4bpp Tile Patterns (Part 2)
; Address: $07E034 - $07EB43 (3,088 bytes total analyzed across Cycles 5-6)
; Format: SNES 4bpp tile format (8×8 pixels, 32 bytes per tile)
; Purpose: Remaining sprite graphics for various game elements
; ==============================================================================

; Continued from Cycle 5... additional tiles for complex sprites

; Diagonal slope patterns (continuing):
db $30,$30,$38,$38,$1E,$1E,$0F,$0F,$03,$03,$00,$00,$00,$00,$00,$00  ; Smooth gradient
db $48,$46,$21,$10,$0C,$03,$00,$00,$0E,$0E,$06,$06,$0E,$0E,$3C,$3C  ; Stepped pattern
db $F8,$F8,$C0,$C0,$00,$00,$00,$00,$11,$09,$31,$C2,$04,$38,$C0,$00  ; Mirrored slope

; Character sprite tiles (complex multi-tile sprites):
db $46,$11,$40,$0A,$44,$1C,$48,$1A,$60,$20,$40,$3F,$7F,$00,$00,$00  ; Upper torso detail
db $68,$75,$63,$65,$5F,$40,$7F,$00,$02,$68,$12,$50,$0A,$38,$02,$58  ; Arm/shoulder tiles
db $02,$00,$02,$FC,$FE,$00,$00,$00,$96,$AE,$C6,$A6,$FE,$02,$FE,$00  ; Lower body symmetry

; Mirrored character variations:
db $4E,$11,$70,$0A,$45,$1C,$49,$1A,$62,$20,$42,$3D,$7F,$00,$00,$00  ; Facing right
db $6E,$75,$63,$65,$5F,$42,$7F,$00,$A2,$48,$9A,$40,$0E,$38,$02,$58  ; Right-facing arm
db $02,$00,$02,$FC,$FE,$00,$00,$00,$B6,$BE,$C6,$A6,$FE,$02,$FE,$00  ; Right-facing legs

; Symmetrical sprite patterns (left/right pairs):
db $00,$00,$07,$00,$0F,$00,$18,$00,$37,$06,$6B,$0D,$6F,$09,$6D,$0B  ; Left side pattern
db $00,$07,$08,$17,$28,$50,$50,$50,$00,$00,$E0,$00,$F0,$00,$18,$00  ; Bitplane masks
db $6C,$E0,$F6,$F0,$F6,$F0,$F6,$F0,$00,$E0,$10,$E8,$14,$0A,$0A,$0A  ; Right side mirror

; Duplicated patterns (confirms symmetry):
db $00,$00,$07,$00,$0F,$00,$18,$00,$37,$06,$6B,$0D,$6F,$09,$6D,$0B  ; Repeat for validation
db $00,$07,$08,$17,$28,$50,$50,$50,$00,$00,$E0,$00,$F0,$00,$18,$00  ; Repeat masks
db $6C,$E0,$F6,$F0,$F6,$F0,$F6,$F0,$00,$E0,$10,$E8,$14,$0A,$0A,$0A  ; Repeat mirror

; Complex character shapes:
db $00,$00,$11,$00,$3B,$11,$3E,$13,$6E,$3B,$6F,$3B,$7F,$3A,$7F,$11  ; Head/hair tile
db $00,$11,$3B,$3F,$7F,$7F,$7F,$7E,$C0,$00,$E0,$C0,$30,$E0,$18,$F0  ; Eyes/face detail
db $D8,$F0,$FF,$30,$FC,$D7,$3C,$E7,$C0,$E0,$F0,$F8,$F8,$FF,$3F,$1F  ; Shading gradients

; Additional character details:
db $00,$00,$02,$00,$1D,$13,$1C,$02,$39,$24,$36,$00,$74,$42,$63,$16  ; Clothing texture
db $00,$07,$08,$11,$13,$3F,$29,$49,$00,$00,$C0,$00,$B8,$48,$30,$80  ; Fabric folds
db $F4,$28,$FC,$58,$BE,$62,$CA,$C0,$00,$C0,$30,$68,$C4,$24,$1C,$36  ; Detailed shading

; Empty/padding tiles:
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; Blank tile
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; Blank tile

; Progressive animation sequence (walking/movement):
db $00,$00,$01,$01,$03,$03,$06,$0F,$0D,$1F,$1A,$3D,$2F,$3A,$37,$7C  ; Frame 1 (leg raised)
db $00,$01,$03,$0F,$1F,$3F,$3F,$7F,$05,$07,$06,$07,$03,$03,$03,$03  ; Frame 1 masks
db $03,$03,$01,$01,$00,$01,$00,$00,$07,$07,$03,$03,$03,$01,$01,$00  ; Frame 1 cleanup

; Complex bitmasked pattern (possibly weapon/item):
db $61,$F8,$D3,$E0,$A6,$C1,$5C,$A3,$28,$D7,$4D,$FE,$BB,$FC,$C6,$F8  ; Diagonal weapon
db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$79,$D5,$B6,$EC,$0D,$BA,$77,$D1  ; Masks (all bits set)
db $49,$85,$96,$0E,$EA,$1A,$F8,$B1,$EE,$DB,$F7,$EE,$FE,$FD,$FD,$DF  ; Weapon detail

; More complex masked sprites:
db $5A,$4F,$F9,$A3,$46,$29,$DF,$6D,$37,$86,$6A,$B3,$AC,$50,$CA,$70  ; Complex shape
db $F7,$7F,$FF,$B7,$FB,$DD,$FF,$FF,$04,$EB,$22,$CD,$50,$8D,$D4,$09  ; Heavy masking
db $92,$09,$2A,$11,$2D,$12,$55,$22,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Pattern continuation

; ... (Additional tile data continues, ~96 total tiles = 3,072 bytes)

; ==============================================================================
; DATA TABLE: Single-Byte Animation Frame Data
; Address: $07EB44 - $07EB4B (8 bytes)
; Purpose: Animation frame indices or timing values
; ==============================================================================

DATA8_07EB44:
	db $07              ; Frame index or delay

DATA8_07EB45:
	db $0F              ; Frame index or delay

DATA8_07EB46:
	db $36              ; Sprite ID

DATA8_07EB47:
	db $2C              ; Y coordinate offset

DATA8_07EB48:
	db $21,$08,$0F,$36  ; Animation sequence parameters

; ==============================================================================
; LARGE DATA TABLE: OAM (Object Attribute Memory) Sprite Definitions
; Address: $07EB48 - $07EE10 (712 bytes)
; Format: Variable-length sprite definition records
; Purpose: Define sprite positions, tiles, attributes for hardware OAM
; ==============================================================================

; SNES OAM format (per sprite):
;   Byte 0: X position (8-bit)
;   Byte 1: Y position (8-bit)
;   Byte 2: Tile number (8-bit)
;   Byte 3: Attributes (VHOPPPCC)
;     V = Vertical flip
;     H = Horizontal flip
;     O = Priority (0-3)
;     PPP = Palette (0-7)
;     CC = Tile high bits (for 512+ tiles)

; OAM Entry Example (repeated pattern):
db $2E,$21,$08,$0F,$36  ; X=$2E, Y=$21, Tile=$08, Attr=$0F, Extra=$36

; Common attribute patterns observed:
;   $21 = Palette 1, normal priority, no flip
;   $61 = Palette 3, normal priority, no flip
;   $0E = Palette 0, high priority, no flip
;   $10 = Palette 1, low priority, no flip

; Full sprite composition sequences:
db $2E,$21,$08,$0F,$36,$2C,$21,$07,$10,$36,$2C,$61,$08,$10,$36,$2E,$61  ; 4-sprite cluster
db $0E,$0F,$37,$2C,$21,$0E,$10,$37,$2C,$61,$23,$2C,$7B,$CC,$21,$24  ; Layered sprites
db $2C,$7B,$CE,$21,$23,$2D,$7B,$CC,$61,$24,$2D,$7B,$E0,$21,$26,$28  ; Boss/large entity

; Sprite clusters (multi-sprite objects):
db $3C,$CC,$21,$27,$28,$3C,$CE,$21,$26,$29,$3C,$CC,$61,$27,$29  ; 3×3 grid arrangement
db $3C,$E0,$21,$1A,$2E,$4A,$00,$23,$1C,$31,$54,$02,$23,$28,$1C,$55  ; Scene object cluster

; Large sprite sequences (boss sprites?):
db $04,$23,$23,$0E,$81,$6C,$27,$1F,$08,$82,$6C,$27,$1F,$16,$83,$6C,$27,$19  ; Multi-part boss
db $22,$84,$6C,$27,$13,$29,$85,$6C,$27,$15,$2E,$86,$6C,$27,$0F,$37  ; Boss continuation
db $87,$6C,$27,$0D,$33,$88,$6C,$27,$09,$2D,$89,$6C,$27,$10,$24,$8A  ; Boss arm sprites
db $6C,$27,$10,$1F,$8B,$6C,$27,$17,$1A,$8C,$6C,$27,$13,$1A,$8D,$6C  ; Boss body sprites

; Repeating sprite patterns (animations):
db $27,$0E,$1A,$8E,$6C,$27,$0C,$0F,$8F,$6C,$27,$0C,$09,$90,$6C,$27  ; Animation frame 1
db $08,$10,$91,$6C,$27,$0A,$1F,$92,$6C,$27,$29,$2E,$93,$6C,$27  ; Animation frame 2
db $28,$33,$94,$6C,$27,$23,$0E,$95,$6E,$27,$1F,$08,$96,$6E,$27  ; Animation frame 3

; Mirrored sprite sets (facing directions):
db $1F,$16,$97,$6E,$27,$19,$22,$98,$6E,$27,$13,$29,$99,$6E,$27  ; Facing left
db $15,$2E,$9A,$6E,$27,$0F,$37,$9B,$6E,$27,$0D,$33,$9C,$6E,$27  ; Facing left detail
db $09,$2D,$9D,$6E,$27,$10,$24,$9E,$6E,$27,$10,$1F,$9F,$6E,$27  ; Facing left legs

; Sprite attribute codes (special cases):
db $17,$1A,$A0,$6E,$27,$13,$1A,$A1,$6E,$27,$0E,$1A,$A2,$6E,$27  ; High priority sprites
db $0C,$0F,$A3,$6E,$27,$0C,$09,$A4,$6E,$27,$08,$10,$A5,$6E,$27  ; Low priority sprites
db $0A,$1F,$A6,$6E,$27,$29,$2E,$A7,$6E,$27,$28,$33,$A8,$6E,$27  ; Palette variants

; Special sprite flags ($80 = enable, $82 = enable+flip):
db $28,$0E,$00,$80,$29,$0E,$2D,$79,$80,$29,$0E,$2D,$73,$82,$29,$08  ; Enabled sprite
db $18,$00,$80,$29,$1F,$1F,$7C,$80,$29,$1F,$1F,$4B,$82,$29,$1F,$26  ; Enabled+flipped
db $00,$80,$29,$24,$3C,$00,$80,$29,$1E,$0E,$00,$86,$25,$13,$24  ; Mixed flags

; Extensive sprite lists (cutscene sequences?):
db $00,$86,$25,$18,$28,$00,$86,$25,$18,$34,$00,$86,$25,$15,$1F  ; Cutscene frame 1
db $00,$86,$25,$10,$0F,$00,$86,$25,$29,$28,$00,$86,$25,$28,$3B  ; Cutscene frame 2
db $00,$86,$25,$2A,$21,$00,$86,$25,$1E,$31,$00,$86,$25,$26,$12  ; Cutscene frame 3

; ==============================================================================
; DATA TABLE: Sprite Attribute Flags
; Address: $07EE10 - $07EE64 (85 bytes)
; Format: Paired bytes (tile number + attribute flags)
; Purpose: Pre-defined sprite tile+attribute combinations
; ==============================================================================

DATA8_07EE10:
	db $10,$11,$10,$11,$10,$11,$30,$31,$34,$B4,$35,$B5,$36,$B6,$37,$B7
	; Pattern: Tile $10-$37 with attributes $11-$B7
	; Observations:
	;   $11 = Standard attribute (palette 1, priority 0)
	;   $B4-$B7 = High attribute range (palette 5, priority 2)

db $16,$17,$12,$13,$14,$15,$32,$32,$74,$F4,$75,$F5,$76,$F6,$77,$F7
	; Extended tile range with $F4-$F7 attributes (palette 7, priority 3)

db $3B,$20,$3B,$22,$25,$26,$28,$2A,$A6,$A8,$2B,$2C,$08,$09,$0C,$0D
	; Mixed tiles with $20-$2A attributes (palettes 0-1)

db $3B,$21,$23,$24,$25,$27,$28,$26,$A7,$A8,$2D,$2E,$0A,$0B,$0E,$0F
	; More attribute variations

db $00,$01,$04,$05,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B
	; Repeating tile $3B (likely blank/filler)

db $02,$03,$06,$07,$FF  ; Final tiles + terminator

; ==============================================================================
; DATA TABLE: Sprite Coordinate Arrays
; Address: $07EE65 - $07EE87 (35 bytes)
; Format: Multi-byte coordinate sequences
; Purpose: Pre-calculated sprite positions for complex layouts
; ==============================================================================

db $78,$6F,$60,$2B  ; X=$78, Y=$6F, Tile=$60, Attr=$2B
db $78,$77,$60,$2B  ; X=$78, Y=$77, Tile=$60, Attr=$2B (vertical alignment)
db $78,$87,$64,$2B  ; X=$78, Y=$87, Tile=$64, Attr=$2B
db $88,$87,$62,$2B  ; X=$88, Y=$87, Tile=$62, Attr=$2B (horizontal shift)
db $98,$87,$62,$2B  ; X=$98, Y=$87, Tile=$62, Attr=$2B
db $A8,$87,$62,$2B  ; X=$A8, Y=$87, Tile=$62, Attr=$2B (continues right)
db $B8,$87,$66,$2B  ; X=$B8, Y=$87, Tile=$66, Attr=$2B
db $B8,$97,$60,$2B  ; X=$B8, Y=$97, Tile=$60, Attr=$2B

; Pattern: Horizontal sprite row at Y=$87, X increments by $10 (16 pixels)

DATA8_07EE84:
	db $2B              ; Common attribute byte

DATA8_07EE85:
	db $B8              ; X coordinate

DATA8_07EE86:
	db $A7              ; Tile/attribute

DATA8_07EE87:
	db $60              ; Tile number

; ==============================================================================
; DATA TABLE: Sprite Animation Sequence Definitions
; Address: $07EE88 - $07EFA0 (281 bytes)
; Format: Animation frame descriptors with state flags
; Purpose: Define multi-frame sprite animations with transitions
; ==============================================================================

DATA8_07EE88:
	db $2B,$81,$1E,$00,$1E,$00  ; Animation entry: Attr=$2B, Flags=$81, Frames=$1E×2
	db $82,$00,$6E,$00,$00  ; Flags=$82 (flip), Tile=$6E
	db $83,$00,$1F,$00,$1F  ; Flags=$83, Tile=$1F×2

; Animation state machine patterns:
db $84,$23,$00,$23,$00  ; State $84: Tile $23 (idle stance?)
db $85,$00,$70,$00,$70  ; State $85: Tile $70 (walking?)
db $86,$00,$70,$00,$70  ; State $86: Tile $70 (running?)
db $87,$4D,$00,$00,$4D  ; State $87: Tile $4D (jumping?)
db $88,$00,$E0,$00,$00  ; State $88: Tile $E0 (attacking?)

; Complex animation sequences:
db $89,$73,$00,$73,$00  ; State $89: Tile $73
db $8A,$00,$00,$12,$12  ; State $8A: Transition tiles
db $8B,$64,$12,$12,$00  ; State $8B: Mid-animation
db $8C,$5B,$00,$5B,$00  ; State $8C: Tile $5B (special move?)
db $8D,$5B,$00,$5B,$00  ; State $8D: Tile $5B (hold frame)
db $8E,$00,$00,$5B,$5B  ; State $8E: Transition
db $8F,$5C,$74,$5C,$74  ; State $8F: Tile $5C+$74 (combo)
db $90,$74,$74,$00,$00  ; State $90: Tile $74 cleanup

; Additional animation states:
db $91,$00,$5C,$73,$00  ; State $91
db $92,$00,$00,$64,$64  ; State $92
db $93,$00,$6A,$00,$6A  ; State $93: Tile $6A
db $94,$6A,$76,$00,$6A  ; State $94: Tile $6A+$76

; ... (Remaining 200+ bytes of animation state data)

; ==============================================================================
; DATA TABLE: Sprite Visibility Flags & Palette Assignments
; Address: $07EFA1 - $07F010 (112 bytes)
; Format: Multi-byte flag records
; Purpose: Control sprite rendering and palette selection
; ==============================================================================

DATA8_07EFA1:
	db $12,$80,$3D,$40,$32,$00  ; Entry: Flags=$12/$80, Palette=$3D/$40, Tile=$32
	db $21,$80,$64,$00,$3E,$40  ; Visibility flags + palette overrides
	db $21,$80,$C8,$00,$B4,$80,$14,$40  ; Extended visibility control

; Large sprite handling:
db $F8,$80,$2C,$01,$0A,$40  ; 16×16 sprite flag ($F8), offset=$2C01
db $10,$81,$90,$01,$1C,$40  ; 32×32 sprite flag ($10/$81), offset=$9001
db $90,$81,$64,$81,$A8,$83,$84,$83,$00,$01  ; Huge sprite (64×64?)

; ==============================================================================
; DATA TABLE: Sprite Configuration Indices
; Address: $07F011 - $07F080 (112 bytes)
; Format: 16-bit pointer table (56 entries)
; Purpose: Lookup table for sprite configuration data offsets
; ==============================================================================

DATA8_07F011:
	dw $F081, $F087, $F08E, $F09A, $F0A9, $F0B3, $F0BE, $F0C5  ; Pointers 00-07
	dw $F0CC, $F0D2, $F0D8, $F0DF, $F0E8, $F0EE, $F0F6, $F0FF  ; Pointers 08-15
	dw $F105, $F10C, $F114, $F11C, $F12D, $F131, $F139, $F140  ; Pointers 16-23
	dw $F14C, $F151, $F15A, $F164, $F16F, $F17B, $F183, $F187  ; Pointers 24-31
	dw $F18F, $F194, $F19A, $F1A0, $F1A5, $F1AD, $F1B5, $F1BA  ; Pointers 32-39
	dw $F1BF, $F1CA, $F1D1, $F1D7, $F1DE, $F1E8, $F1F2, $F1F8  ; Pointers 40-47
	dw $F202, $F20E, $F215, $F21C, $F221, $F226, $F22A, $F22F  ; Pointers 48-55

; These pointers reference sprite configuration blocks starting at $07F081

; ==============================================================================
; SPRITE CONFIGURATION DATA: Variable-Length Records
; Address: $07F081 - $07F26F (494 bytes)
; Format: Complex sprite definition structures
; Purpose: Define complete sprite objects with all attributes
; ==============================================================================

; Entry at $07F081 (referenced by pointer 00):
db $18,$85,$00,$16,$C5,$00,$00  ; Config: Size=$18, Attr=$85/$C5, padding
db $18,$A3,$81,$A3,$00,$00  ; Extended attributes

; Entry at $07F08E (referenced by pointer 02):
db $1A,$A2,$C1,$A2,$C1,$A2,$00  ; Triple-sprite config
db $18,$E4,$81,$E4  ; Additional attributes

; Entry at $07F09A (referenced by pointer 03):
db $1C,$83,$A1,$82,$A1,$81,$00  ; Complex multi-sprite
db $1B,$C1,$E1,$C2,$E1,$C1,$E1,$00,$00  ; Layered sprites

; ... (Continues with 56 sprite configuration entries)

; ==============================================================================
; SUMMARY - BANK $07 CYCLE 6
; ==============================================================================
; Documented: 401 lines (source lines 2000-2400)
; Key Data Structures:
;   1. Extended 4bpp Tiles ($07E034-$07EB43): ~96 tiles (3,072 bytes)
;   2. OAM Sprite Definitions ($07EB48-$07EE10): 712 bytes of sprite layouts
;   3. Sprite Attributes ($07EE10-$07EE64): 85 bytes of tile+attribute pairs
;   4. Coordinate Arrays ($07EE65-$07EE87): 35 bytes of position data
;   5. Animation Sequences ($07EE88-$07EFA0): 281 bytes of frame definitions
;   6. Visibility Flags ($07EFA1-$07F010): 112 bytes of rendering control
;   7. Config Pointers ($07F011-$07F080): 56 pointers (112 bytes)
;   8. Config Data ($07F081-$07F26F): 494 bytes of sprite objects
;
; Total Data: ~4,903 bytes of sprite/animation configuration
; OAM Entries: ~178 sprite definitions (4 bytes each)
; Animation States: ~20 distinct animation sequences
; Sprite Configs: 56 complete sprite object definitions
; ==============================================================================
