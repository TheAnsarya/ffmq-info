; ===============================================
; FFMQ ROM Labels
; ===============================================
; ROM data tables, subroutines, and constants
; Related: Issue #30, labels/rom_data_tables.csv
; ===============================================

; ===============================================
; Graphics System Routines
; ===============================================

.define GraphicsDecompression       $fc8e    ; Decompress graphics data (8 uses)
.define SpriteUpdate                $ab5c    ; Update sprite positions/attributes (6 uses)
.define VRAMTransfer                $fd50    ; Transfer data to VRAM (6 uses)
.define TileDataTable               $f280    ; Tile data lookup table (4 uses)
.define LoadTilemap                 $81db    ; Load tilemap data
.define RenderTiles                 $8672    ; Render tiles to buffer
.define ProcessSprites              $84e0    ; Process sprite data
.define UpdateAnimation             $8b75    ; Update animation frames
.define SetAnimationState           $8b82    ; Set animation state

; ===============================================
; System & DMA Routines
; ===============================================

.define InitGraphicsEngine          $8e06    ; Initialize graphics system
.define SetupDMA                    $82cf    ; Configure DMA transfer

; ===============================================
; Menu & Battle Graphics
; ===============================================

.define MenuGraphics                $94cc    ; Menu rendering routines
.define BattleGraphics              $9fae    ; Battle scene rendering

; ===============================================
; Data Loading Routines
; ===============================================

.define LoadEnemySprite             $a08a    ; Load enemy sprite graphics
.define LoadCharacterSprite         $a403    ; Load character sprite

; ===============================================
; Lookup Tables
; ===============================================

.define PaletteDataLo               $839e    ; Palette data (low byte)
.define PaletteDataHi               $839f    ; Palette data (high byte)
.define OffsetTableLo               $88c4    ; Offset table (low byte)
.define OffsetTableHi               $88c5    ; Offset table (high byte)

; ===============================================
; End of ROM Labels
; ===============================================
