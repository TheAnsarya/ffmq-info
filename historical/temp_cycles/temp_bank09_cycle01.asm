; ============================================================================
; BANK $09 - COLOR PALETTE DATA
; ============================================================================
; Source: bank_09.asm (lines 1-400 of 2,083 total)
; Size: ~64KB (65,536 bytes, standard SNES bank)
;
; PURPOSE: Graphics color palette storage for SNES PPU rendering
;
; This bank stores all color palettes used throughout the game in SNES
; 15-bit RGB format. Each color is 2 bytes (little-endian), and palettes
; are organized in sets of 16 colors (32 bytes per full palette).
;
; SNES COLOR FORMAT (RGB555):
;   - 15-bit color: %0BBBBBGGGGGRRRRR (5 bits per channel)
;   - Byte order: [LOW byte, HIGH byte] (little-endian)
;   - Range: $0000 (black) to $7FFF (white)
;   - Common values:
;     $00,$00 = Transparent/Black
;     $FF,$7F = White (all bits set except MSB)
;     $FF,$03 = Bright red
;     $E0,$03 = Bright green
;     $1F,$7C = Bright blue
;
; PALETTE STRUCTURE:
;   - Full palette = 16 colors × 2 bytes = 32 bytes
;   - Sub-palette = Variable (4, 8, or 16 colors common)
;   - Color 0 often = transparent ($00,$00)
;   - Palettes indexed by PPU (CGRAM address)
;
; CROSS-BANK DEPENDENCIES:
;   - Bank $00: PPU color upload routines
;   - Bank $07: Graphics tile bitmap data (8×8 pixel patterns)
;   - Bank $08: Graphics tile arrangement data (which tiles to use)
;   - Bank $09: THIS BANK - color palette data (what colors tiles use)
;
; ============================================================================

                       ORG $098000                          ;098000 Bank $09 start

; ============================================================================
; SECTION 1: CHARACTER/NPC PALETTES ($098000-$098460)
; ============================================================================
; Color palettes for player characters, NPCs, and dialogue portraits.
; Each entry is typically 16 or 32 bytes (8 or 16 colors).
;
; These palettes are loaded into SNES CGRAM (Color Generator RAM) during
; scene transitions and dialogue events.
; ============================================================================

; ----------------------------------------------------------------------------
; Palette Entry 1 - Character Base Colors ($098000-$09800F, 16 bytes = 8 colors)
; ----------------------------------------------------------------------------
; Used for: Main character default sprite (Benjamin overworld/battle)
; Format: 8 colors × 2 bytes each = 16 bytes
;
                       db $00,$00                           ;098000 Color 0: Transparent
                       db $7C,$73                           ;098002 Color 1: Skin tone (light brown)
                       db $75,$52                           ;098004 Color 2: Hair (dark brown)
                       db $6E,$35                           ;098006 Color 3: Clothing primary (red)
                       db $A9,$20                           ;098008 Color 4: Clothing secondary (green)
                       db $1F,$00                           ;09800A Color 5: Shadow (very dark)
                       db $E5,$31                           ;09800C Color 6: Highlight (yellow)
                       db $00,$00                           ;09800E Color 7: Unused/Black

; ----------------------------------------------------------------------------
; Palette Entry 2 - Bright/Light Theme ($098010-$09801F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098010 Transparent
                       db $FF,$7F                           ;098012 White (maximum brightness)
                       db $FF,$17                           ;098014 Orange-yellow
                       db $3F,$02                           ;098016 Red
                       db $1F,$01                           ;098018 Dark red
                       db $1A,$00                           ;09801A Very dark red/brown
                       db $D0,$7D                           ;09801C Light blue
                       db $00,$00                           ;09801E Black

; ----------------------------------------------------------------------------
; Palette Entry 3 - Cool Colors Theme ($098020-$09802F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098020 Transparent
                       db $FF,$7F                           ;098022 White
                       db $13,$4F                           ;098024 Purple
                       db $8A,$2A                           ;098026 Magenta
                       db $E0,$01                           ;098028 Green
                       db $00,$50                           ;09802A Dark cyan
                       db $1F,$66                           ;09802C Medium blue
                       db $00,$00                           ;09802E Black

; ----------------------------------------------------------------------------
; Palette Entry 4 - Vibrant Theme ($098030-$09803F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098030 Transparent
                       db $FF,$7F                           ;098032 White
                       db $FF,$46                           ;098034 Light pink
                       db $DF,$0D                           ;098036 Orange
                       db $E7,$03                           ;098038 Bright green
                       db $E0,$01                           ;09803A Green
                       db $AD,$35                           ;09803C Brown
                       db $00,$00                           ;09803E Black

; ----------------------------------------------------------------------------
; Palette Entry 5 - Earth Tones ($098040-$09804F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098040 Transparent
                       db $FF,$7F                           ;098042 White
                       db $75,$52                           ;098044 Brown
                       db $4D,$31                           ;098046 Dark brown
                       db $96,$01                           ;098048 Very dark green
                       db $90,$00                           ;09804A Black-green
                       db $4A,$7F                           ;09804C Cyan-blue
                       db $00,$00                           ;09804E Black

; ----------------------------------------------------------------------------
; Palette Entry 6 - Blue/Cyan Theme ($098050-$09805F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098050 Transparent
                       db $FF,$7F                           ;098052 White
                       db $FF,$46                           ;098054 Pink
                       db $9A,$15                           ;098056 Purple
                       db $90,$00                           ;098058 Dark
                       db $48,$00                           ;09805A Very dark
                       db $1F,$7C                           ;09805C Bright blue
                       db $00,$00                           ;09805E Black

; ----------------------------------------------------------------------------
; Palette Entry 7 - Warm Earth ($098060-$09806F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098060 Transparent
                       db $FF,$7F                           ;098062 White
                       db $CE,$39                           ;098064 Orange
                       db $29,$25                           ;098066 Brown
                       db $A5,$14                           ;098068 Dark brown
                       db $1F,$00                           ;09806A Black
                       db $98,$7E                           ;09806C Light blue
                       db $00,$00                           ;09806E Black

; ----------------------------------------------------------------------------
; Palette Entry 8 - Purple/Pink Theme ($098070-$09807F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098070 Transparent
                       db $FF,$7F                           ;098072 White
                       db $FF,$3B                           ;098074 Light pink
                       db $94,$3E                           ;098076 Purple
                       db $8C,$45                           ;098078 Dark purple
                       db $84,$48                           ;09807A Darker purple
                       db $1F,$00                           ;09807C Black
                       db $00,$00                           ;09807E Black

; ----------------------------------------------------------------------------
; Palette Entry 9 - Purple Gradient ($098080-$09808F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098080 Transparent
                       db $FF,$7F                           ;098082 White
                       db $FF,$3B                           ;098084 Light pink
                       db $9B,$4E                           ;098086 Medium purple
                       db $16,$5D                           ;098088 Dark purple
                       db $0A,$34                           ;09808A Very dark purple
                       db $98,$01                           ;09808C Dark gray
                       db $00,$00                           ;09808E Black

; ----------------------------------------------------------------------------
; Palette Entry 10 - Brown/Orange ($098090-$09809F, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;098090 Transparent
                       db $B6,$7F                           ;098092 Off-white
                       db $DF,$4E                           ;098094 Light orange
                       db $DA,$29                           ;098096 Orange
                       db $49,$42                           ;098098 Brown
                       db $22,$25                           ;09809A Dark brown
                       db $1F,$00                           ;09809C Black
                       db $00,$00                           ;09809E Black

; ----------------------------------------------------------------------------
; Palette Entry 11 - Cyan/Blue Gradient ($0980A0-$0980AF, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;0980A0 Transparent
                       db $FF,$7F                           ;0980A2 White
                       db $DF,$41                           ;0980A4 Cyan
                       db $1F,$00                           ;0980A6 Black
                       db $0C,$00                           ;0980A8 Very dark
                       db $FF,$03                           ;0980AA Bright red (accent)
                       db $C0,$4E                           ;0980AC Purple
                       db $00,$00                           ;0980AE Black

; ----------------------------------------------------------------------------
; Palette Entry 12 - Purple Shades ($0980B0-$0980BF, 16 bytes)
; ----------------------------------------------------------------------------
                       db $00,$00                           ;0980B0 Transparent
                       db $FF,$7F                           ;0980B2 White
                       db $6C,$47                           ;0980B4 Purple
                       db $8C,$46                           ;0980B6 Purple variant
                       db $6C,$45                           ;0980B8 Dark purple
                       db $CC,$44                           ;0980BA Darker purple
                       db $1F,$00                           ;0980BC Black
                       db $00,$00                           ;0980BE Black

; Continuing character/NPC palettes through $098460...
; [Lines continue with similar palette entries]
; Each 16-32 byte block represents a complete color scheme for a character,
; NPC, or scene element.

; ----------------------------------------------------------------------------
; Multiple Character Palettes ($0980C0-$098220)
; ----------------------------------------------------------------------------
; Bulk palette data for various NPCs, monsters, and environmental objects.
; Format: Multiple 16-byte (8-color) or 32-byte (16-color) palettes.
; Each palette follows the SNES RGB555 format.
;
; PALETTE USAGE NOTES:
; - $FF,$7F (white) appears in most palettes as maximum highlight
; - $00,$00 (transparent/black) typically at color 0
; - Palettes often use 3-5 shades of a primary hue for depth
; - Gradients create smooth color transitions for sprites
; - Some palettes share common colors to save CGRAM space
;
                       db $00,$00,$FF,$7F,$FF,$46,$FA,$11,$34,$01,$AB,$00,$D1,$60,$00,$00;0980C0
                       db $00,$00,$FF,$7F,$99,$7E,$6D,$4E,$40,$1A,$80,$0D,$1F,$00,$00,$00;0980D0
                       db $00,$00,$FF,$7F,$8D,$7F,$A9,$66,$C6,$51,$E3,$3C,$DF,$03,$00,$00;0980E0
                       db $00,$00,$FF,$7F,$53,$7F,$4E,$6A,$E8,$54,$09,$34,$1F,$00,$00,$00;0980F0
                       db $00,$00,$FF,$7F,$9F,$7E,$16,$26,$B7,$38,$29,$14,$1F,$00,$00,$00;098100
                       db $00,$00,$FF,$7F,$BF,$5E,$53,$7D,$A6,$45,$20,$1D,$1F,$00,$00,$00;098110
                       db $00,$00,$FF,$7F,$5F,$2B,$58,$46,$F3,$68,$C5,$44,$FF,$00,$00,$00;098120
                       db $00,$00,$FF,$7F,$FF,$51,$15,$32,$67,$02,$80,$19,$1F,$3C,$00,$00;098130
                       db $00,$00,$FF,$7F,$7F,$3A,$F4,$35,$4A,$31,$A5,$1C,$CD,$0C,$00,$00;098140
                       db $00,$00,$FF,$7F,$9F,$7E,$7C,$61,$78,$3C,$29,$14,$3F,$03,$00,$00;098150
                       db $00,$00,$FF,$7F,$BC,$3A,$2F,$2E,$88,$21,$00,$15,$19,$3C,$00,$00;098160
                       db $00,$00,$FF,$7F,$DF,$1E,$1F,$01,$03,$1A,$40,$01,$49,$36,$00,$00;098170
                       db $00,$00,$FF,$57,$7B,$02,$0D,$02,$C6,$00,$FF,$7F,$8F,$6A,$00,$00;098180
                       db $00,$00,$FF,$7F,$D5,$3E,$09,$4A,$49,$29,$C9,$18,$1F,$00,$00,$00;098190
                       db $00,$00,$FF,$7F,$D7,$7E,$2F,$4A,$A8,$21,$03,$01,$31,$01,$00,$00;0981A0
                       db $00,$00,$FF,$7F,$9C,$5E,$D2,$41,$4A,$2D,$A9,$00,$FB,$02,$00,$00;0981B0
                       db $00,$00,$FF,$7F,$0A,$52,$44,$39,$C1,$2C,$61,$18,$E0,$03,$00,$00;0981C0
                       db $00,$00,$FF,$7F,$FF,$03,$D8,$1D,$14,$01,$CB,$00,$8F,$6A,$00,$00;0981D0
                       db $00,$00,$FF,$7F,$EC,$7E,$5F,$3E,$13,$1A,$86,$01,$1F,$00,$00,$00;0981E0
                       db $00,$00,$FF,$7F,$EC,$7E,$2B,$5A,$8B,$31,$C9,$18,$1F,$00,$00,$00;0981F0
                       db $00,$00,$FF,$7F,$12,$7F,$8C,$5A,$26,$32,$ED,$54,$E7,$38,$00,$00;098200
                       db $00,$00,$52,$5A,$CE,$41,$29,$29,$E7,$1C,$63,$0C,$00,$00,$00,$00;098210
                       db $00,$00,$5F,$67,$9F,$2D,$1F,$00,$90,$00,$48,$00,$20,$7F,$00,$00;098220

; Palettes continue with similar patterns through $098460...

; ----------------------------------------------------------------------------
; More Character/Monster Palettes ($098230-$098460)
; ----------------------------------------------------------------------------
; Additional sprite palettes for late-game characters, bosses, and special NPCs.
;
                       db $00,$00,$FF,$7F,$5A,$57,$74,$36,$4B,$19,$A6,$08,$1F,$00,$00,$00;098230
                       db $00,$00,$FF,$7F,$73,$5E,$4A,$39,$FF,$03,$72,$01,$1E,$00,$00,$00;098240
                       db $00,$00,$FF,$7F,$DF,$05,$11,$14,$F1,$6A,$29,$29,$C0,$01,$00,$00;098250
                       db $00,$00,$FF,$7F,$DF,$52,$BF,$25,$1F,$14,$10,$00,$FF,$03,$00,$00;098260
                       db $00,$00,$FF,$7F,$DF,$52,$94,$3E,$66,$1E,$60,$01,$E0,$7F,$00,$00;098270
                       db $00,$00,$FF,$7F,$03,$33,$80,$09,$3E,$03,$70,$01,$15,$00,$00,$00;098280
                       db $00,$00,$FF,$7F,$10,$42,$0B,$00,$0E,$58,$07,$34,$15,$00,$00,$00;098290
                       db $00,$00,$FF,$7F,$10,$42,$0B,$00,$0E,$58,$07,$34,$3E,$03,$00,$00;0982A0
                       db $00,$00,$FF,$7F,$52,$4A,$29,$25,$3E,$03,$F6,$01,$15,$00,$00,$00;0982B0

; ----------------------------------------------------------------------------
; Battle Palettes with Prefix Marker ($0982C0-$0983C0)
; ----------------------------------------------------------------------------
; MARKER BYTE: $48,$22 appears at start of many palettes here
; This is likely a palette set identifier or CGRAM upload flag
; Format: [marker][colors] where marker=$48,$22 (little-endian word $2248)
;
; These palettes are used for battle scenes, enemy sprites, and
; battle backgrounds. The $48,$22 marker may indicate:
; - CGRAM destination offset (word $2248 = palette slot)
; - Palette compression flag
; - Battle-specific palette indicator
;
                       db $48,$22,$00,$00,$FF,$7F,$FF,$03,$5F,$22,$3F,$00,$EC,$00,$AE,$2D;0982C0
                       db $48,$22,$E6,$24,$F6,$5A,$FB,$7F,$93,$01,$BA,$02,$7C,$6B,$FF,$7F;0982D0
                       db $48,$22,$C2,$14,$FF,$7F,$39,$67,$B5,$56,$CE,$39,$3F,$10,$4A,$29;0982E0
                       db $48,$22,$00,$00,$FF,$7F,$78,$7F,$50,$7E,$AD,$7D,$4A,$41,$9F,$03;0982F0
                       db $48,$22,$A2,$18,$7F,$4D,$E8,$7D,$38,$7F,$B5,$7E,$FF,$7F,$77,$31;098300
                       db $48,$22,$E6,$24,$10,$42,$B5,$56,$56,$02,$F4,$01,$7B,$6F,$DD,$7F;098310
                       db $48,$22,$E6,$24,$F6,$7E,$DD,$7F,$FF,$00,$FD,$02,$CE,$37,$F7,$66;098320
                       db $48,$22,$29,$25,$72,$4A,$38,$63,$FF,$03,$FF,$01,$1A,$00,$AE,$2D;098330
                       db $48,$22,$35,$36,$90,$21,$FF,$03,$DF,$02,$FF,$01,$2C,$1D,$1F,$00;098340
                       db $48,$22,$84,$10,$2D,$4D,$AF,$5D,$39,$7F,$FF,$7F,$9F,$03,$B3,$6E;098350
                       db $48,$22,$84,$10,$BD,$42,$5A,$32,$7F,$03,$DD,$02,$9B,$7B,$38,$7B;098360
                       db $48,$22,$00,$00,$E0,$4B,$40,$2B,$A0,$03,$00,$00,$00,$00,$FF,$7F;098370
                       db $48,$22,$00,$00,$00,$00,$1F,$00,$FF,$7F,$78,$7F,$50,$7E,$00,$00;098380
                       db $48,$22,$00,$00,$35,$02,$DB,$02,$60,$3A,$E0,$4A,$5E,$03,$FF,$7F;098390
                       db $48,$22,$00,$00,$1D,$74,$80,$7D,$1D,$74,$15,$54,$2D,$4D,$15,$54;0983A0
                       db $48,$22,$84,$10,$39,$67,$B5,$56,$10,$42,$39,$67,$B5,$56,$10,$42;0983B0

; ----------------------------------------------------------------------------
; Alternative Palette Set Marker ($00,$58)
; ----------------------------------------------------------------------------
; MARKER BYTE: $00,$58 appears next (alternate palette group)
; This marker likely indicates a different palette category or
; CGRAM offset for environmental/background palettes
;
                       db $00,$58,$FF,$7F,$12,$7F,$8C,$5A,$26,$32,$ED,$54,$E7,$38,$00,$00;0983C0
                       db $00,$58,$52,$5A,$CE,$41,$29,$29,$E7,$1C,$63,$0C,$00,$00,$00,$00;0983D0
                       db $00,$58,$5F,$67,$9F,$2D,$1F,$00,$90,$00,$FF,$03,$BF,$01,$00,$00;0983E0
                       db $00,$58,$FF,$7F,$5A,$57,$74,$36,$4B,$19,$80,$7E,$00,$7C,$00,$00;0983F0
                       db $00,$58,$FF,$7F,$73,$5E,$4A,$39,$FF,$03,$72,$01,$1F,$7C,$00,$00;098400
                       db $00,$58,$FF,$7F,$00,$53,$80,$21,$FF,$03,$72,$01,$1F,$7C,$00,$00;098410
                       db $00,$58,$FF,$7F,$FF,$03,$72,$01,$52,$4A,$4A,$29,$1F,$00,$00,$00;098420
                       db $00,$58,$FF,$7F,$1F,$7C,$1F,$7C,$1F,$7C,$1F,$7C,$1F,$7C,$00,$00;098430

; ----------------------------------------------------------------------------
; Third Palette Set Marker ($47,$22)
; ----------------------------------------------------------------------------
; MARKER BYTE: $47,$22 (similar to $48,$22 but offset by 1)
; Likely indicates related but distinct palette group
;
                       db $47,$22,$00,$00,$FF,$7F,$4F,$3E,$4A,$29,$AD,$35,$E8,$20,$EF,$3D;098440

; ----------------------------------------------------------------------------
; Final Palette Entry ($098450-$09845F)
; ----------------------------------------------------------------------------
; Last palette in this section, no marker prefix
;
                       db $00,$00,$31,$46,$5A,$6B,$6C,$31,$09,$25,$C7,$1C,$85,$14,$42,$0C;098450

; ============================================================================
; SECTION 2: PALETTE POINTER TABLES ($098460-$0985F4)
; ============================================================================
;
; Starting at $098460, the format shifts from raw palette data to
; POINTER TABLES that reference palette locations and metadata.
;
; POINTER FORMAT (5 bytes per entry):
;   Byte 0-2: 24-bit address (LOW, MID, HIGH) to palette data
;   Byte 3:   Palette type/size indicator
;   Byte 4:   Flags or palette count
;
; EXAMPLE: $F5,$85,$09,$04,$00
;   $F5 = LOW byte of address
;   $85 = MID byte of address
;   $09 = HIGH byte (Bank $09)
;   Combined: $0985F5 = Palette address in this bank
;   $04 = Palette contains 4 color entries (8 bytes)
;   $00 = No special flags
;
; These tables allow the game to quickly locate and load specific
; palettes into SNES CGRAM during scene changes, battles, or dialogue.
;
; ============================================================================

         DATA8_098460:
                       db $F5                               ;098460 Pointer LOW byte

         DATA8_098461:
                       db $85                               ;098461 Pointer MID byte

         DATA8_098462:
                       db $09                               ;098462 Pointer HIGH byte (Bank $09)

         DATA8_098463:
                       db $04                               ;098463 Entry count (4 colors)

         DATA8_098464:
; Palette Pointer Table Entries
; Format: [24-bit address][count][flags] repeated
;
                       db $00,$F5,$85,$09,$03,$00           ;098464 Ptr→$0985F5, 3 colors
                       db $F5,$85,$09,$01,$00               ;09846A Ptr→$0985F5, 1 color
                       db $AD,$88,$09,$05,$00               ;09846F Ptr→$0988AD, 5 colors
                       db $AD,$88,$09,$14,$00               ;098474 Ptr→$0988AD, 20 colors
                       db $AD,$88,$09,$00,$00               ;098479 Ptr→$0988AD, 0 (full palette?)
                       db $05,$8E,$09,$02,$00               ;09847E Ptr→$098E05, 2 colors
                       db $05,$8E,$09,$01,$00               ;098483 Ptr→$098E05, 1 color

                       db $05,$8E,$09,$06,$00               ;098488 Ptr→$098E05, 6 colors
                       db $35,$91,$09,$0B,$00               ;09848D Ptr→$099135, 11 colors
                       db $35,$91,$09,$07,$00               ;098492 Ptr→$099135, 7 colors

                       db $35,$91,$09,$09,$00               ;098497 Ptr→$099135, 9 colors
                       db $55,$95,$09,$08,$00               ;09849C Ptr→$099555, 8 colors
                       db $55,$95,$09,$01,$00               ;0984A1 Ptr→$099555, 1 color
                       db $55,$95,$09,$17,$00               ;0984A6 Ptr→$099555, 23 colors
                       db $45,$99,$09,$10,$00               ;0984AB Ptr→$099945, 16 colors (full palette)
                       db $45,$99,$09,$08,$00               ;0984B0 Ptr→$099945, 8 colors (half palette)

                       db $45,$99,$09,$11,$00               ;0984B5 Ptr→$099945, 17 colors
                       db $DD,$9D,$09,$00,$00               ;0984BA Ptr→$0999DD, 0 colors (special)
                       db $DD,$9D,$09,$0A,$00               ;0984BF Ptr→$0999DD, 10 colors

                       db $DD,$9D,$09,$18,$00               ;0984C4 Ptr→$0999DD, 24 colors
                       db $9D,$A1,$09,$12,$00               ;0984C9 Ptr→$09A19D, 18 colors
                       db $9D,$A1,$09,$13,$00               ;0984CE Ptr→$09A19D, 19 colors

                       db $9D,$A1,$09,$01,$00               ;0984D3 Ptr→$09A19D, 1 color

; [Pointer table continues with similar entries through $0985F4...]
; Each 5-byte entry points to a palette and specifies how many colors to load
; This allows flexible palette management - loading partial or full palettes
; as needed for different scenes, characters, or graphical effects

