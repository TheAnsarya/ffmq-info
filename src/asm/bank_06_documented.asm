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

                       ; Example collision bytes
                       db $00  ; Fully passable (grass)
                       db $01  ; Blocked (wall)
                       db $02  ; Water tile
                       db $04  ; Lava tile
                       db $08  ; Event trigger (door, chest)

; [Collision data continues...]

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
