; ============================================================================
; FFMQ Battle System Data Structures Analysis
; ============================================================================
; Analyzed from Diztinguish disassembly bank_09.asm
; Bank $09 ($098000-$09ffff) - Battle System and Enemy Data
;
; This file documents the battle system data structures discovered through
; analysis of bank_09 patterns and cross-referencing with gameplay.
; ============================================================================

; ============================================================================
; Enemy Palette Data
; ============================================================================
; Address: $098000-$098460
; Format: 16-byte palette entries (8 colors in RGB555 format)
; Each enemy has a custom color palette for sprite rendering
; ============================================================================

; Palette Entry Format (16 bytes per enemy):
; Offset  Size  Description
; +$00    2     Background color (RGB555) - usually $0000
; +$02    2     Color 1 (RGB555)
; +$04    2     Color 2 (RGB555)
; +$06    2     Color 3 (RGB555)
; +$08    2     Color 4 (RGB555)
; +$0a    2     Color 5 (RGB555)
; +$0c    2     Color 6 (RGB555)
; +$0e    2     Color 7 (RGB555)

EnemyPalette_00:	; $098000 - First enemy palette
	.bg:        dw $0000            ; Transparent/background
	.color1:    dw $737c            ; RGB(28,30,28) - Dark gray-green
	.color2:    dw $5275            ; RGB(21,26,20) - Medium gray-green
	.color3:    dw $356e            ; RGB(14,18,13) - Dark green
	.color4:    dw $20a9            ; RGB(09,10,08) - Very dark
	.color5:    dw $001f            ; RGB(00,00,31) - Pure blue
	.color6:    dw $31e5            ; RGB(05,15,12) - Cyan-green
	.color7:    dw $0000            ; Black

EnemyPalette_01:	; $098010 - Second enemy palette
	.bg:        dw $0000
	.color1:    dw $7fff            ; RGB(31,31,31) - Pure white
	.color2:    dw $17ff            ; RGB(31,31,02) - Bright yellow
	.color3:    dw $023f            ; RGB(31,01,00) - Bright red
	.color4:    dw $011f            ; RGB(31,00,00) - Red
	.color5:    dw $001a            ; RGB(26,00,00) - Dark red
	.color6:    dw $7dd0            ; RGB(16,29,31) - Cyan
	.color7:    dw $0000

; Pattern: Most palettes follow this structure
; - First word is usually $0000 (transparent) or $0058 (gray)
; - Second word often $7fff (white) for highlights
; - Colors 2-7 define the enemy's color scheme
; - Brightness/shading achieved through similar hues at different intensities

; ============================================================================
; Enemy Sprite Data Pointers
; ============================================================================
; Address: $098460-$0985f4
; Format: 5-byte entries pointing to enemy sprite graphics
; Used to load enemy graphics into VRAM during battle
; ============================================================================

; Sprite Pointer Format (5 bytes per enemy):
; Offset  Size  Description
; +$00    2     Address low/mid bytes (little endian)
; +$02    1     Bank byte
; +$03    1     Sprite type/flags
; +$04    1     Unused/padding ($00)

	STRUCT EnemySpritePointer
	.address    .word               ; 2 bytes - pointer to graphics data
	.bank       .byte               ; 1 byte - ROM bank ($09-$0f typically)
	.flags      .byte               ; 1 byte - sprite configuration flags
	.padding    .byte               ; 1 byte - always $00
	ENDSTRUCT

; Example entries:
Enemy_00_SpritePtr:	; $098460
	dw $85f5                        ; Address in bank
	db $09                          ; Bank $09
	db $04                          ; Flags: sprite type 4
	db $00                          ; Padding

Enemy_01_SpritePtr:	; $098465
	dw $85f5                        ; Same graphics as enemy 0
	db $09
	db $03                          ; Different flags
	db $00

Enemy_02_SpritePtr:	; $09846a
	dw $85f5                        ; Reuses graphics
	db $09
	db $01                          ; Simpler sprite
	db $00

; Pattern observed:
; - Many enemies share sprite data (same address)
; - Flags byte determines sprite behavior/size
; - Common flag values:
;   $00 = Basic sprite
;   $01 = Small sprite
;   $02-$04 = Medium sprites
;   $05-$10 = Large sprites
;   $11+ = Boss/special sprites

; ============================================================================
; Enemy Sprite Graphics Data
; ============================================================================
; Address: $0985f5+
; Format: Compressed or raw 4BPP tile data
; Contains the actual pixel data for enemy sprites
; ============================================================================

; Tile Data appears to be in 4BPP planar format:
; - 8x8 pixel tiles
; - 4 bits per pixel (16 colors)
; - 32 bytes per tile
; - May be compressed (needs further analysis)

EnemySprite_Data_00:	; $0985f5
; First tile row (8 pixels)
	db $00,$00                      ; Bitplane 0/1
	db $03,$03                      ; Bitplane 2/3
	db $0f,$0c                      ; Next row...
	db $1c,$10
	db $39,$20
	db $72,$40
	db $e4,$80
	db $e1,$80
; Continues for full sprite...

; ============================================================================
; Battle System RAM Variables (Inferred)
; ============================================================================
; These addresses are likely used during battle based on code patterns:
;
; Enemy State Block (per enemy, ~32-64 bytes each):
; +$00  Enemy ID
; +$01  Enemy HP (current) - word
; +$03  Enemy HP (max) - word
; +$05  Enemy status flags - byte
; +$06  Enemy position X - byte
; +$07  Enemy position Y - byte
; +$08  Sprite pointer offset - word
; +$0a  Palette index - byte
; +$0b  Animation frame - byte
; +$0c  AI routine pointer - word
; +$0e  Stats (ATK/DEF/etc) - multiple bytes
; ============================================================================

; ============================================================================
; Enemy Sprite Rendering Process (Inferred)
; ============================================================================
; 1. Load enemy ID
; 2. Look up sprite pointer at $098460 + (ID * 5)
; 3. Extract bank and address from pointer
; 4. Load sprite flags to determine size/type
; 5. DMA transfer sprite data from ROM to VRAM
; 6. Look up palette at $098000 + (ID * 16)
; 7. Transfer palette to CGRAM
; 8. Set OAM entries for sprite positioning
; ============================================================================

; ============================================================================
; Color Format Notes
; ============================================================================
; SNES uses RGB555 format (15-bit color):
; Bit pattern: 0BBBBBGGGGGRRRRR
; - 5 bits red (0-31)
; - 5 bits green (0-31)
; - 5 bits blue (0-31)
; - 1 bit unused (always 0)
;
; Common colors in battle system:
; $0000 = RGB(00,00,00) = Black/Transparent
; $7fff = RGB(31,31,31) = White
; $001f = RGB(31,00,00) = Pure Red
; $03e0 = RGB(00,31,00) = Pure Green
; $7c00 = RGB(00,00,31) = Pure Blue
; ============================================================================

; ============================================================================
; Enemy Data Table Sizes
; ============================================================================
; Total Palettes: ~70 entries (16 bytes each) = 1,120 bytes
; Total Sprite Pointers: ~70 entries (5 bytes each) = 350 bytes
; Sprite Graphics: Variable size per enemy (100-2000 bytes typical)
; ============================================================================

; ============================================================================
; Boss/Special Enemy Indicators
; ============================================================================
; Certain patterns indicate boss enemies:
; - Larger sprite data (>1KB)
; - Complex palettes with many colors
; - Higher sprite flags ($18+)
; - Unique graphics (not shared with other enemies)
;
; Examples (inferred from data size):
; - Entries with flags $18-$27 appear to be bosses
; - Large data chunks suggest multiple animation frames
; ============================================================================
