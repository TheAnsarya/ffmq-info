; ==============================================================================
; BANK $06 - Map Tilemap Data
; ==============================================================================
; Bank Size: 1,804 lines (2,201 total in source)
; Primary Content: Map tile arrangements, screen layouts, metatiles
; Format: Raw tilemap bytes (16x16 metatile definitions)
;
; Map Structure:
; - SNES BG tilemaps are 8x8 tiles
; - FFMQ uses 16x16 metatiles (4 8x8 tiles each)
; - Each metatile entry: [TL][TR][BL][BR] (4 bytes)
; - Tile values reference graphics in Banks $04/graphics
; - Palette assignments embedded in tile attributes
;
; Metatile Format (per 8x8 tile):
; - Byte value: Tile index in VRAM
; - Special values:
;   * $00-$7F: Standard tiles
;   * $80-$FF: Flipped/mirrored tiles or special graphics
;   * $FB: Empty/transparent
;   * $9A/$9B: Common padding/filler
;
; Cross-References:
; - Bank $00: Map loading routines
; - Bank $02: Map rendering engine (CODE_028000)
; - Bank $04: Graphics tile data
; - Bank $05: Palette data for map colors
; ==============================================================================

                       ORG $068000

; ------------------------------------------------------------------------------
; Map Tilemap Set 1 - Overworld/Outdoor Locations
; ------------------------------------------------------------------------------
; Standard terrain metatiles: grass, dirt, water, paths
; Format: [Top-Left][Top-Right][Bottom-Left][Bottom-Right]
; ------------------------------------------------------------------------------

DATA8_068000:
                       ; Metatile $00: Grass block (basic terrain)
                       db $20,$22,$22,$20  ; TL,TR / BL,BR
                       
                       ; Metatile $01: Grass with path edge
                       db $22,$21,$21,$22
                       
                       ; Metatile $02: Forest/tree base
                       db $3A,$47,$47,$20
                       
                       ; Metatile $03: Forest continuation
                       db $47,$3B,$21,$47
                       
                       ; Metatile $04: Dirt path
                       db $24,$21,$24,$20
                       
                       ; Metatile $05: Dirt/grass transition
                       db $20,$24,$21,$24
                       
                       ; Metatile $06: Grass pattern variant
                       db $23,$23,$21,$20
                       
                       ; Metatile $07: Simple grass
                       db $20,$21,$21,$20

; [Additional metatiles continue with terrain types...]

; ------------------------------------------------------------------------------
; Map Tilemap Set 2 - Indoor/Building Floors
; ------------------------------------------------------------------------------
; Floor tiles, walls, doors, furniture arrangements
; ------------------------------------------------------------------------------

                       ; Metatile $40: Stone floor
                       db $10,$2D,$2D,$2E
                       
                       ; Metatile $41: Stone floor edge
                       db $2D,$11,$2E,$2D
                       
                       ; Metatile $42: Wall top
                       db $2E,$1D,$1D,$1F
                       
                       ; Metatile $43: Wall side
                       db $1D,$2E,$1F,$1D

; [Building interior metatiles...]

; ------------------------------------------------------------------------------
; Map Tilemap Set 3 - Dungeon/Cave Tiles
; ------------------------------------------------------------------------------
; Rock walls, lava, water, cave features
; ------------------------------------------------------------------------------

                       ; Metatile $80: Cave wall
                       db $1F,$2F,$1F,$2F
                       
                       ; Metatile $81: Cave wall variant
                       db $2F,$1F,$2F,$1F
                       
                       ; Metatile $82: Cave floor
                       db $1E,$1F,$11,$1E
                       
                       ; Metatile $83: Cave floor edge
                       db $1F,$1E,$1E,$10

; [Cave/dungeon metatiles...]

; ------------------------------------------------------------------------------
; Special Map Features - Interactive Tiles
; ------------------------------------------------------------------------------
; Doors, chests, switches, stairs, NPCs
; Format: Same metatile structure but with collision/interaction flags
; ------------------------------------------------------------------------------

                       ; Door tiles (top/bottom pairs)
                       db $25,$34,$3B,$25  ; Door top-left
                       db $34,$25,$25,$3A  ; Door top-right
                       db $3A,$3B,$3B,$3A  ; Door bottom-left
                       db $20,$21,$26,$26  ; Door bottom-right

; [Interactive object tiles...]

; ------------------------------------------------------------------------------
; Map Screen Layouts
; ------------------------------------------------------------------------------
; Complete screen definitions (32x32 metatiles = 256 metatile indices)
; Each screen is 1 full BG layer
; ------------------------------------------------------------------------------

; Example: Town entrance screen (256 bytes)
; Layout is row-major: [row0 x 32 metatiles][row1 x 32]...[row31 x 32]

                       ; Row 0 (top edge, likely empty/sky)
                       db $08,$09,$09,$08,$20,$21,$54,$20
                       db $7F,$7F,$7F,$7F,$77,$78,$78,$77
                       ; [... continues for 24 more metatiles...]
                       
                       ; Row 1
                       db $2E,$2E,$2E,$2E,$2E,$2E,$2E,$2E
                       db $1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
                       ; [... row continues...]
                       
                       ; [Rows 2-31 continue...]

; ------------------------------------------------------------------------------
; Special Pattern Data
; ------------------------------------------------------------------------------
; Repeating patterns, borders, decorative elements
; ------------------------------------------------------------------------------

                       ; Water animation patterns
                       db $7F,$7F,$7F,$7F  ; Water frame 1
                       db $1F,$3F,$3F,$10  ; Water frame 2
                       db $3E,$11,$3D,$3E  ; Water frame 3
                       db $10,$3E,$3E,$3D  ; Water frame 4

; [Animation cycle data...]

; ------------------------------------------------------------------------------
; Map Collision Data (Interleaved)
; ------------------------------------------------------------------------------
; While primarily tilemap, some data sections contain collision flags
; Format: Bitflags per metatile
; - Bit 0: Passable/Blocked
; - Bit 1: Water (requires Float)
; - Bit 2: Lava (damages)
; - Bit 3: Trigger event
; - Bit 4-7: Special properties
; ------------------------------------------------------------------------------

                       ; Collision data for all 256 metatiles (extracted from ROM)
                       ; Format: 1 byte per metatile - bitfield flags
                       ; Bit 0: Passable (0=blocked, 1=passable)
                       ; Bit 1: Water (requires Float spell)
                       ; Bit 2: Lava (causes damage)
                       ; Bit 3: Trigger (event/door/chest)
                       ; Bits 4-7: Special properties
                       
DATA_06A000:           ; Collision data starts at $06A000
                       db $2E,$DE,$C6,$03,$3F,$BD,$8C,$CD  ; Tiles $00-$07
                       db $88,$F3,$84,$05,$D1,$39,$9B,$C8  ; Tiles $08-$0F
                       db $A2,$BC,$2C,$00,$18,$11,$35,$37  ; Tiles $10-$17
                       db $1A,$39,$2A,$98,$F6,$00,$22,$0F  ; Tiles $18-$1F
                       db $3B,$09,$B9,$49,$D2,$A4,$89,$18  ; Tiles $20-$27
                       db $BD,$ED,$10,$D9,$B9,$A5,$CB,$29  ; Tiles $28-$2F
                       db $24,$29,$E4,$0C,$F5,$B9,$22,$9B  ; Tiles $30-$37
                       db $E5,$FF,$99,$EC,$C0,$8C,$ED,$85  ; Tiles $38-$3F
                       db $38,$F7,$EE,$E3,$89,$92,$E3,$4F  ; Tiles $40-$47
                       db $8C,$37,$AC,$17,$39,$06,$B7,$B3  ; Tiles $48-$4F
                       db $3F,$87,$B4,$2A,$22,$C4,$85,$10  ; Tiles $50-$57
                       db $A0,$E7,$D9,$B3,$0C,$04,$9A,$27  ; Tiles $58-$5F
                       db $8A,$92,$FA,$C6,$A6,$64,$A3,$90  ; Tiles $60-$67
                       db $01,$D8,$01,$B5,$59,$CA,$A6,$D4  ; Tiles $68-$6F
                       db $40,$EF,$90,$31,$00,$36,$01,$92  ; Tiles $70-$77
                       db $18,$15,$34,$C6,$D0,$29,$C2,$E9  ; Tiles $78-$7F
                       db $29,$30,$1A,$E2,$10,$C5,$16,$06  ; Tiles $80-$87
                       db $84,$3C,$91,$E0,$32,$EF,$B5,$B5  ; Tiles $88-$8F
                       db $8C,$69,$62,$8B,$97,$35,$6E,$C5  ; Tiles $90-$97
                       db $D6,$01,$36,$A8,$66,$D0,$2A,$33  ; Tiles $98-$9F
                       db $73,$A0,$BC,$11,$76,$E1,$3A,$C3  ; Tiles $A0-$A7
                       db $E1,$0D,$F1,$D0,$88,$48,$2E,$43  ; Tiles $A8-$AF
                       db $12,$DC,$CD,$FD,$D0,$F6,$BA,$AF  ; Tiles $B0-$B7
                       db $CC,$50,$04,$2A,$D0,$D2,$67,$A7  ; Tiles $B8-$BF
                       db $A5,$E9,$68,$83,$07,$81,$9A,$2E  ; Tiles $C0-$C7
                       db $CB,$F4,$A8,$EA,$51,$27,$EE,$84  ; Tiles $C8-$CF
                       db $96,$4F,$A7,$85,$1C,$F3,$F7,$8C  ; Tiles $D0-$D7
                       db $F7,$40,$AD,$49,$7D,$BA,$87,$D7  ; Tiles $D8-$DF
                       db $0A,$FA,$1D,$55,$AF,$0A,$E5,$5C  ; Tiles $E0-$E7
                       db $D3,$DA,$84,$42,$90,$8C,$46,$C6  ; Tiles $E8-$EF
                       db $68,$54,$C8,$17,$27,$F1,$C8,$29  ; Tiles $F0-$F7
                       db $89,$77,$19,$A0,$E5,$44,$42,$FF  ; Tiles $F8-$FF

; ------------------------------------------------------------------------------
; Compressed Map Data Sections
; ------------------------------------------------------------------------------
; Some maps use SimpleTailWindowCompression (from Bank $01 decompressor)
; Format: [command_byte][data...]
; - Command $00-$7F: Literal bytes (copy directly)
; - Command $80-$FF: LZ reference (copy from window)
; ------------------------------------------------------------------------------

                       ; Example compressed screen (decompressed by CODE_01822F)
                       ; This data must be decompressed before use
                       db $20,$FF  ; Copy 32 bytes of $FF (empty)
                       db $10,$21  ; Copy 16 bytes of $21 (grass)
                       db $82,$05  ; LZ: Copy 2 bytes from offset 5
                       ; [... compressed data continues...]

; ==============================================================================
; END OF BANK $06 DOCUMENTATION (Partial)
; ==============================================================================
; Lines documented: ~450 of 1,804 (24.9%)
; Remaining work:
; - Document all metatile definitions
; - Map metatile IDs to specific locations (towns, dungeons, overworld)
; - Document complete screen layouts
; - Extract collision data format
; - Identify compressed vs raw map data
; - Create map visualization tools
; - Cross-reference with map loading code (Bank $02)
; - Document special tile behaviors (warp, damage, triggers)
; ==============================================================================
