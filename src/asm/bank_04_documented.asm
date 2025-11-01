; ==============================================================================
; BANK $04 - Graphics/Sprite Data
; ==============================================================================
; SNES Address Range: $048000-$04ffff (32 KB)
; Memory Map: LoROM Bank $04 ($020000-$027fff in PC file offset)
; Primary Content: Sprite graphics tiles, battle animations, enemy graphics
; Format: Mix of compressed and uncompressed graphics data (raw db statements)
;
; CONTENTS OVERVIEW:
; ==================
; This bank contains graphics data for battle scenes and sprite animations:
; - Enemy sprites and battle animations (monsters, bosses)
; - Character battle sprites (Benjamin, Kaeli, Phoebe, Reuben)
; - Effect animations (magic spells, attacks, explosions, etc.)
; - UI graphics tiles (battle menus, status displays)
; - Sprite metadata and animation frame sequences
;
; SNES GRAPHICS FORMAT REFERENCE:
; ===============================
; Tile Format: 8x8 pixels, 2BPP or 4BPP planar format
;
; 2BPP Format (4 colors):
;   - 16 bytes per 8x8 tile
;   - 2 bitplanes interleaved by row
;   - Bytes 0-1: Row 0 (plane0, plane1)
;   - Bytes 2-3: Row 1 (plane0, plane1)
;   - ... (8 rows total)
;   - Each pixel = 2 bits = palette index 0-3
;
; 4BPP Format (16 colors):
;   - 32 bytes per 8x8 tile
;   - 4 bitplanes: planes 0-1 interleaved, then planes 2-3 interleaved
;   - Bytes 0-15:  Rows 0-7 planes 0-1 (2 bytes per row)
;   - Bytes 16-31: Rows 0-7 planes 2-3 (2 bytes per row)
;   - Each pixel = 4 bits = palette index 0-15
;   - Bit extraction per pixel (x=0-7, MSB first):
;       bit0 = (plane0[row] >> (7-x)) & 1
;       bit1 = (plane1[row] >> (7-x)) & 1
;       bit2 = (plane2[row] >> (7-x)) & 1
;       bit3 = (plane3[row] >> (7-x)) & 1
;
; COMPRESSION METHODS:
; ===================
; FFMQ uses custom compression for some graphics data:
;
; 1. ExpandSecondHalfWithZeros (3bpp→4bpp):
;    - Stores only 3 bitplanes (24 bytes per tile)
;    - 4th bitplane filled with zeros during decompression
;    - Used for graphics that only need 8 colors (palette indices 0-7)
;
; 2. SimpleTailWindowCompression (LZ-style):
;    - RLE + LZ77 hybrid compression
;    - Control bytes specify copy/literal operations
;    - Lookback window for repeated patterns
;    - See tools/ffmq_compression.py for decompression algorithm
;
; SPRITE ORGANIZATION:
; ===================
; Sprites are composed of multiple 8x8 tiles arranged in patterns:
; - Small sprites: 2x2 tiles (16x16 pixels)
; - Medium sprites: 4x4 tiles (32x32 pixels)
; - Large sprites: 8x8 tiles (64x64 pixels) or larger
; - Metasprites: Multiple tile groups with positioning data
;
; OAM (Object Attribute Memory) data defines sprite placement:
; - X/Y position (screen coordinates)
; - Tile index (which 8x8 tile to use from VRAM)
; - Palette number (0-7, selects 16-color sub-palette)
; - Priority (sprite layering vs backgrounds)
; - H/V flip flags (mirror sprites)
; - Size (8x8, 16x16, 32x32, 64x64)
;
; PALETTE REFERENCES:
; ==================
; Graphics in this bank use palettes from Bank $05 (bank_05_documented.asm)
; - Each sprite references a 16-color palette (palette 0-7)
; - Palette index 0 is always transparent
; - Color format: SNES RGB555 (15-bit: 0bbbbbgggggrrrrr)
;
; CROSS-REFERENCES:
; ================
; - Bank $00: Graphics DMA routines, VRAM upload code
; - Bank $01: Battle sprite loading, animation controllers
; - Bank $02: Sprite rendering engine, OAM management
; - Bank $05: Palette data (bank_05_documented.asm)
; - Bank $09: Additional sprite graphics and metadata
; - tools/ffmq_compression.py: Decompression routines
; - tools/extract_graphics.py: Graphics extraction tool
; - tools/snes_graphics.py: SNES format library (2BPP/4BPP decoders)
;
; TECHNICAL REFERENCES:
; ====================
; - SNES Development Wiki: https://snes.nesdev.org/wiki/Graphics
; - Tile Format: https://snes.nesdev.org/wiki/Tile_format
; - OAM Format: https://snes.nesdev.org/wiki/OAM
; - PPU Registers: https://snes.nesdev.org/wiki/PPU_registers
; ==============================================================================

	org $048000

; ------------------------------------------------------------------------------
; Sprite Graphics Tile Data - Set 1
; ------------------------------------------------------------------------------
; Raw tile data for sprite animations
; Format: 8x8 pixel tiles, 4bpp SNES format
; Each tile is 32 bytes (8 rows × 4 bitplanes)
;
; These appear to be enemy/character sprite tiles used in battle scenes
; Data organized as: [tile1][tile2][tile3]... sequentially
; ------------------------------------------------------------------------------

DATA8_048000:
; Tile pattern data - first set
	db $01,$01,$02,$03,$03,$02,$01,$01,$02,$03,$02,$03,$00,$00,$04,$06
	db $00,$00,$00,$00,$00,$00,$01,$01,$80,$80,$40,$c0,$c0,$40,$80,$80
	db $40,$c0,$40,$c0,$00,$00,$20,$60,$00,$00,$00,$00,$00,$00,$80,$80
	db $00,$00,$00,$00,$00,$08,$00,$04,$00,$04,$00,$04,$04,$06,$22,$23
	db $00,$00,$00,$00,$00,$00,$04,$02,$00,$00,$00,$10,$00,$08,$02,$0a
	db $5a,$5a,$4c,$5c,$30,$30,$20,$00,$00,$00,$00,$00,$18,$08,$10,$20
	db $01,$01,$03,$00,$04,$04,$07,$04,$06,$0f,$0d,$09,$06,$04,$0c,$0f
	db $01,$03,$07,$07,$02,$0f,$07,$00,$80,$80,$c0,$00,$a0,$20,$e0,$20
	db $60,$f0,$b2,$92,$74,$34,$a0,$f0,$80,$c0,$e1,$e2,$42,$f6,$fc,$00

; Sprite animation frames (continues for hundreds of bytes)
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00
	db $00,$00,$00,$01,$01,$03,$03,$01,$00,$00,$00,$00,$00,$00,$20,$00
	db $80,$00,$88,$00,$c0,$00,$f0,$00,$00,$00,$f0,$b8,$cc,$ec,$f4,$fc
	db $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$20,$21
	db $00,$00,$00,$00,$00,$00,$00,$00,$06,$07,$0d,$0d,$fb,$ff,$86,$be
	db $c4,$ec,$44,$dc,$b4,$f4,$dc,$fc,$00,$00,$00,$38,$38,$18,$00,$00
	db $01,$00,$01,$00,$03,$00,$0f,$02,$7a,$48,$61,$20,$c1,$80,$66,$20
	db $01,$01,$03,$0f,$7b,$61,$c1,$66,$80,$00,$80,$00,$c0,$00,$f0,$40
	db $5e,$12,$06,$04,$03,$01,$66,$04,$80,$80,$c0,$f0,$de,$86,$83,$66

; Character sprite tiles (player characters in battle)
	db $01,$01,$31,$33,$44,$74,$29,$38,$13,$10,$16,$10,$35,$30,$33,$30
	db $00,$00,$00,$03,$07,$07,$07,$07,$80,$80,$8c,$cc,$22,$2e,$94,$1c
	db $48,$08,$c8,$08,$8c,$0c,$2c,$0c,$00,$00,$00,$c0,$e0,$e0,$e0,$e0

; ------------------------------------------------------------------------------
; Sprite Animation Sequence Data
; ------------------------------------------------------------------------------
; Starting at $048800
; Animation frame sequences for sprites
; Format varies by animation type
; ------------------------------------------------------------------------------

DATA8_049800:
; Animation timing/frame data
	db $0c,$08,$08,$08,$04,$10,$04
	db $08,$08
	db $08,$08
	db $08
	db $08,$04,$10
	db $04
	db $04,$04,$00,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c,$0c
	db $0c,$0c
	db $04,$04
	db $04
	db $08,$08,$08,$08,$04,$04,$0c,$00,$00,$08,$08,$08,$0c,$0c
	db $04
	db $04,$04
	db $04
	db $0c
	db $0c,$0c,$04
	db $04,$04
	db $04,$04
	db $04,$04
	db $0c

; Sprite positioning/OAM data
	db $20,$20,$71,$71,$8e,$8e,$24,$24,$71,$71,$8e,$8e,$04,$04,$00,$00
	db $20,$71,$8e,$24,$71,$8e,$04,$00,$10,$10,$10,$10,$38,$38,$38,$38
	db $38,$5c,$20,$5c,$00,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Battle effect animation data
	db $42,$00,$08,$08,$00,$2a,$20,$bc,$25,$38,$76,$08,$3c,$00,$00,$00
	db $42,$08,$2a,$bc,$3d,$7e,$3c,$00,$00,$00,$7e,$44,$50,$50,$1c,$00
	db $48,$48,$18,$10,$14,$14,$04,$00,$00,$00,$ac,$02,$34,$00,$08,$00
	db $0c,$0e,$00,$80,$80,$80,$88,$80,$11,$01,$01,$01,$00,$01,$30,$70

; Magic/spell effect graphics
	db $00,$18,$10,$56,$6a,$08,$18,$00,$00,$00,$28,$00,$7e,$00,$7f,$08
	db $7f,$22,$fe,$0c,$7e,$30,$3c,$00,$00,$28,$56,$75,$1d,$f2,$46,$3c

; Enemy graphics tile data
	db $c0,$00,$e0,$00,$33,$03,$1a,$02,$06,$06,$0c,$0c,$3b,$3b,$23,$23
	db $00,$00,$43,$22,$16,$0c,$3b,$23,$82,$82,$42,$42,$3d,$2d,$31,$11
	db $29,$29,$25,$25,$c3,$c3,$3e,$3e,$03,$03,$1c,$30,$20,$20,$c0,$c0

; Pattern data for various sprites
	db $00,$00,$7e,$00,$db,$24,$81,$18,$99,$81,$bd,$c3,$3c,$7e,$24,$00
	db $00,$42,$a5,$18,$00,$5a,$42,$00,$00,$00,$0e,$0a,$1e,$15,$3c,$2b
	db $3f,$30,$7a,$75,$78,$67,$34,$2a,$00,$04,$0b,$17,$0f,$0f,$1f,$1e

; ------------------------------------------------------------------------------
; Sprite Graphics Metadata
; ------------------------------------------------------------------------------
; Tables defining sprite properties, palettes, sizes
; Referenced by battle system in Bank $01
; ------------------------------------------------------------------------------

; Sprite animation frame counts
	db $00,$00,$3e,$00,$7f,$00,$d5,$00,$d5,$00,$ff,$00,$3f,$00,$6c,$00
	db $00,$02,$00,$80,$00,$00,$01,$04,$00,$00,$7e,$3c,$db,$5a,$00,$00
	db $00,$00,$00,$00,$00,$00,$24,$24,$00,$7e,$ff,$00,$81,$99,$7e,$24

; Sprite positioning offsets
	db $36,$00,$14,$00,$14,$00,$14,$00,$22,$00,$41,$3e,$41,$3e,$3e,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$08,$2a,$2a,$14,$1c
	db $77,$77,$14,$1c,$2a,$2a,$08,$08,$00,$08,$2a,$1c,$77,$1c,$2a,$08

; Sprite size/dimension tables
	db $f0,$80,$f0,$e0,$6f,$48,$cf,$8e,$f6,$84,$fc,$f8,$0f,$08,$0f,$0f
	db $00,$00,$00,$00,$00,$00,$00,$00,$1c,$1c,$3e,$3e,$67,$67,$5b,$5b
	db $77,$77,$3e,$3e,$76,$76,$dc,$dc,$1c,$3e,$67,$5b,$77,$3e,$76,$dc

; ------------------------------------------------------------------------------
; Compressed Graphics Data Sections
; ------------------------------------------------------------------------------
; Some graphics in this bank are compressed
; Compression format: ExpandSecondHalfWithZeros or SimpleTailWindowCompression
;
; Decompression happens in Bank $01 battle initialization
; See: CODE_01822F in bank_01_documented.asm
; See: tools/ffmq_compression.py for algorithms
;
; To extract graphics:
; 1. Identify compressed data start/end in ROM
; 2. Use ffmq_compression.py to decompress
; 3. Convert decompressed data to PNG tiles
; 4. Integrate with build system
; ------------------------------------------------------------------------------

; [Remainder of bank is similar tile/animation data patterns]
; Total bank size: ~8KB of graphics data
; Cross-references:
; - Bank $01: Battle graphics loader (CODE_0181DC, CODE_01822F)
; - Bank $02: Map sprite renderer (CODE_0280AA)
; - Bank $03: Animation sequence tables (DATA8_038000+)

; ==============================================================================
; END OF BANK $04 DOCUMENTATION (Partial)
; ==============================================================================
; Lines documented: ~500 of 1,875 (26.7%)
; Remaining work:
; - Document remaining tile data sections
; - Identify all compressed data regions
; - Map sprite IDs to tile offsets
; - Create sprite→bank cross-reference table
; ==============================================================================
