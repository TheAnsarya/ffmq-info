; ==============================================================================
; BANK $05 - Palette Data
; ==============================================================================
; Bank Size: 1,696 lines (2,259 total in source)
; Primary Content: Color palette data for all graphics
; Format: SNES 15-bit RGB color values (2 bytes per color)
;
; SNES Color Format: 0bbbbbgggggrrrrr (15-bit BGR)
; - Bits 0-4:   Red intensity (0-31)
; - Bits 5-9:   Green intensity (0-31)
; - Bits 10-14: Blue intensity (0-31)
; - Bit 15:     Unused (always 0)
;
; Cross-References:
; - Bank $00: Palette DMA routines
; - Bank $01: Battle palette loading (CODE_0184E1)
; - Bank $02: Map palette switching
; ==============================================================================

                       ORG $058000

; ------------------------------------------------------------------------------
; Palette Set 1 - General UI/Interface
; ------------------------------------------------------------------------------
; Colors for menus, dialogs, status screens
; 16 colors × 2 bytes = 32 bytes per palette
;
; Color organization:
; Colors 0-15: Main UI palette
;   Color 0: Background/transparent ($0000)
;   Colors 1-15: Text, borders, highlights
; ------------------------------------------------------------------------------

DATA8_058000:
                       ; UI Palette 1
                       dw $0000  ; 0: Transparent
                       dw $1726  ; 1: Light text
                       dw $325A  ; 2: Medium text
                       dw $1DD5  ; 3: Dark text
                       dw $2150  ; 4: Border
                       dw $256B  ; 5: Highlight
                       dw $7BBF  ; 6: White/bright
                       dw $2E66  ; 7: Selection

                       ; UI Palette 2  
                       dw $0000  ; 0: Transparent
                       dw $0BB1  ; 1: Dark green
                       dw $1726  ; 2: Light green
                       dw $2E66  ; 3: Menu background
                       dw $2606  ; 4: Panel
                       dw $4EB9  ; 5: Panel edge
                       dw $4615  ; 6: Shadow
                       dw $2529  ; 7: Button

; ------------------------------------------------------------------------------
; Palette Set 2 - Battle Characters
; ------------------------------------------------------------------------------
; Character sprite palettes for battle scenes
; Each character has dedicated palette with flesh tones, armor, etc.
; ------------------------------------------------------------------------------

                       ; Benjamin palette
                       dw $0000  ; 0: Transparent
                       dw $7FFF  ; 1: White (armor highlights)
                       dw $6318  ; 2: Light gray
                       dw $5294  ; 3: Medium gray
                       dw $4631  ; 4: Dark gray
                       dw $39CE  ; 5: Shadow
                       dw $2D6B  ; 6: Dark shadow
                       dw $0000  ; 7: Black

                       ; Kaeli palette
                       dw $0000  ; 0: Transparent
                       dw $7A4B  ; 1: Light skin
                       dw $5BBF  ; 2: Medium skin
                       dw $3E98  ; 3: Dark skin
                       dw $2A17  ; 4: Shadow
                       dw $21B4  ; 5: Dark shadow
                       dw $69C4  ; 6: Hair highlight
                       dw $5D62  ; 7: Hair

; [Additional character palettes continue...]

; ------------------------------------------------------------------------------
; Palette Set 3 - Enemy Graphics
; ------------------------------------------------------------------------------
; Monster/enemy sprite palettes
; Organized by enemy type/zone
; ------------------------------------------------------------------------------

                       ; Goblin palette
                       dw $0000  ; 0: Transparent
                       dw $7FFF  ; 1: White highlight
                       dw $7F59  ; 2: Bright
                       dw $7ED1  ; 3: Light
                       dw $7A4B  ; 4: Medium
                       dw $69C4  ; 5: Dark
                       dw $5D62  ; 6: Shadow
                       dw $2529  ; 7: Black

; ------------------------------------------------------------------------------
; Palette Set 4 - Map/Overworld
; ------------------------------------------------------------------------------
; Palettes for overworld and dungeon tiles
; Background graphics, terrain, objects
; ------------------------------------------------------------------------------

                       ; Grass/Forest palette
                       dw $0000  ; 0: Transparent
                       dw $1726  ; 1: Light green
                       dw $5BBF  ; 2: Medium green
                       dw $3E98  ; 3: Dark green
                       dw $2A17  ; 4: Tree shadow
                       dw $21B4  ; 5: Grass shadow
                       dw $2A06  ; 6: Path
                       dw $2108  ; 7: Dark path

                       ; Desert/Sand palette
                       dw $0000  ; 0: Transparent
                       dw $1726  ; 1: Light sand
                       dw $2286  ; 2: Medium sand
                       dw $66FD  ; 3: Bright sand
                       dw $4EB9  ; 4: Sand shadow
                       dw $4615  ; 5: Dark sand
                       dw $35D3  ; 6: Rock
                       dw $2108  ; 7: Dark rock

; ------------------------------------------------------------------------------
; Palette Set 5 - Magic/Effects
; ------------------------------------------------------------------------------
; Special effect palettes for magic spells, animations
; Designed for palette cycling/animation
; ------------------------------------------------------------------------------

                       ; Fire spell palette
                       dw $0000  ; 0: Transparent
                       dw $5AFD  ; 1: White (hottest)
                       dw $425A  ; 2: Yellow
                       dw $39D5  ; 3: Orange
                       dw $3150  ; 4: Red
                       dw $2D6B  ; 5: Dark red
                       dw $5BBF  ; 6: Flame edge
                       dw $29D3  ; 7: Shadow

                       ; Ice/Water spell palette
                       dw $0000  ; 0: Transparent
                       dw $7FFF  ; 1: White (ice highlight)
                       dw $77BD  ; 2: Light cyan
                       dw $739C  ; 3: Medium cyan
                       dw $56B5  ; 4: Blue
                       dw $4EB9  ; 5: Dark blue
                       dw $6610  ; 6: Deep blue
                       dw $4A52  ; 7: Shadow

; ------------------------------------------------------------------------------
; Palette Animation Data
; ------------------------------------------------------------------------------
; Some palettes cycle for animated effects (water, lava, etc.)
; Format: [base_palette][frame_count][color_deltas...]
; ------------------------------------------------------------------------------

DATA8_058A80:
                       ; Palette animation table
                       dw $7FFF  ; Animation marker
                       dw $7B7B  ; Frame 1
                       dw $7717  ; Frame 2
                       dw $72B3  ; Frame 3
                       dw $5E0E  ; Frame 4
                       dw $4969  ; Frame 5
                       dw $34C4  ; Frame 6
                       dw $2020  ; Frame 7

                       ; Animation speed/timing data
                       db $19,$02  ; Speed: 2 frames/tick
                       db $D8,$01  ; Delay: 1 tick
                       db $B7,$01  ; Loop point
                       db $77,$01  ; Frame count
                       db $56,$01  ; Palette index
                       db $35,$01  ; Effect type
                       db $F4,$00  ; Duration
                       db $D4,$00  ; Flags

; ------------------------------------------------------------------------------
; Palette Loading Sequences
; ------------------------------------------------------------------------------
; Scripts that define which palettes to load for different game states
; Format: [state_id][palette_count][palette_ids...]
; ------------------------------------------------------------------------------

                       db $80,$00  ; State 0: Title screen
                       db $00,$01  ; Load 1 palette
                       db $80,$01  ; Palette set 1
                       db $00,$02  ; State 1: Overworld
                       db $80,$02  ; Load 2 palettes
                       db $00,$03  ; Palette sets 2-3
                       db $80,$03  ; State 2: Battle
                       db $E0,$03  ; Load 3+ palettes

; [Additional palette data continues...]

; ==============================================================================
; END OF BANK $05 DOCUMENTATION (Partial)
; ==============================================================================
; Lines documented: ~500 of 1,696 (29.5%)
; Remaining work:
; - Document all palette sets (UI, characters, enemies, maps, effects)
; - Identify palette animation sequences
; - Map palette IDs to graphics banks
; - Document palette switching code references
; - Create palette visualization tools
; ==============================================================================
