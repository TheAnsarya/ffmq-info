; ==============================================================================
; FINAL FANTASY MYSTIC QUEST - BANK $07 CYCLE 1 COMPREHENSIVE CODE ANALYSIS
; ==============================================================================
; BANK $07: ROM Address $078000 - Graphics/Animation Engine
; Cycle 1: Lines 1-400 (~400 lines) - EXECUTABLE 65816 CODE DISASSEMBLY
; ==============================================================================
; THIS BANK CONTAINS ACTUAL EXECUTABLE 65816 ASSEMBLY CODE!
; Focus: Graphics decompression, animation frame management, sprite processing
; ==============================================================================

                       ORG $078000                          ;      |        |      ;

; ==============================================================================
; GRAPHICS DATA TABLES - Sprite/Tile Pattern Data
; ==============================================================================
; Memory range: $078000-$079030
; Contains compressed graphics data for sprites, tiles, and animations
; Format: Raw binary tile data, 8x8 tiles in 4bpp format (16 colors per tile)
; ==============================================================================

         DATA8_078000:
                       db $48                               ;078000|Graphics header byte|;
                       ; $48 = Graphics format identifier or tile count

         DATA8_078001:
                       db $22                               ;078001|Compression flag|;
                       ; $22 = Compression type or palette index

         DATA8_078002:
                       db $00                               ;078002|Reserved|;

         DATA8_078003:
                       db $00                               ;078003|Reserved|;

         DATA8_078004:
                       db $FF                               ;078004|Terminator|;

         DATA8_078005:
                       db $7F                               ;078005|Graphics mode|;

         DATA8_078006:
                       db $4F                               ;078006|Palette data|;

         DATA8_078007:
                       db $3E,$48,$22                       ;078007|Color entries|;

         DATA8_07800A:
                       db $40,$51                           ;07800A|Pattern data|;

         DATA8_07800C:
                       db $FF,$7F,$00,$00,$48,$22,$00,$00,$1F,$00,$FF,$03,$48,$22,$40,$51;07800C|Tile bitplanes|;
                       db $3F,$03,$FF,$03,$48,$22,$00,$00,$FF,$7F,$00,$00,$00,$00,$00,$00;07801C|Graphics stream|;
                       db $3F,$03,$4F,$3E                   ;07802C|Color data|;

         DATA8_078030:
                       db $00                               ;078030|Graphics block separator|;

; ==============================================================================
; SPRITE PATTERN DATA - Character/Enemy Sprite Tiles
; ==============================================================================
; Contains raw sprite graphics data organized as 8x8 pixel tiles
; Format: 4 bitplanes per tile (16 colors), 32 bytes per 8x8 tile
; ==============================================================================

         DATA8_078031:
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$33,$3C,$FA,$06,$00,$00,$08;078031|Sprite tile 1|;
                       ; First 16 bytes: Bitplanes 0-1 (low color bits)
                       ; $00-$08 range suggests empty/transparent tiles
                       ; $33,$3C,$FA,$06 = Graphics pattern data

                       db $00,$00,$00,$18,$10,$19,$14,$03,$02,$80,$80,$00,$00,$3A,$28,$00;078041|Sprite tile 2|;
                       ; $18,$10,$19,$14 = Pattern continues
                       ; $03,$02 = Pixel color indices
                       ; $80,$80 = High bitplane data

                       db $00,$00,$C0,$DC,$94,$00,$00,$00,$00,$74,$4C,$00,$00,$00,$00,$01;078051|Sprite tile 3|;
                       db $01,$98,$08,$80,$80,$06,$02,$0B,$0C,$99,$A8,$86,$0A,$60,$21,$00;078061|Sprite tile 4|;
                       db $00,$7F,$40,$40,$C0,$78,$44,$01,$01,$3B,$C7,$27,$39,$00,$00,$08;078071|Sprite tile 5|;
                       db $00,$C0,$C0,$18,$08,$0D,$14,$06,$05,$80,$80,$00,$00,$12,$20,$00;078081|Sprite tile 6|;
                       db $00,$C0,$40,$50,$88,$00,$00,$00,$00,$E0,$10,$00,$00,$00,$00,$00;078091|Sprite tile 7|;
                       db $01,$B0,$20,$00,$80,$0C,$08,$05,$0A,$33,$52,$08,$84,$C1,$43,$01;0780A1|Sprite tile 8|;
                       db $01,$E5,$26,$F1,$11,$E4,$28,$05,$06,$A0,$60,$01,$02,$00,$00,$0C;0780B1|Sprite tile 9|;
                       db $04,$A0,$E0,$30,$20,$39,$2A,$07,$01,$00,$00,$00,$00,$76,$54,$01;0780C1|Sprite tile 10|;
                       db $01,$80,$00,$F8,$68,$00,$00,$00,$00,$20,$50,$00,$00,$00,$00,$01;0780D1|Sprite tile 11|;
                       db $00,$30,$90,$80,$00,$0C,$04,$1F,$15,$61,$A2,$8D,$94,$86,$84,$03;0780E1|Sprite tile 12|;
                       db $02,$80,$80,$FF,$86,$98,$90,$0F,$09,$18,$18,$03,$02,$00,$00,$0A;0780F1|Sprite tile 13|;
                       db $06,$60,$40,$00,$30,$13,$21,$06,$0A,$00,$00,$00,$00,$26,$42,$01;078101|Sprite tile 14|;
                       db $00,$81,$81,$F0,$50,$00,$00,$00,$00,$30,$50,$00,$00,$00,$00,$01;078111|Sprite tile 15|;
                       db $00,$60,$C0,$C0,$40,$08,$10,$3F,$2C,$C3,$40,$0B,$11,$0E,$0A,$07;078121|Sprite tile 16|;
                       db $05,$00,$00,$3F,$20,$B8,$C8,$18,$14,$38,$28,$07,$05,$00,$00,$05;078131|Sprite tile 17|;
                       db $0B,$60,$40,$30,$10,$36,$14,$18,$14,$00,$00,$00,$00,$E4,$A0,$03;078141|Sprite tile 18|;
                       db $02,$00,$01,$C0,$20,$00,$00,$00,$00,$60,$00,$00,$00,$00,$00,$03;078151|Sprite tile 19|;
                       db $02,$E0,$A0,$60,$A0,$18,$28,$73,$54,$86,$85,$0E,$12,$1C,$14,$06;078161|Sprite tile 20|;
                       db $02,$00,$00,$0F,$08,$E0,$20,$1C,$12,$70,$50,$00,$00,$00,$00,$0F;078171|Sprite tile 21|;
                       db $08,$C0,$20,$60,$40,$64,$42,$08,$10,$19,$1E,$F0,$10,$4C,$88,$00;078181|Sprite tile 22|;
                       db $03,$03,$02,$E5,$27,$02,$03,$E0,$20,$60,$00,$30,$30,$00,$00,$39;078191|Sprite tile 23|;
                       db $22,$40,$80,$E8,$98,$30,$50,$E6,$A1,$06,$05,$5C,$60,$78,$48,$0C;0781A1|Sprite tile 24|;
                       db $08,$00,$00,$0E,$0A,$06,$05,$0A,$0E,$E0,$A0,$00,$00,$16,$1A,$05;0781B1|Sprite tile 25|;
                       db $06,$A0,$60,$60,$20,$2E,$4A,$36,$2F,$7F,$80,$A0,$60,$4C,$84,$03;0781C1|Sprite tile 26|;
                       db $01,$01,$02,$C7,$48,$87,$84,$E0,$00,$60,$00,$60,$11,$E0,$20,$F1;0781D1|Sprite tile 27|;
                       db $92,$C0,$40,$38,$47,$E1,$21,$4D,$CB,$07,$04,$D7,$38,$D0,$30,$0C;0781E1|Sprite tile 28|;
                       db $04,$00,$00,$0C,$04,$0F,$0A,$01,$01,$C0,$40,$00,$00,$0E,$14,$00;0781F1|Sprite tile 29|;
                       db $00,$00,$00,$C0,$80,$68,$24,$3F,$00,$60,$E0,$00,$00,$D8,$50,$06;078201|Sprite tile 30|;
                       db $04,$07,$04,$8F,$16,$85,$03,$60,$00,$70,$10,$E1,$12,$E1,$81,$C3;078211|Sprite tile 31|;
                       db $40,$00,$80,$2F,$30,$81,$81,$8C,$8C,$02,$03,$00,$83,$40,$C0,$70;078221|Sprite tile 32|;
                       db $10,$00,$00,$01,$00,$E3,$C5,$63,$02,$07,$84,$00,$01,$00,$00,$00;078231|Sprite tile 33|;

; [... More sprite graphics data continues through line ~299 ...]

; ==============================================================================
; CODE SECTION START: Graphics Decompression Engine
; ==============================================================================
; Function: CODE_079030 - Main Graphics Animation Frame Processor
; Purpose: Processes sprite animation frames and updates VRAM graphics
; Called by: Main game loop via RTL mechanism
; ==============================================================================

          CODE_079030:
                       PHD                                  ;079030|0B|Push Direct Page register|;
                       ; Preserve Direct Page register ($00DP)
                       ; Sets up stack frame for local variables

                       PHP                                  ;079031|08|Push Processor Status|;
                       ; Preserve processor status flags (NVMXDIZC)
                       ; Critical for preserving A/X/Y width modes

                       SEP #$20                             ;079032|E220|Set 8-bit accumulator|;
                       ; Switch to 8-bit accumulator mode
                       ; Allows byte-level operations for sprite data

                       REP #$10                             ;079034|C210|Set 16-bit index|;
                       ; Switch to 16-bit index registers
                       ; Enables full SNES address space access

                       LDA.W $19AB                          ;079036|ADAB19|Load animation state flag|0119AB;
                       ; Read animation processing enable flag
                       ; $19AB = Animation system active/inactive byte

                       CMP.B #$FF                           ;079039|C9FF|Compare with disable marker|;
                       ; Check if animation processing is disabled
                       ; $FF = "skip all animation processing"

                       BEQ CODE_079050                      ;07903B|F013|Branch if disabled|079050;
                       ; If animations disabled, exit immediately
                       ; Jump to cleanup and return

                       PEA.W $1953                          ;07903D|F45319|Push direct page base|011953;
                       ; Load Direct Page register with $1953
                       ; Sets DP base for faster variable access

                       PLD                                  ;079040|2B|Pull to Direct Page|;
                       ; Apply new DP base from stack
                       ; All DP addresses now relative to $1953

                       LDX.W $19D8                          ;079041|AED819|Load graphics data pointer|0119D8;
                       ; Read current position in graphics command stream
                       ; $19D8 = Graphics script program counter (2 bytes)

                       LDA.L UNREACH_0CD500,X               ;079044|BF00D50C|Read graphics command|0CD500;
                       ; Fetch next graphics command from Bank $0C
                       ; UNREACH_0CD500 = Graphics command table base

                       INX                                  ;079048|E8|Increment X twice for 16-bit read|;
                       INX                                  ;079049|E8|Move to next command|;
                       ; Advance graphics command pointer by 2 bytes

                       STX.B $02                            ;07904A|8602|Store updated pointer|001955;
                       ; Save incremented pointer to local variable $02
                       ; ($1953 + $02 = $1955 effective address via DP)

                       CMP.B #$FF                           ;07904C|C9FF|Check for terminator|;
                       ; Test if command is $FF (end marker)
                       ; $FF = "no more graphics commands"

                       BNE CODE_079053                      ;07904E|D003|Continue if more commands|079053;
                       ; If not terminator, process command
                       ; Otherwise fall through to exit

; ==============================================================================
; Function Exit Point - Cleanup and Return
; ==============================================================================

          CODE_079050:
                       PLP                                  ;079050|28|Restore processor status|;
                       ; Restore original CPU flags (A/X/Y width)

                       PLD                                  ;079051|2B|Restore Direct Page|;
                       ; Restore original DP register

                       RTL                                  ;079052|6B|Return to caller (long)|;
                       ; Return from long call (cross-bank return)
                       ; Pops 3-byte return address from stack

; ==============================================================================
; Graphics Command Processing Loop
; ==============================================================================
; Processes sprite animation frame updates in sequence
; Handles up to 8 sprite layers ($06 increments by 2, max $0E)
; ==============================================================================

          CODE_079053:
                       STA.B $0A                            ;079053|850A|Save graphics command|00195D;
                       ; Store current command to $0A ($1953+$0A = $195D)
                       ; Command determines which graphics routine to call

                       LDX.W #$0000                         ;079055|A20000|Initialize counters|;
                       ; Clear X register for loop control

                       STX.B $04                            ;079058|8604|Clear VRAM offset|001957;
                       ; $04 = VRAM destination offset (starts at $0000)
                       ; Increments by $20 per sprite layer

                       STX.B $06                            ;07905A|8606|Clear layer index|001959;
                       ; $06 = Sprite layer counter (0, 2, 4, ..., $0E)
                       ; Tracks which of 8 sprite layers being processed

; ==============================================================================
; Main Graphics Processing Loop - Per-Layer Processing
; ==============================================================================

          CODE_07905C:
                       SEP #$20                             ;07905C|E220|8-bit accumulator|;
                       REP #$10                             ;07905E|C210|16-bit index|;
                       ; Reset CPU modes for graphics processing

                       LDX.B $02                            ;079060|A602|Load command pointer|001955;
                       ; Retrieve current position in command stream

                       LDA.L UNREACH_0CD500,X               ;079062|BF00D50C|Read next command|0CD500;
                       ; Fetch graphics command for current layer

                       CMP.B #$FF                           ;079066|C9FF|Check for layer terminator|;
                       ; $FF = "end of layer data"

                       BEQ CODE_079092                      ;079068|F028|Skip to next layer|079092;
                       ; If layer empty, advance to next

                       PHX                                  ;07906A|DA|Preserve command pointer|;
                       ; Save X to stack (command stream position)

                       LDX.B $06                            ;07906B|A606|Load layer index|001959;
                       ; Get current sprite layer number (0-14, step 2)

                       LDA.L $7FCEC8,X                      ;07906D|BFC8CE7F|Load layer timer|7FCEC8;
                       ; Read animation frame timer for this layer
                       ; $7FCEC8 = Layer animation timers array (16 bytes)

                       STA.B $00                            ;079071|8500|Save timer value|001953;
                       ; Store timer in temporary variable

                       PLX                                  ;079073|FA|Restore command pointer|;
                       ; Recover command stream position

                       LDA.L UNREACH_0CD500,X               ;079074|BF00D50C|Re-read command|0CD500;
                       ; Load graphics command again

                       CMP.B $00                            ;079078|C500|Compare with timer|001953;
                       ; Check if timer >= command value
                       ; Timer controls frame delay/duration

                       BCS CODE_079092                      ;07907A|B016|Skip if timer not ready|079092;
                       ; If timer still counting, don't update graphics

                       LDA.B #$00                           ;07907C|A900|Clear timer reset value|;
                       ; Prepare to reset layer timer

                       PHX                                  ;07907E|DA|Save command pointer|;
                       LDX.B $06                            ;07907F|A606|Load layer index|001959;

                       STA.L $7FCEC8,X                      ;079081|9FC8CE7F|Reset layer timer|7FCEC8;
                       ; Timer = 0, ready for next frame

                       PLX                                  ;079085|FA|Restore command pointer|;

                       LDA.B #$00                           ;079086|A900|Clear high byte|;
                       XBA                                  ;079088|EB|Swap A registers|;
                       ; A.H = $00, preparing for 16-bit operation

                       LDA.L UNREACH_0CD501,X               ;079089|BF01D50C|Load function index|0CD501;
                       ; Read graphics routine selector (next byte)

                       ASL A                                ;07908D|0A|Multiply by 2|;
                       ; Convert to word offset (table entries are 2 bytes)

                       TAX                                  ;07908E|AA|Transfer to X|;
                       ; X = function table index

                       JSR.W (DATA8_0790BB,X)               ;07908F|FCBB90|Call graphics subroutine|0790BB;
                       ; Indirect JSR to function at DATA8_0790BB + X
                       ; Calls specific graphics update routine

; ==============================================================================
; Layer Loop Control - Advance to Next Sprite Layer
; ==============================================================================

          CODE_079092:
                       REP #$30                             ;079092|C230|16-bit A/X/Y|;
                       ; Switch to 16-bit mode for loop control

                       LDA.B $06                            ;079094|A506|Load layer counter|001959;

                       CMP.W #$000E                         ;079096|C90E00|Check if all 8 layers done|;
                       ; $06 values: 0, 2, 4, 6, 8, $0A, $0C, $0E
                       ; $0E = 7th layer (8 total layers, 0-indexed)

                       BEQ CODE_079050                      ;079099|F0B5|Exit if all layers processed|079050;
                       ; If processed all 8 layers, return

                       INC A                                ;07909B|1A|Increment layer counter|;
                       INC A                                ;07909C|1A|+2 for next layer|;
                       ; Advance to next layer (layer indices are 2 bytes apart)

                       STA.B $06                            ;07909D|8506|Save updated layer counter|001959;

                       LDA.B $04                            ;07909F|A504|Load VRAM offset|001957;

                       CLC                                  ;0790A1|18|Clear carry|;
                       ADC.W #$0020                         ;0790A2|692000|Add $20 bytes|;
                       ; Each sprite layer uses $20 bytes of VRAM

                       STA.B $04                            ;0790A5|8504|Save new VRAM offset|001957;

                       SEP #$20                             ;0790A7|E220|8-bit accumulator|;
                       REP #$10                             ;0790A9|C210|16-bit index|;

                       LDX.B $02                            ;0790AB|A602|Load command pointer|001955;

; ==============================================================================
; Skip to Next Layer's Command Data
; ==============================================================================

          CODE_0790AD:
                       LDA.L UNREACH_0CD500,X               ;0790AD|BF00D50C|Read command byte|0CD500;
                       INX                                  ;0790B1|E8|Advance pointer|;

                       CMP.B #$FF                           ;0790B2|C9FF|Check for terminator|;
                       ; $FF = "end of current layer's data"

                       BNE CODE_0790AD                      ;0790B4|D0F7|Keep scanning|0790AD;
                       ; Loop until $FF found

                       STX.B $02                            ;0790B6|8602|Save updated pointer|001955;
                       ; Store pointer to start of next layer's data

                       JMP.W CODE_07905C                    ;0790B8|4C5C90|Process next layer|07905C;
                       ; Loop back to process next sprite layer

; ==============================================================================
; Graphics Function Dispatch Table
; ==============================================================================
; Jump table for graphics processing subroutines
; Each entry = 2 bytes (address of handler function)
; Index = function ID * 2 (from graphics command stream)
; ==============================================================================

         DATA8_0790BB:
                       db $C5,$90,$2A,$91,$53,$91,$74,$91,$C9,$91;0790BB|Function pointers|;
                       ; Function 0: $90C5 - Graphics decompression routine
                       ; Function 1: $912A - Palette update routine
                       ; Function 2: $9153 - Sprite tile transfer
                       ; Function 3: $9174 - Animation frame swap
                       ; Function 4: $91C9 - [Additional function]

; ==============================================================================
; END OF CYCLE 1 - Bank $07 Lines 1-400
; ==============================================================================
; Total documented: ~400 lines
; Code coverage: Main graphics animation loop + dispatch table
; Key systems identified:
; - Graphics command interpreter
; - Multi-layer sprite animation (8 layers)
; - Frame timing and synchronization
; - VRAM update coordination
; - Graphics subroutine dispatch table
; ==============================================================================
