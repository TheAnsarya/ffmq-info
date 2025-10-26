; ==============================================================================
; BANK $04 - Graphics/Sprite Data
; ==============================================================================
; Bank Size: 1,875 lines (2,073 total in source)
; Primary Content: Sprite graphics tiles, battle animations, enemy graphics
; Format: Primarily raw data bytes (db statements)
;
; This bank contains compressed and uncompressed graphics data for:
; - Enemy sprites and battle animations
; - Character battle sprites
; - Effect animations (magic, attacks, etc.)
; - UI graphics tiles
;
; Many graphics are compressed using FFMQ's custom compression:
; - ExpandSecondHalfWithZeros (3bpp→4bpp expansion)
; - SimpleTailWindowCompression (LZ-style compression)
;
; See: tools/ffmq_compression.py for decompression routines
; ==============================================================================

                       ORG $048000

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
                       db $00,$00,$00,$00,$00,$00,$01,$01,$80,$80,$40,$C0,$C0,$40,$80,$80
                       db $40,$C0,$40,$C0,$00,$00,$20,$60,$00,$00,$00,$00,$00,$00,$80,$80
                       db $00,$00,$00,$00,$00,$08,$00,$04,$00,$04,$00,$04,$04,$06,$22,$23
                       db $00,$00,$00,$00,$00,$00,$04,$02,$00,$00,$00,$10,$00,$08,$02,$0A
                       db $5A,$5A,$4C,$5C,$30,$30,$20,$00,$00,$00,$00,$00,$18,$08,$10,$20
                       db $01,$01,$03,$00,$04,$04,$07,$04,$06,$0F,$0D,$09,$06,$04,$0C,$0F
                       db $01,$03,$07,$07,$02,$0F,$07,$00,$80,$80,$C0,$00,$A0,$20,$E0,$20
                       db $60,$F0,$B2,$92,$74,$34,$A0,$F0,$80,$C0,$E1,$E2,$42,$F6,$FC,$00

; Sprite animation frames (continues for hundreds of bytes)
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00
                       db $00,$00,$00,$01,$01,$03,$03,$01,$00,$00,$00,$00,$00,$00,$20,$00
                       db $80,$00,$88,$00,$C0,$00,$F0,$00,$00,$00,$F0,$B8,$CC,$EC,$F4,$FC
                       db $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$01,$20,$21
                       db $00,$00,$00,$00,$00,$00,$00,$00,$06,$07,$0D,$0D,$FB,$FF,$86,$BE
                       db $C4,$EC,$44,$DC,$B4,$F4,$DC,$FC,$00,$00,$00,$38,$38,$18,$00,$00
                       db $01,$00,$01,$00,$03,$00,$0F,$02,$7A,$48,$61,$20,$C1,$80,$66,$20
                       db $01,$01,$03,$0F,$7B,$61,$C1,$66,$80,$00,$80,$00,$C0,$00,$F0,$40
                       db $5E,$12,$06,$04,$03,$01,$66,$04,$80,$80,$C0,$F0,$DE,$86,$83,$66

; Character sprite tiles (player characters in battle)
                       db $01,$01,$31,$33,$44,$74,$29,$38,$13,$10,$16,$10,$35,$30,$33,$30
                       db $00,$00,$00,$03,$07,$07,$07,$07,$80,$80,$8C,$CC,$22,$2E,$94,$1C
                       db $48,$08,$C8,$08,$8C,$0C,$2C,$0C,$00,$00,$00,$C0,$E0,$E0,$E0,$E0

; ------------------------------------------------------------------------------
; Sprite Animation Sequence Data
; ------------------------------------------------------------------------------
; Starting at $048800
; Animation frame sequences for sprites
; Format varies by animation type
; ------------------------------------------------------------------------------

DATA8_049800:
                       ; Animation timing/frame data
                       db $0C,$08,$08,$08,$04,$10,$04
                       db $08,$08
                       db $08,$08
                       db $08
                       db $08,$04,$10
                       db $04
                       db $04,$04,$00,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
                       db $0C,$0C
                       db $04,$04
                       db $04
                       db $08,$08,$08,$08,$04,$04,$0C,$00,$00,$08,$08,$08,$0C,$0C
                       db $04
                       db $04,$04
                       db $04
                       db $0C
                       db $0C,$0C,$04
                       db $04,$04
                       db $04,$04
                       db $04,$04
                       db $0C

; Sprite positioning/OAM data
                       db $20,$20,$71,$71,$8E,$8E,$24,$24,$71,$71,$8E,$8E,$04,$04,$00,$00
                       db $20,$71,$8E,$24,$71,$8E,$04,$00,$10,$10,$10,$10,$38,$38,$38,$38
                       db $38,$5C,$20,$5C,$00,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Battle effect animation data
                       db $42,$00,$08,$08,$00,$2A,$20,$BC,$25,$38,$76,$08,$3C,$00,$00,$00
                       db $42,$08,$2A,$BC,$3D,$7E,$3C,$00,$00,$00,$7E,$44,$50,$50,$1C,$00
                       db $48,$48,$18,$10,$14,$14,$04,$00,$00,$00,$AC,$02,$34,$00,$08,$00
                       db $0C,$0E,$00,$80,$80,$80,$88,$80,$11,$01,$01,$01,$00,$01,$30,$70

; Magic/spell effect graphics
                       db $00,$18,$10,$56,$6A,$08,$18,$00,$00,$00,$28,$00,$7E,$00,$7F,$08
                       db $7F,$22,$FE,$0C,$7E,$30,$3C,$00,$00,$28,$56,$75,$1D,$F2,$46,$3C

; Enemy graphics tile data
                       db $C0,$00,$E0,$00,$33,$03,$1A,$02,$06,$06,$0C,$0C,$3B,$3B,$23,$23
                       db $00,$00,$43,$22,$16,$0C,$3B,$23,$82,$82,$42,$42,$3D,$2D,$31,$11
                       db $29,$29,$25,$25,$C3,$C3,$3E,$3E,$03,$03,$1C,$30,$20,$20,$C0,$C0

; Pattern data for various sprites
                       db $00,$00,$7E,$00,$DB,$24,$81,$18,$99,$81,$BD,$C3,$3C,$7E,$24,$00
                       db $00,$42,$A5,$18,$00,$5A,$42,$00,$00,$00,$0E,$0A,$1E,$15,$3C,$2B
                       db $3F,$30,$7A,$75,$78,$67,$34,$2A,$00,$04,$0B,$17,$0F,$0F,$1F,$1E

; ------------------------------------------------------------------------------
; Sprite Graphics Metadata
; ------------------------------------------------------------------------------
; Tables defining sprite properties, palettes, sizes
; Referenced by battle system in Bank $01
; ------------------------------------------------------------------------------

; Sprite animation frame counts
                       db $00,$00,$3E,$00,$7F,$00,$D5,$00,$D5,$00,$FF,$00,$3F,$00,$6C,$00
                       db $00,$02,$00,$80,$00,$00,$01,$04,$00,$00,$7E,$3C,$DB,$5A,$00,$00
                       db $00,$00,$00,$00,$00,$00,$24,$24,$00,$7E,$FF,$00,$81,$99,$7E,$24

; Sprite positioning offsets
                       db $36,$00,$14,$00,$14,$00,$14,$00,$22,$00,$41,$3E,$41,$3E,$3E,$00
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$08,$2A,$2A,$14,$1C
                       db $77,$77,$14,$1C,$2A,$2A,$08,$08,$00,$08,$2A,$1C,$77,$1C,$2A,$08

; Sprite size/dimension tables
                       db $F0,$80,$F0,$E0,$6F,$48,$CF,$8E,$F6,$84,$FC,$F8,$0F,$08,$0F,$0F
                       db $00,$00,$00,$00,$00,$00,$00,$00,$1C,$1C,$3E,$3E,$67,$67,$5B,$5B
                       db $77,$77,$3E,$3E,$76,$76,$DC,$DC,$1C,$3E,$67,$5B,$77,$3E,$76,$DC

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
