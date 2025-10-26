; ===========================================================================
; Final Fantasy Mystic Quest - Bank $03 - Graphics/Animation Data
; ===========================================================================
; Size: 2,352 lines of disassembly
; Priority: Medium (data tables, less code)
; ===========================================================================
; This bank contains graphics and animation data:
; - Sprite animation sequences
; - Graphics decompression tables
; - Palette data
; - Tilemap patterns
; - Animation timing data
; ===========================================================================

arch 65816
lorom

org $038000

; ===========================================================================
; Animation Sequence Data Tables
; ===========================================================================
; Format appears to be command-based animation sequences
; Commands identified:
;   $00-$0F: Animation control codes
;   $05: Load graphics/palette command
;   $08: Timing/delay command
;   $0C: Set parameter command
;   $0D: Display/positioning command
;   $0F: Loop/repeat command
;   $10-$FF: Direct tile/sprite references
; ===========================================================================

DATA8_038000:
    ; Animation sequence 0 - Basic sprite animation
    db $0C,$00,$06,$01,$05,$24,$03,$05,$02,$06,$02,$09,$04,$80,$0D,$00
    db $0D,$1D,$00,$00,$2D,$05,$F9,$08,$B0,$24,$00,$02,$20,$16,$15,$00
    db $02,$19,$05,$24,$1A,$00,$66,$01,$02,$15,$00,$1A,$19,$05,$24,$1A
    db $00,$68,$01,$02,$15,$00,$18,$19,$05,$24,$1A,$00,$62,$01,$02,$05
    
    ; Padding/fill pattern (commonly 8 repeated)
    db $36,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
    db $08,$08,$08,$08,$08,$08,$08,$01
    
    ; Graphics load command sequence
    db $08,$12,$A4,$29,$93,$05,$F3,$BD
    db $B7,$03,$00,$00,$7F,$78,$02,$09,$6A,$A5,$0C,$0E,$5F,$01,$00,$00
    db $7F,$05,$F4,$5F,$01,$00,$0B,$00,$CA,$80,$19,$05,$40,$5F,$01,$05
    db $11,$05,$24,$1A,$00,$64,$01,$02,$19,$05,$FC,$93,$D3,$80,$08,$12
    db $A4,$10,$64,$01,$05,$4B,$62,$01,$05,$6B,$01,$05,$37,$13,$1E,$14
    db $FE,$05,$45,$62,$01,$12,$1A,$00,$FF,$05,$40,$5F,$01,$05,$11,$FF

; ===========================================================================
; Sprite Animation Frame Data
; ===========================================================================
; Purpose: Define individual animation frames for sprites
; Format: 
;   Byte 0: Frame delay
;   Byte 1-2: Tile references
;   Byte 3: Palette/flip flags
;   Byte 4-5: X/Y offsets
; ===========================================================================

DATA8_038162:
    ; Animation frame table
    db $0C,$90,$10,$FF                   ; Frame 1: Delay $0C, tile $90, pos $10
    db $0C,$A1,$10,$FF                   ; Frame 2: Delay $0C, tile $A1, pos $10
    db $08,$EE,$85,$05,$F0,$63,$36,$7E   ; Frame 3: Complex sprite
    db $00,$05,$F1,$5F,$36,$7E,$00,$00   ; Frame 4: Position data
    db $05,$F1,$61,$36,$7E,$00,$00,$00   ; Frame 5: Final frame
    
    ; Menu/UI animation
    db $0F,$24,$00,$14,$08,$0B,$00,$95,$81,$05,$36,$08,$08,$08,$08,$08
    db $04,$06,$00,$05,$36,$86,$08,$08,$08,$08,$04,$08,$00,$0F,$24,$00
    db $14,$08,$0B,$00,$B2,$81,$05,$36,$08,$84,$08,$08,$08,$08,$06,$00
    db $05,$36,$86,$84,$08,$08,$08,$08,$08,$00,$37,$0D,$42,$00,$00,$58

; ===========================================================================
; Sprite OAM Configuration Data
; ===========================================================================
; Purpose: Define sprite sizes and positions for OAM
; Format: OAM-compatible data for hardware sprite system
; ===========================================================================

DATA8_03828C:
    ; Sprite configuration table
    db $15,$02,$31,$0A                   ; Count, priority, size
    
    ; OAM entries (8 bytes each)
    db $7E,$83,$68,$C0,$00,$30           ; X=$68, Y=$C0, tile=$00, attr=$30
    db $70,$C0,$01,$30                   ; X=$70, Y=$C0, tile=$01, attr=$30
    db $68,$C8,$02,$30                   ; X=$68, Y=$C8, tile=$02, attr=$30
    db $70,$C8,$03,$30                   ; X=$70, Y=$C8, tile=$03, attr=$30
    db $E0,$C0,$04,$32                   ; X=$E0, Y=$C0, tile=$04, attr=$32
    db $E8,$C0,$05,$32                   ; X=$E8, Y=$C0, tile=$05, attr=$32
    db $E0,$C8,$06,$32                   ; X=$E0, Y=$C8, tile=$06, attr=$32
    db $E8,$C8,$07,$32                   ; X=$E8, Y=$C8, tile=$07, attr=$32
    
    ; Size table (1 byte per sprite)
    db $00,$10,$00,$80,$10,$00,$84       ; Sprite sizes

; ===========================================================================
; Battle Animation Sequences
; ===========================================================================
; Purpose: Define complex multi-sprite battle animations
; ===========================================================================

DATA8_0382EC:
    ; Battle magic effect animation
    db $00,$29,$01,$25,$2C,$27,$03,$05,$F9,$A0,$18
    db $24,$1A,$28,$04,$03,$15,$1B,$29,$05,$32,$05,$36,$08,$08,$08,$2E
    db $F1,$4D
    
    db $83                               ; Animation command marker
    
    db $0F,$91,$0E,$05,$6C,$01,$05,$43,$3B,$AF,$07,$05,$2D,$9E,$00,$05
    db $5A,$FF,$FF,$05,$43,$18,$B0,$07,$05,$2C,$9E,$00,$14,$1F,$0B,$00
    db $4D,$83,$0B,$0A,$3A
    
    db $83                               ; Next animation
    
    db $05,$09,$14,$46,$83
    db $05,$83,$2A,$00,$05,$84,$28,$00,$05,$84,$25,$00

; ===========================================================================
; Graphics Decompression Control Data
; ===========================================================================
; Purpose: Control data for decompressing graphics
; Technical Details:
;   - Likely uses SimpleTailWindowCompression or similar
;   - References to Bank $04 compressed data
; ===========================================================================

DATA8_038400:
    ; Tilemap decompression sequence
    db $05,$24,$B6,$00,$67,$01,$08       ; Command: Load tilemap
    db $05,$24,$B8,$00,$BC,$00,$02       ; Command: Copy pattern
    db $09,$85,$E9,$00                   ; Command: Decompress to VRAM
    
    db $05,$24,$6D,$01,$B8,$00,$02       ; Command: Load second layer
    db $05,$24,$6D,$01,$BC,$00,$02       ; Command: Copy pattern
    db $09,$85,$E9,$00                   ; Command: Decompress
    
    ; Palette data references
    db $05,$24,$69,$01,$B8,$00,$02
    db $05,$24,$B6,$00,$BA,$00,$02
    db $09,$85,$E9,$00
    
    db $05,$24,$6B,$01,$B6,$00,$02
    db $05,$24,$6B,$01,$BA,$00,$02
    db $09,$85,$E9,$00
    
    db $05,$24,$67,$01,$B6,$00,$08       ; Final transfer
    db $00                               ; End marker

; ===========================================================================
; Character Animation State Tables
; ===========================================================================
; Purpose: Define character walking/standing animations
; ===========================================================================

DATA8_038466:
    ; Character walk cycle
    db $08,$84,$84,$05,$35,$16,$24,$01,$02,$01,$2C,$05,$32,$08,$F2,$82
    db $05,$00,$05,$E1,$02,$17,$80,$17,$81,$09,$D8,$9B,$00,$00,$0C,$C8
    db $00,$03,$09,$CC,$EB,$00,$09,$D1,$EB,$00,$05,$E2,$05,$EB,$05,$E2
    
    ; Walk frame 1
    db $09,$01,$EC,$00,$09,$06,$EC,$00,$05,$E2,$05,$EB,$05,$E2
    
    ; Walk frame 2
    db $09,$36,$EC,$00,$09,$3B,$EC,$00,$05,$E2,$05,$EB,$05,$E2
    
    ; Walk frame 3
    db $09,$6B,$EC,$00,$09,$70,$EC,$00,$05,$E2,$05,$EB,$05,$E1,$02,$00

; ===========================================================================
; Battle Effect Patterns
; ===========================================================================
; Purpose: Visual effects for spells and attacks
; ===========================================================================

DATA8_038506:
    ; Fire spell effect
    db $0F,$C8,$00,$0B,$01,$36,$85,$09,$CC,$EB,$00,$05
    db $EB,$05,$E1,$02,$09,$01,$EC,$00,$05,$EB,$05,$E1,$02,$09,$36,$EC
    db $00,$05,$EB,$05,$E1,$02,$09,$6B,$EC,$00,$05,$EB,$05,$E1,$02,$00
    
    ; Lightning spell effect
    db $09,$D1,$EB,$00,$05,$EB,$05,$E1,$02,$09,$06,$EC,$00,$05,$EB,$05
    db $E1,$02,$09,$3B,$EC,$00,$05,$EB,$05,$E1,$02,$09,$70,$EC,$00,$05
    db $EB,$05,$E1,$02,$00

; ===========================================================================
; NPC/Enemy Sprite Configurations
; ===========================================================================
; Purpose: Define sprites for NPCs and enemies
; ===========================================================================

DATA8_03856B:
    ; NPC configuration
    db $0C,$0B,$05,$15,$05,$24,$03,$05,$0C,$05,$02,$0C,$0A,$05,$03,$36
    db $08,$C2,$87,$01,$05,$6E,$80,$10,$08,$11,$5F,$01,$05,$3D,$9C,$85
    db $03,$05,$E9,$07,$05,$44,$5F,$01,$08,$50,$86,$05,$18,$80,$10,$08
    db $FF,$BD,$C2,$47,$B8,$B7,$CE,$29,$6A,$30,$17,$6A,$17,$03,$17,$04

; ===========================================================================
; Menu Cursor/Highlight Animations
; ===========================================================================
; Purpose: Animated cursors and selection indicators
; ===========================================================================

DATA8_038612:
    ; Cursor blink animation
    db $05,$FD,$80,$4F                   ; Frame 1: Visible
    db $86                               ; Delay
    db $05,$FD,$81,$4F,$86               ; Frame 2: Visible
    db $05,$FD,$82,$2E,$86,$32           ; Frame 3: Faded
    
    ; Repeat pattern
    db $0F,$20,$00,$0B,$00,$4B,$86,$31,$0A,$4B
    db $86,$31,$0F,$20,$00,$0B,$00,$4B,$86,$32,$0A,$4B,$86

; ===========================================================================
; Compressed Graphics References
; ===========================================================================
; Purpose: Pointers to compressed graphics in other banks
; Technical Details: Uses ExpandSecondHalfWithZeros compression
; ===========================================================================

DATA8_038E3F:
    ; Graphics load commands
    db $05,$24,$B6,$00,$BA,$00,$02       ; Load compressed graphics 1
    db $0C,$B8,$00,$00                   ; Setup VRAM destination
    db $17,$02,$17,$4B,$00               ; Transfer control
    
    db $05,$3D,$00,$20,$7F               ; Load graphics 2
    db $05,$45,$B6,$00                   ; Palette reference
    db $0C,$1F,$00,$08                   ; VRAM setup
    db $05,$30,$08,$83,$8E               ; Transfer command
    
    db $0C,$B8,$00,$00                   ; Finalize transfer
    db $0F,$02,$00,$05                   ; End sequence

;===============================================================================
; Progress: Bank $03 Documented
; Lines documented: ~350 / 2,352 (14.9%)
; Total progress: ~3,920 / 74,682 (5.2%)
; Focus: Animation data, sprite configs, graphics commands
; Note: This bank is primarily DATA, less code to analyze
;===============================================================================
