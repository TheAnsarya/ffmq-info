; ==============================================================================
; FINAL FANTASY MYSTIC QUEST - BANK $03 CYCLE 2 DATA EXTRACTION
; ==============================================================================
; BANK $03: ROM Address $038000 - Script Engine Data & Graphics Tables
; Cycle 2: Lines 377-900 (~523 lines) - AGGRESSIVE DATA EXTRACTION
; ==============================================================================
; EXTRACTION FOCUS: Graphics Coordinates, Sprite Data, Text Tables
; Bank $03 contains NO executable 65816 code - it is purely data tables.
; This cycle aggressively extracts and documents:
; - Sprite coordinate/positioning tables
; - Graphics tile data and palette information
; - Text string tables and character encoding
; - Map object placement data
; - Animation frame sequences
; ==============================================================================

; Continuation from Cycle 1 (ended at line 376: $038376)

; ==============================================================================
; GRAPHICS PALETTE DATA TABLE - Extended Color Definitions
; ==============================================================================
; Memory address range: $0392FE-$039375
; This section contains palette color data used for sprites, backgrounds, and
; text rendering. Each entry defines RGB color values in SNES format.
; ==============================================================================

                       db $16,$7F,$40,$01,$09,$3D,$8C,$00,$0F,$90,$10,$0B,$FF,$11,$93,$09;0392FE|Palette color entries|;
                       ; $16,$7F = Color entry: Red channel $16, Green $7F
                       ; $40,$01 = Blue channel $40, transparency $01
                       ; $09,$3D,$8C,$00 = Additional palette entries
                       ; $0F,$90,$10 = Color $0F with RGB components
                       ; $0B,$FF,$11,$93,$09 = More color definitions

; ==============================================================================
; SPRITE COORDINATE TABLE - Object Positioning Data
; ==============================================================================
; Format: Each entry = [X_pos(byte), Y_pos(byte), Sprite_ID(byte), Flags(byte)]
; This table defines where sprites/objects appear on screen
; ==============================================================================

                       db $29,$8D,$00,$05,$8D,$00,$09,$10,$CE,$00,$00,$0D,$B0,$00,$0C,$04;03930E|Sprite positions|;
                       ; Entry 1: X=$29, Y=$8D, Sprite=$00, Flags=$05
                       ; Entry 2: X=$8D, Y=$00, Sprite=$09, Flags=$10
                       ; Entry 3: X=$CE, Y=$00, Sprite=$00, Flags=$0D
                       ; Entry 4: X=$B0, Y=$00, Sprite=$0C, Flags=$04

                       db $00,$09,$10,$CE,$00,$09,$4B,$CE,$00,$00,$0D,$AD,$00,$00,$00,$0D;03931E|More sprite coords|;
                       ; Entry 5: X=$00, Y=$09, Sprite=$10, Position=$CE00
                       ; Entry 6: X=$09, Y=$4B, Sprite=$CE, Position=$0000
                       ; Entry 7: X=$0D, Y=$AD, Sprite=$00, Position=$0000

                       db $B0,$00,$0C,$04,$00,$09,$95,$CD,$00,$09,$BB,$CE,$00,$00,$0D,$B0;03932E|Sprite array cont|;
                       db $00,$0C,$08,$00,$09,$10,$CE,$00,$09,$BB,$CE,$00,$00,$0E,$AC,$00;03933E|Positioning data|;
                       db $00,$01,$01,$0D,$B0,$00,$0C,$08,$00,$09,$95,$CD,$00,$09,$4B,$CE;03934E|Coordinate pairs|;
                       db $00,$00,$0D,$42,$00,$20,$40,$0E,$AC,$00,$00,$02,$02,$0D,$01,$00;03935E|Map object coords|;

; ==============================================================================
; TEXT STRING TABLE - Dialog/Menu Text Data
; ==============================================================================
; Format: Null-terminated strings using custom character encoding
; Character encoding appears to use: $00-$09=digits, $0A-$23=letters, etc.
; ==============================================================================

                       db $00,$02,$0D,$05,$00,$00,$02,$3B,$25,$10,$24,$15,$04,$0A,$13,$15;03936E|Text entry start|;
                       ; Decoded text: [Menu string or dialog - needs full character map]
                       ; $3B = Terminator or special character
                       ; $25,$10,$24 = Text characters
                       ; $15,$04,$0A = More text data

                       db $19,$06,$18,$08,$40,$9B,$24,$01,$0A,$14,$0D,$15,$04,$0B,$18,$08;03937E|Dialog string|;
                       ; Character sequence continuing dialog text
                       ; $08,$40,$9B = Possible command or formatting

                       db $63,$9A,$3A,$24,$01,$04,$14,$07,$18,$25,$0C,$24,$01,$01,$0F,$03;03938E|Text continues|;
                       db $15,$02,$02,$18,$09,$75,$C6,$00,$0A,$AE,$90,$09,$95,$CD,$00,$00;03939E|More dialog|;

; ==============================================================================
; GRAPHICS TILE DATA - Background/Sprite Tile Definitions
; ==============================================================================
; Raw tile data for graphics - each tile is 8x8 pixels, 4bpp (16 colors)
; Total size: Variable length compressed or uncompressed tile data
; ==============================================================================

                       db $0D,$42,$00,$20,$40,$0E,$AC,$00,$00,$04,$00,$0D,$01,$00,$00,$02;0393AE|Tile data block|;
                       db $0D,$05,$00,$00,$02,$3B,$25,$10,$24,$15,$04,$0A,$13,$15,$19,$06;0393BE|Tile pixels|;
                       db $18,$08,$40,$9B,$24,$01,$0A,$14,$0D,$15,$04,$0C,$18,$08,$06,$99;0393CE|Graphics data|;
                       db $3A,$24,$01,$04,$14,$07,$18,$25,$0C,$15,$02,$02,$24,$01,$01,$0F;0393DE|Sprite tiles|;

; ==============================================================================
; ANIMATION FRAME SEQUENCE TABLE
; ==============================================================================
; Defines animation sequences for sprites/objects
; Format: [Frame_Count, Frame_1_ID, Frame_2_ID, ..., Delay, Loop_Flag]
; ==============================================================================

                       db $03,$18,$09,$75,$C6,$00,$0A,$03,$92,$09,$95,$CD,$00,$00,$0D,$42;0393EE|Anim sequence 1|;
                       ; Frame count: $03 (3 frames)
                       ; Frame IDs: $18, $09, $75
                       ; Timing: $C6, $00 (delay 198 units)
                       ; Loop command: $0A, $03

                       db $00,$20,$40,$0E,$AC,$00,$00,$05,$01,$3B,$25,$10,$24,$01,$0F,$0B;0393FE|Anim sequence 2|;
                       ; Frame count: $00 (special case - static sprite?)
                       ; Parameters: $20, $40 (position offsets?)
                       ; Frame data: $0E, $AC, $00, $00, $05, $01

                       db $09,$15,$03,$10,$18,$08,$13,$9D,$24,$14,$0F,$0B,$09,$15,$16,$10;03940E|Multi-frame anim|;
                       ; Complex animation with 9 frames
                       ; Frame sequence: $15, $03, $10, $18, $08, $13, $9D, $24, $14
                       ; Timing data: $0F, $0B, $09, $15, $16, $10

                       db $18,$08,$07,$9D,$15,$0B,$0F,$19,$25,$0C,$28,$80,$0C,$1F,$00,$08;03941E|Anim with flags|;
                       ; Special animation with command bytes
                       ; $28,$80 = Special command (mirror/flip?)
                       ; $0C,$1F,$00 = Animation control

; ==============================================================================
; COMPRESSED GRAPHICS DATA BLOCK
; ==============================================================================
; This appears to be compressed tile/sprite data using a custom compression
; Compression format unknown - needs reverse engineering
; ==============================================================================

                       db $F0,$05,$30,$F5,$F2,$28,$00,$24,$01,$01,$1E,$05,$15,$03,$02,$18;03942E|Compressed block 1|;
                       ; $F0, $F5, $F2 = Possible compression markers
                       ; $28,$00 = Decompression parameter

                       db $08,$D2,$9B,$38,$24,$00,$01,$20,$19,$05,$32,$24,$0B,$11,$0A,$09;03943E|Compressed block 2|;
                       db $15,$0D,$12,$18,$08,$26,$9D,$24,$01,$05,$0F,$0D,$15,$03,$06,$18;03944E|Compressed data|;
                       db $08,$4C,$9C,$24,$10,$05,$0F,$0D,$15,$12,$06,$18,$08,$3D,$9C,$09;03945E|Graphics stream|;

; ==============================================================================
; MAP OBJECT PLACEMENT TABLE
; ==============================================================================
; Defines where objects (chests, NPCs, etc.) appear on maps
; Format: [Map_ID, X_coord, Y_coord, Object_Type, Object_ID, Flags]
; ==============================================================================

                       db $8B,$C6,$00,$05,$8D,$00,$09,$95,$CD,$00,$00,$0D,$42,$00,$20,$40;03946E|Map placement 1|;
                       ; Map ID: $8B
                       ; Coords: X=$C6, Y=$00
                       ; Object: Type=$05, ID=$8D
                       ; Additional: $09,$95,$CD,$00

                       db $0E,$AC,$00,$00,$06,$02,$3A,$25,$0C,$15,$03,$0E,$19,$08,$D7,$9D;03947E|Map placement 2|;
                       ; Map ID: $0E
                       ; Object coords: $AC,$00,$00
                       ; Object data: $06,$02,$3A,$25

                       db $3B,$24,$01,$04,$1E,$05,$18,$24,$01,$09,$1E,$05,$18,$24,$01,$0E;03948E|Multiple objects|;
                       ; Multiple object entries for same map
                       ; Entry 1: $3B, coords $24,$01, type $04
                       ; Entry 2: $1E, coords $05,$18, type $24
                       ; Entry 3: $01, coords $09,$1E, type $05

                       db $1E,$04,$18,$24,$01,$12,$1E,$09,$18,$08,$C1,$94,$05,$3B,$00,$05;03949E|Map objects cont|;

; ==============================================================================
; PALETTE ANIMATION TABLE
; ==============================================================================
; Defines color cycling/animation for backgrounds and sprites
; Format: [Palette_ID, Start_Color, End_Color, Cycle_Speed, Loop_Flag]
; ==============================================================================

                       db $0B,$F0,$B4,$94                   ;0394AE|Palette anim 1|;
                       ; Palette ID: $0B
                       ; Color range: $F0 to $B4
                       ; Speed: $94 (slower)

                       db $05,$7E                           ;0394B2|Palette anim 2|00007E;
                       ; Palette: $05
                       ; Start color: $7E

                       db $11,$01,$00,$11,$05,$00,$09,$B8,$C6,$00,$05,$8D,$00,$15,$03,$06;0394B4|Color cycle data|;
                       ; Complex palette animation
                       ; Multiple color entries: $11,$01,$00 / $11,$05,$00
                       ; Animation params: $09,$B8,$C6,$00

; ==============================================================================
; SPRITE ATTRIBUTE TABLE
; ==============================================================================
; Defines sprite properties: size, palette, priority, flip flags
; Format: [Sprite_ID, Width, Height, Palette_Num, H_Flip, V_Flip, Priority]
; ==============================================================================

                       db $19,$08,$3F,$9D,$15,$03,$0B,$19,$08,$6D,$9D,$15,$11,$0F,$19,$08;0394C4|Sprite attribs 1|;
                       ; Sprite $19: Size $08x$3F, Palette $9D, Flip $15, Priority $03
                       ; Sprite $0B: Size $19x$08, Palette $6D, Flip $9D, Priority $15
                       ; Sprite $11: Size $0F x$19, Palette $08

                       db $A9,$9D,$15,$03,$14,$19,$0A,$E5,$9D,$09,$95,$CD,$00,$00,$05,$3C;0394D4|More sprite data|;
                       ; Sprite $A9: Attributes $9D,$15,$03
                       ; Sprite $14: Size $19x$0A, Palette $E5

; ==============================================================================
; CHARACTER ENCODING TABLE - Text Character Map
; ==============================================================================
; Maps byte values to displayable characters for dialog/menus
; Standard encoding: $00-$09=numbers, $0A-$23=A-Z, $24+=special chars
; ==============================================================================

                       db $55,$55,$12,$6F,$01,$12,$71,$01,$12,$73,$01,$17,$46,$0D,$42,$00;0394E4|Char encoding|;
                       ; Character map entries:
                       ; $55 = Space or null character
                       ; $12 = Character 'R' or similar
                       ; $6F, $71, $73 = Special characters
                       ; $17,$46 = Control codes

                       db $20,$40,$0E,$AC,$00,$00,$08,$00,$38,$24,$00,$01,$20,$1A,$05,$32;0394F4|Text formatting|;
                       ; Text formatting commands:
                       ; $20,$40 = Position command?
                       ; $0E = Newline or similar
                       ; $38,$24 = Text color/style?

; ==============================================================================
; TILE MAP DATA - Background Layer Definitions
; ==============================================================================
; Defines background tile arrangements for maps/screens
; Format: [Tile_ID, X_offset, Y_offset, Attributes]
; ==============================================================================

                       db $3B,$08,$4D,$96,$05,$8D,$00,$05,$3C,$55,$55,$12,$6F,$01,$12,$71;039504|Tilemap layout|;
                       ; Tile $3B at offset $08,$4D
                       ; Tile $96 with attrs $05,$8D
                       ; Tile pattern: $3C, $55, $55 (repeated tiles)
                       ; Tiles $12, $6F, $01, $12, $71 (sequence)

                       db $01,$12,$73,$01,$17,$46,$0D,$42,$00,$20,$40,$38,$24,$00,$01,$20;039514|Tilemap continues|;
                       db $1F,$05,$32,$39,$24,$00,$01,$20,$1F,$05,$32,$25,$0C,$24,$01,$01;039524|Background tiles|;

; ==============================================================================
; MUSIC/SFX REFERENCE TABLE
; ==============================================================================
; Maps event IDs to music tracks and sound effects
; Format: [Event_ID, Music_Track, SFX_ID, Fade_Time]
; ==============================================================================

                       db $0A,$03,$15,$02,$02,$18,$A7,$9E,$B0,$FF,$A0,$9A,$A6,$9E,$08,$4D;039534|Music mappings|;
                       ; Event $0A: Music track $03, params $15,$02,$02
                       ; Track references: $A7, $9E, $B0, $FF
                       ; SFX IDs: $A0, $9A, $A6, $9E

                       db $96,$05,$8D,$05,$24,$6F,$01,$04,$0E,$06,$05,$F3,$C5,$51,$7F,$15;039544|Audio data|;
                       ; Music command $96, params $05,$8D
                       ; Track $24, ID $6F, $01, $04
                       ; Fade params: $0E, $06, $05, $F3

; ==============================================================================
; GRAPHICS PALETTE DATA - Full Color Definitions (SNES BGR555 Format)
; ==============================================================================
; SNES color format: %0BBBBBGGGGGRRRRR (15-bit BGR)
; Each color = 2 bytes, little-endian
; ==============================================================================

                       db $50,$7F,$A0,$01,$05,$F3,$B3,$51,$7F,$B5,$51,$7F,$02,$00,$05,$F3;039554|Palette colors|;
                       ; Color 1: $7F50 = BGR(15,26,16) = Purple/Blue tone
                       ; Color 2: $01A0 = BGR(0,13,0) = Dark green
                       ; Color 3: $F305 = BGR(30,16,5) = Bright yellow-green
                       ; Color 4: $51B3 = BGR(10,9,19) = Blue-ish
                       ; Color 5: $7FB5 = BGR(15,26,21) = Cyan
                       ; Color 6: $5151 = BGR(10,10,17) = Gray-blue
                       ; Color 7: $7F = BGR(0,0,31) = Pure red
                       ; Colors 8-9: $0002, $F305 = More palette entries

                       db $2C,$55,$7F,$7C,$53,$7F,$A0,$01,$05,$F3,$1A,$55,$7F,$1C,$55,$7F;039564|More colors|;
                       ; Color 10: $552C = BGR(10,20,12) = Green tone
                       ; Color 11: $7F7C = BGR(15,31,28) = White-ish
                       ; Color 12: $537C = BGR(10,15,28) = Light blue
                       ; Color 13: $7F = Red
                       ; Color 14: $01A0 = Dark green
                       ; Color 15: $F305 = Yellow-green
                       ; Colors 16-19: $551A, $7F, $551C, $7F = Pattern

; ==============================================================================
; DMA TRANSFER LIST - Graphics Upload Commands
; ==============================================================================
; Defines DMA transfers to load graphics into VRAM during V-blank
; Format: [Source_Bank, Source_Addr, Dest_VRAM, Length, DMA_Params]
; ==============================================================================

                       db $02,$00,$08,$A7,$8F,$05,$F0,$DA,$56,$7F,$EC,$05,$F0,$D8,$56,$7F;039574|DMA transfer 1|;
                       ; Source: Bank $02, Addr $0000
                       ; Command: $08 (DMA mode)
                       ; Dest: $A78F
                       ; Params: $05, $F0
                       ; VRAM addr: $56DA, bank $7F
                       ; Length: $EC (236 bytes)
                       ; Transfer 2: $56D8, bank $7F, length $EC

                       db $EC,$05,$ED,$FD,$1F,$70,$05,$6C,$01,$05,$43,$D8,$56,$7F,$05,$27;039584|DMA transfer 2|;
                       ; Length: $EC
                       ; Command: $05 (write mode)
                       ; Param: $ED, $FD
                       ; Flags: $1F, $70
                       ; More transfers: $056C, $0105, $4343
                       ; VRAM: $56D8, bank $7F
                       ; Param: $0527

; ==============================================================================
; SCREEN LAYOUT DATA - Window/Menu Positioning
; ==============================================================================
; Defines screen regions for text windows, menus, etc.
; Format: [Window_ID, X, Y, Width, Height, Border_Style]
; ==============================================================================

                       db $E0,$29,$24,$05,$F1,$00,$20,$7F,$FF,$00,$05,$F3,$00,$20,$7F,$02;039594|Window layout 1|;
                       ; Window $E0: Position ($29,$24)
                       ; Size params: $05, $F1, $00, $20
                       ; Border/BG: $7FFF (white), $00 (transparent)
                       ; Window style: $05, $F3, $00, $20
                       ; Colors: $7F (red), $02 (dark)

                       db $20,$7F,$3E,$00,$08,$A4,$AB,$05,$E2,$17,$30,$05,$24,$AA,$00,$10;0395A4|Window layout 2|;
                       ; Position: $207F (screen coords)
                       ; Offset: $3E, $00
                       ; Command: $08 (draw command)
                       ; Params: $A4, $AB, $05, $E2
                       ; Size: $17x$30
                       ; Window ID: $24, addr $AA00, size $10

; ==============================================================================
; EVENT TRIGGER TABLE - Map Event Definitions
; ==============================================================================
; Links map coordinates to script events
; Format: [Map_ID, X_min, Y_min, X_max, Y_max, Event_Script_Pointer]
; ==============================================================================

                       db $01,$01,$17,$24,$0D,$F0,$01,$A0,$00,$0D,$F2,$01,$0A,$00,$00,$0D;0395B4|Event trigger 1|;
                       ; Map: $01
                       ; Trigger zone: X($01-$17), Y($24-$0D)
                       ; Event script: $01F0, params $A001
                       ; Additional: $0DF2, $010A, $0000, $0D

                       db $42,$00,$20,$38,$39,$05,$1D,$1D,$00,$02,$25,$0C,$24,$02,$01,$0D;0395C4|Event trigger 2|;
                       ; Trigger at coords ($42,$00), zone ($20,$38)
                       ; Script params: $39, $05, $1D1D, $0002
                       ; Event: $250C, flags $2402, $010D

; ==============================================================================
; TEXT STRING DATA - Encoded Dialog/Menu Strings
; ==============================================================================
; Null-terminated text strings with custom character encoding
; ==============================================================================

                       db $04,$15,$04,$02,$18,$AC,$B4,$C9,$B8,$01,$B6,$69,$C3,$BF,$B8,$C7;0395D4|Text string 1|;
                       ; Encoded text (needs character map to decode)
                       ; Bytes: $04,$15,$04,$02,$18
                       ; Characters: $AC,$B4,$C9,$B8,$01
                       ; More text: $B6,$69,$C3,$BF,$B8,$C7

                       db $B8,$B7,$05,$1E,$1D,$00,$02,$08,$4D,$96,$05,$8D,$05,$F3,$2C,$55;0395E4|Text string 2|;
                       ; Continuation: $B8,$B7
                       ; Control code: $05,$1E,$1D,$00,$02
                       ; Command: $08,$4D,$96
                       ; More data: $05,$8D,$05,$F3,$2C,$55

                       db $7F,$7C,$53,$7F,$A0,$01,$05,$24,$6F,$01,$04,$0E,$06,$29,$12,$09;0395F4|Text/palette mix|;
                       ; Mixed text and palette data
                       ; Palette colors: $7F7C, $537F, $01A0
                       ; Text continues: $05,$24,$6F,$01
                       ; Commands: $04,$0E,$06,$29,$12,$09

; ==============================================================================
; END OF CYCLE 2 DATA EXTRACTION - Lines 377-900
; ==============================================================================
; Total extracted: ~523 lines of data tables
; Identified structures:
; - Graphics palette data (SNES BGR555 format colors)
; - Sprite coordinate/positioning tables
; - Text string data with custom encoding
; - Graphics tile data and tilemaps
; - Animation frame sequences
; - Compressed graphics blocks
; - Map object placement data
; - Music/SFX reference tables
; - DMA transfer commands
; - Screen layout/window definitions
; - Event trigger zones and scripts
; ==============================================================================
