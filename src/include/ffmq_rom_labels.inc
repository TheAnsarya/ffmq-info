; ===============================================
; FFMQ ROM Labels
; ===============================================
; ROM data tables, subroutines, and constants
; Related: Issue #30, labels/rom_data_tables.csv
; ===============================================

; ===============================================
; Graphics System Routines
; ===============================================

.define GraphicsDecompression       $FC8E    ; Decompress graphics data (8 uses)
.define SpriteUpdate                $AB5C    ; Update sprite positions/attributes (6 uses)
.define VRAMTransfer                $FD50    ; Transfer data to VRAM (6 uses)
.define TileDataTable               $F280    ; Tile data lookup table (4 uses)
.define LoadTilemap                 $81DB    ; Load tilemap data
.define RenderTiles                 $8672    ; Render tiles to buffer
.define ProcessSprites              $84E0    ; Process sprite data
.define UpdateAnimation             $8B75    ; Update animation frames
.define SetAnimationState           $8B82    ; Set animation state

; ===============================================
; System & DMA Routines
; ===============================================

.define InitGraphicsEngine          $8E06    ; Initialize graphics system
.define SetupDMA                    $82CF    ; Configure DMA transfer

; ===============================================
; Menu & Battle Graphics
; ===============================================

.define MenuGraphics                $94CC    ; Menu rendering routines
.define BattleGraphics              $9FAE    ; Battle scene rendering

; ===============================================
; Data Loading Routines
; ===============================================

.define LoadEnemySprite             $A08A    ; Load enemy sprite graphics
.define LoadCharacterSprite         $A403    ; Load character sprite

; ===============================================
; Lookup Tables
; ===============================================

.define PaletteDataLo               $839E    ; Palette data (low byte)
.define PaletteDataHi               $839F    ; Palette data (high byte)
.define OffsetTableLo               $88C4    ; Offset table (low byte)
.define OffsetTableHi               $88C5    ; Offset table (high byte)

; ===============================================
; End of ROM Labels
; ===============================================
