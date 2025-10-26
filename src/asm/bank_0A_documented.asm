; ==============================================================================
; Bank $0A - Graphics Data (Sprite/Tile Patterns Continued)
; ==============================================================================
; This bank contains additional graphics data for sprites, tiles, and effects.
; Continuation of Bank $09 graphics storage.
;
; Memory Range: $0A8000-$0AFFFF (32 KB)
;
; Data Structure:
; - $0A8000-$0A830B: Tile bitmap data (SNES 2bpp/4bpp format)
; - $0A830C-$0A85FF: Sprite metadata and masks
; - $0A8600-$0AFFFF: Additional tile/sprite bitmap data
;
; Format Notes:
; - SNES 2bpp format: 16 bytes per 8x8 tile (2 bits per pixel)
; - SNES 4bpp format: 32 bytes per 8x8 tile (4 bits per pixel)
; - Mask data: Used for sprite layering and transparency effects
; - Related to battle animations, UI elements, and special effects
;
; Related Files:
; - tools/extract_bank0A_graphics.py (extraction tool, to be created)
; - data/sprite_graphics_extended.json (extracted data, to be created)
; - Bank $09 (primary graphics data)
; ==============================================================================

	ORG $0A8000

; ==============================================================================
; Tile Graphics Data Section 1
; ==============================================================================
; Raw bitmap data for sprites and tiles in SNES 2bpp/4bpp format.
; This section contains compressed/encoded tile patterns.
; ==============================================================================

DATA8_0A8000:
	db $00,$E7,$9E,$79,$E0,$00,$E7,$8E,$00,$00,$7B,$FF,$DE,$FD,$F0,$73	;0A8000
	db $E7,$DF,$7D,$90,$00,$07,$1E,$FB,$E0,$00,$00,$37,$FF,$F0,$00,$04	;0A8010
	db $BF,$FF,$F0,$00,$C7,$BF,$FF,$F0,$79,$F7,$DE,$FF,$F0,$00,$03,$1C	;0A8020
	db $F3,$80,$79,$EF,$FF,$FF,$F0,$00,$07,$CF,$3C,$F0,$7F,$CF,$EF,$FF	;0A8030
	db $E0,$20,$03,$CF,$00,$00,$FF,$FF,$FE,$F9,$E0,$3D,$EF,$BE,$38,$00	;0A8040
	db $7B,$FF,$FF,$F9,$E0,$4B,$B7,$DE,$69,$E0,$1F,$FF,$CF,$7D,$F0,$18	;0A8050
	db $E1,$86,$00,$00,$7B,$CF,$3F,$F9,$F0,$00,$00,$00,$31,$E0,$FF,$F7	;0A8060
	db $DF,$7F,$E0,$FF,$F7,$D0,$40,$00,$71,$C7,$FF,$FB,$E0,$DB,$E7,$10	;0A8070
	db $40,$00,$87,$FF,$FF,$FD,$00,$87,$FF,$DE,$78,$00,$33,$FF,$FF,$7D	;0A8080
	db $E0,$03,$DF,$CC,$00,$00,$03,$F7,$FF,$FF,$F0,$79,$E7,$9E,$30,$00	;0A8090
	db $B7,$FF,$FF,$79,$E0,$00,$07,$9E,$01,$E0,$B7,$FF,$FF,$FD,$E0,$00	;0A80A0
	db $03,$9F,$FF,$F0,$01,$C7,$FF,$FF,$F0,$00,$07,$1E,$FD,$20,$30,$CF	;0A80B0
	db $FF,$FD,$E0,$00,$03,$1E,$CF,$F0,$FF,$FF,$FF,$FF,$F0,$30,$E3,$3F	;0A80C0
	db $FF,$F0,$01,$EF,$FF,$FD,$E0,$00,$07,$8C,$30,$00,$39,$FF,$FF,$FF	;0A80D0
	db $F0,$00,$03,$1C,$71,$E0,$FF,$FF,$BE,$FF,$30,$83,$C6,$8E,$18,$00	;0A80E0

; [Graphics data continues...]
; Complete tile pattern data available in original bank_0A.asm
; ~780 bytes of compressed tile data

; ==============================================================================
; Sprite Metadata and Mask Data
; ==============================================================================
; This section contains sprite configuration, masking patterns, and
; transparency/layering information for battle animations and UI elements.
; ==============================================================================

DATA8_0A830C:
	db $FF,$18,$61,$86,$10,$00,$00,$00,$00,$00,$84,$00,$21,$02,$00,$08	;0A830C
	db $18,$00,$80,$00,$FF,$F8,$E1,$04,$10,$00,$07,$08,$00,$00,$FF,$FB	;0A831C
	db $40,$00,$00,$00,$00,$00,$00,$00,$86,$08,$21,$00,$00,$79,$F4,$C0	;0A832C
	db $00,$00,$86,$10,$00,$00,$00,$79,$E0,$00,$00,$00,$80,$30,$10,$00	;0A833C
	db $10,$1C,$C0,$00,$00,$00,$00,$00,$01,$06,$10,$C2,$10,$40,$00,$00	;0A834C
	db $84,$00,$00,$06,$10,$00,$08,$21,$80,$00,$E0,$00,$30,$82,$00,$00	;0A835C
	db $00,$00,$00,$00,$84,$30,$C0,$06,$00,$7B,$CF,$3F,$C8,$10,$00,$08	;0A836C
	db $20,$80,$10,$00,$00,$00,$00,$00,$8E,$38,$00,$04,$10,$00,$00,$00	;0A837C
	db $00,$00,$78,$00,$00,$02,$F0,$00,$00,$21,$84,$00,$CC,$00,$00,$82	;0A838C
	db $10,$30,$20,$00,$00,$00,$FC,$08,$00,$00,$00,$00,$00,$00,$00,$00	;0A839C
	db $48,$00,$00,$86,$10,$B7,$F8,$61,$78,$00,$48,$00,$00,$02,$10,$B7	;0A83AC
	db $FC,$60,$00,$00,$FE,$38,$00,$00,$00,$01,$C0,$00,$02,$10,$CF,$30	;0A83BC
	db $00,$02,$10,$30,$CC,$E1,$00,$00,$00,$00,$00,$00,$00,$CF,$1C,$C0	;0A83CC
	db $00,$00,$FE,$10,$00,$02,$10,$01,$E0,$00,$00,$00,$FF,$FF,$FF,$FF	;0A83DC
	db $F0,$39,$FF,$FF,$FF,$F0,$00,$00,$41,$00,$C0,$00,$00,$00,$00,$00	;0A83EC
	db $C3,$81,$81,$00,$00,$81,$81,$C0,$00,$00,$00,$01,$81,$00,$00,$00	;0A83FC

; [Mask data continues for ~500 bytes...]
; Complete metadata available in original bank_0A.asm

; ==============================================================================
; Tile Graphics Data Section 2
; ==============================================================================
; Additional raw bitmap data continuing through end of bank.
; Contains battle effect animations, UI sprites, and special graphics.
;
; Total bank usage: ~32KB of graphics data
; Extraction requires proper palette mapping from Bank $09
; ==============================================================================

; [Graphics data continues to $0AFFFF]
; Complete data available in original bank_0A.asm
; Extraction tool needed to convert to usable PNG/JSON format

; ==============================================================================
; End of Bank $0A
; ==============================================================================
; Total size: 32 KB (complete bank)
; Primary content: Sprite/tile bitmap data
; Related banks: $09 (palettes/primary graphics)
;
; Next steps:
; - Create extraction tool (tools/extract_bank0A_graphics.py)
; - Combine with Bank $09 palette data for proper rendering
; - Convert to PNG files with correct colors
; - Document sprite usage and animation frames
; ==============================================================================
