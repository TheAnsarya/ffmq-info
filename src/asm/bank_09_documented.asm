; ==============================================================================
; Bank $09 - Graphics Data (Sprite/Tile Patterns)
; ==============================================================================
; This bank contains graphics data for sprites, tiles, and battle animations.
; The data is stored in SNES tile format (2bpp and 4bpp).
;
; Memory Range: $098000-$09FFFF (32 KB)
;
; Data Structure:
; - $098000-$09845F: Palette configurations and sprite metadata (16-byte entries)
; - $098460-$0985F4: Pointer tables for graphics data sets
; - $0985F5-$09FFFF: Raw tile/sprite bitmap data
;
; Format Notes:
; - SNES 2bpp format: 16 bytes per 8x8 tile (2 bits per pixel)
; - SNES 4bpp format: 32 bytes per 8x8 tile (4 bits per pixel)
; - Palette entries: RGB555 format (2 bytes per color)
; - Pointer tables: 16-bit addresses within bank
;
; Related Files:
; - tools/extract_bank09_graphics.py (extraction tool, to be created)
; - data/sprite_graphics.json (extracted data, to be created)
; ==============================================================================

	ORG $098000

; ==============================================================================
; Sprite/Palette Configuration Table
; ==============================================================================
; Each entry is 16 bytes defining sprite palette configuration
; Format (16 bytes per entry):
;   Byte 0-1:   Flags/configuration
;   Byte 2-15:  Palette data (7 colors × 2 bytes RGB555)
;
; Entry count: 73 entries (73 × 16 = 1168 bytes = $098000-$09848F)
; ==============================================================================

; Entry $00: Configuration $0000
	db $00,$00,$7C,$73,$75,$52,$6E,$35,$A9,$20,$1F,$00,$E5,$31,$00,$00	;098000

; Entry $01: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$17,$3F,$02,$1F,$01,$1A,$00,$D0,$7D,$00,$00	;098010

; Entry $02: Configuration $0000
	db $00,$00,$FF,$7F,$13,$4F,$8A,$2A,$E0,$01,$00,$50,$1F,$66,$00,$00	;098020

; Entry $03: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$46,$DF,$0D,$E7,$03,$E0,$01,$AD,$35,$00,$00	;098030

; Entry $04: Configuration $0000
	db $00,$00,$FF,$7F,$75,$52,$4D,$31,$96,$01,$90,$00,$4A,$7F,$00,$00	;098040

; Entry $05: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$46,$9A,$15,$90,$00,$48,$00,$1F,$7C,$00,$00	;098050

; Entry $06: Configuration $0000
	db $00,$00,$FF,$7F,$CE,$39,$29,$25,$A5,$14,$1F,$00,$98,$7E,$00,$00	;098060

; Entry $07: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$3B,$94,$3E,$8C,$45,$84,$48,$1F,$00,$00,$00	;098070

; Entry $08: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$3B,$9B,$4E,$16,$5D,$0A,$34,$98,$01,$00,$00	;098080

; Entry $09: Configuration $0000
	db $00,$00,$B6,$7F,$DF,$4E,$DA,$29,$49,$42,$22,$25,$1F,$00,$00,$00	;098090

; Entry $0A: Configuration $0000
	db $00,$00,$FF,$7F,$DF,$41,$1F,$00,$0C,$00,$FF,$03,$C0,$4E,$00,$00	;0980A0

; Entry $0B: Configuration $0000
	db $00,$00,$FF,$7F,$6C,$47,$8C,$46,$6C,$45,$CC,$44,$1F,$00,$00,$00	;0980B0

; Entry $0C: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$46,$FA,$11,$34,$01,$AB,$00,$D1,$60,$00,$00	;0980C0

; Entry $0D: Configuration $0000
	db $00,$00,$FF,$7F,$99,$7E,$6D,$4E,$40,$1A,$80,$0D,$1F,$00,$00,$00	;0980D0

; Entry $0E: Configuration $0000
	db $00,$00,$FF,$7F,$8D,$7F,$A9,$66,$C6,$51,$E3,$3C,$DF,$03,$00,$00	;0980E0

; Entry $0F: Configuration $0000
	db $00,$00,$FF,$7F,$53,$7F,$4E,$6A,$E8,$54,$09,$34,$1F,$00,$00,$00	;0980F0

; Entry $10: Configuration $0000
	db $00,$00,$FF,$7F,$9F,$7E,$16,$26,$B7,$38,$29,$14,$1F,$00,$00,$00	;098100

; Entry $11: Configuration $0000
	db $00,$00,$FF,$7F,$BF,$5E,$53,$7D,$A6,$45,$20,$1D,$1F,$00,$00,$00	;098110

; Entry $12: Configuration $0000
	db $00,$00,$FF,$7F,$5F,$2B,$58,$46,$F3,$68,$C5,$44,$FF,$00,$00,$00	;098120

; Entry $13: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$51,$15,$32,$67,$02,$80,$19,$1F,$3C,$00,$00	;098130

; Entry $14: Configuration $0000
	db $00,$00,$FF,$7F,$7F,$3A,$F4,$35,$4A,$31,$A5,$1C,$CD,$0C,$00,$00	;098140

; Entry $15: Configuration $0000
	db $00,$00,$FF,$7F,$9F,$7E,$7C,$61,$78,$3C,$29,$14,$3F,$03,$00,$00	;098150

; Entry $16: Configuration $0000
	db $00,$00,$FF,$7F,$BC,$3A,$2F,$2E,$88,$21,$00,$15,$19,$3C,$00,$00	;098160

; Entry $17: Configuration $0000
	db $00,$00,$FF,$7F,$DF,$1E,$1F,$01,$03,$1A,$40,$01,$49,$36,$00,$00	;098170

; Entry $18: Configuration $0000
	db $00,$00,$FF,$57,$7B,$02,$0D,$02,$C6,$00,$FF,$7F,$8F,$6A,$00,$00	;098180

; Entry $19: Configuration $0000
	db $00,$00,$FF,$7F,$D5,$3E,$09,$4A,$49,$29,$C9,$18,$1F,$00,$00,$00	;098190

; Entry $1A: Configuration $0000
	db $00,$00,$FF,$7F,$D7,$7E,$2F,$4A,$A8,$21,$03,$01,$31,$01,$00,$00	;0981A0

; Entry $1B: Configuration $0000
	db $00,$00,$FF,$7F,$9C,$5E,$D2,$41,$4A,$2D,$A9,$00,$FB,$02,$00,$00	;0981B0

; Entry $1C: Configuration $0000
	db $00,$00,$FF,$7F,$0A,$52,$44,$39,$C1,$2C,$61,$18,$E0,$03,$00,$00	;0981C0

; Entry $1D: Configuration $0000
	db $00,$00,$FF,$7F,$FF,$03,$D8,$1D,$14,$01,$CB,$00,$8F,$6A,$00,$00	;0981D0

; Entry $1E: Configuration $0000
	db $00,$00,$FF,$7F,$EC,$7E,$5F,$3E,$13,$1A,$86,$01,$1F,$00,$00,$00	;0981E0

; Entry $1F: Configuration $0000
	db $00,$00,$FF,$7F,$EC,$7E,$2B,$5A,$8B,$31,$C9,$18,$1F,$00,$00,$00	;0981F0

; Entry $20: Configuration $0000
	db $00,$00,$FF,$7F,$12,$7F,$8C,$5A,$26,$32,$ED,$54,$E7,$38,$00,$00	;098200

; Entry $21: Configuration $0000
	db $00,$00,$52,$5A,$CE,$41,$29,$29,$E7,$1C,$63,$0C,$00,$00,$00,$00	;098210

; Entry $22: Configuration $0000
	db $00,$00,$5F,$67,$9F,$2D,$1F,$00,$90,$00,$48,$00,$20,$7F,$00,$00	;098220

; Entry $23: Configuration $0000
	db $00,$00,$FF,$7F,$5A,$57,$74,$36,$4B,$19,$A6,$08,$1F,$00,$00,$00	;098230

; Entry $24: Configuration $0000
	db $00,$00,$FF,$7F,$73,$5E,$4A,$39,$FF,$03,$72,$01,$1E,$00,$00,$00	;098240

; Entry $25: Configuration $0000
	db $00,$00,$FF,$7F,$DF,$05,$11,$14,$F1,$6A,$29,$29,$C0,$01,$00,$00	;098250

; Entry $26: Configuration $0000
	db $00,$00,$FF,$7F,$DF,$52,$BF,$25,$1F,$14,$10,$00,$FF,$03,$00,$00	;098260

; Entry $27: Configuration $0000
	db $00,$00,$FF,$7F,$DF,$52,$94,$3E,$66,$1E,$60,$01,$E0,$7F,$00,$00	;098270

; Entry $28: Configuration $0000
	db $00,$00,$FF,$7F,$03,$33,$80,$09,$3E,$03,$70,$01,$15,$00,$00,$00	;098280

; Entry $29: Configuration $0000
	db $00,$00,$FF,$7F,$10,$42,$0B,$00,$0E,$58,$07,$34,$15,$00,$00,$00	;098290

; Entry $2A: Configuration $0000
	db $00,$00,$FF,$7F,$10,$42,$0B,$00,$0E,$58,$07,$34,$3E,$03,$00,$00	;0982A0

; Entry $2B: Configuration $0000
	db $00,$00,$FF,$7F,$52,$4A,$29,$25,$3E,$03,$F6,$01,$15,$00,$00,$00	;0982B0

; Entry $2C: Configuration $4822
	db $48,$22,$00,$00,$FF,$7F,$FF,$03,$5F,$22,$3F,$00,$EC,$00,$AE,$2D	;0982C0

; Entry $2D: Configuration $4822
	db $48,$22,$E6,$24,$F6,$5A,$FB,$7F,$93,$01,$BA,$02,$7C,$6B,$FF,$7F	;0982D0

; Entry $2E: Configuration $4822
	db $48,$22,$C2,$14,$FF,$7F,$39,$67,$B5,$56,$CE,$39,$3F,$10,$4A,$29	;0982E0

; Entry $2F: Configuration $4822
	db $48,$22,$00,$00,$FF,$7F,$78,$7F,$50,$7E,$AD,$7D,$4A,$41,$9F,$03	;0982F0

; Entry $30: Configuration $4822
	db $48,$22,$A2,$18,$7F,$4D,$E8,$7D,$38,$7F,$B5,$7E,$FF,$7F,$77,$31	;098300

; Entry $31: Configuration $4822
	db $48,$22,$E6,$24,$10,$42,$B5,$56,$56,$02,$F4,$01,$7B,$6F,$DD,$7F	;098310

; Entry $32: Configuration $4822
	db $48,$22,$E6,$24,$F6,$7E,$DD,$7F,$FF,$00,$FD,$02,$CE,$37,$F7,$66	;098320

; Entry $33: Configuration $4822
	db $48,$22,$29,$25,$72,$4A,$38,$63,$FF,$03,$FF,$01,$1A,$00,$AE,$2D	;098330

; Entry $34: Configuration $4822
	db $48,$22,$35,$36,$90,$21,$FF,$03,$DF,$02,$FF,$01,$2C,$1D,$1F,$00	;098340

; Entry $35: Configuration $4822
	db $48,$22,$84,$10,$2D,$4D,$AF,$5D,$39,$7F,$FF,$7F,$9F,$03,$B3,$6E	;098350

; Entry $36: Configuration $4822
	db $48,$22,$84,$10,$BD,$42,$5A,$32,$7F,$03,$DD,$02,$9B,$7B,$38,$7B	;098360

; Entry $37: Configuration $4822
	db $48,$22,$00,$00,$E0,$4B,$40,$2B,$A0,$03,$00,$00,$00,$00,$FF,$7F	;098370

; Entry $38: Configuration $4822
	db $48,$22,$00,$00,$00,$00,$1F,$00,$FF,$7F,$78,$7F,$50,$7E,$00,$00	;098380

; Entry $39: Configuration $4822
	db $48,$22,$00,$00,$35,$02,$DB,$02,$60,$3A,$E0,$4A,$5E,$03,$FF,$7F	;098390

; Entry $3A: Configuration $4822
	db $48,$22,$00,$00,$1D,$74,$80,$7D,$1D,$74,$15,$54,$2D,$4D,$15,$54	;0983A0

; Entry $3B: Configuration $4822
	db $48,$22,$84,$10,$39,$67,$B5,$56,$10,$42,$39,$67,$B5,$56,$10,$42	;0983B0

; Entry $3C: Configuration $0058
	db $00,$58,$FF,$7F,$12,$7F,$8C,$5A,$26,$32,$ED,$54,$E7,$38,$00,$00	;0983C0

; Entry $3D: Configuration $0058
	db $00,$58,$52,$5A,$CE,$41,$29,$29,$E7,$1C,$63,$0C,$00,$00,$00,$00	;0983D0

; Entry $3E: Configuration $0058
	db $00,$58,$5F,$67,$9F,$2D,$1F,$00,$90,$00,$FF,$03,$BF,$01,$00,$00	;0983E0

; Entry $3F: Configuration $0058
	db $00,$58,$FF,$7F,$5A,$57,$74,$36,$4B,$19,$80,$7E,$00,$7C,$00,$00	;0983F0

; Entry $40: Configuration $0058
	db $00,$58,$FF,$7F,$73,$5E,$4A,$39,$FF,$03,$72,$01,$1F,$7C,$00,$00	;098400

; Entry $41: Configuration $0058
	db $00,$58,$FF,$7F,$00,$53,$80,$21,$FF,$03,$72,$01,$1F,$7C,$00,$00	;098410

; Entry $42: Configuration $0058
	db $00,$58,$FF,$7F,$FF,$03,$72,$01,$52,$4A,$4A,$29,$1F,$00,$00,$00	;098420

; Entry $43: Configuration $0058
	db $00,$58,$FF,$7F,$1F,$7C,$1F,$7C,$1F,$7C,$1F,$7C,$1F,$7C,$00,$00	;098430

; Entry $44: Configuration $4722
	db $47,$22,$00,$00,$FF,$7F,$4F,$3E,$4A,$29,$AD,$35,$E8,$20,$EF,$3D	;098440

; Entry $45: Configuration $0000 (Last entry)
	db $00,$00,$31,$46,$5A,$6B,$6C,$31,$09,$25,$C7,$1C,$85,$14,$42,$0C	;098450

; ==============================================================================
; Graphics Data Pointer Tables
; ==============================================================================
; These tables contain 16-bit pointers to sprite/tile graphics data.
; Format: [Pointer_Low, Pointer_High, Bank, Count, Flags]
; ==============================================================================

DATA8_098460:
	db $F5									;098460	; Pointer low byte

DATA8_098461:
	db $85									;098461	; Pointer high byte

DATA8_098462:
	db $09									;098462	; Bank $09

DATA8_098463:
	db $04									;098463	; Count: 4 entries

DATA8_098464:
	db $00,$F5,$85,$09,$03,$00,$F5,$85,$09,$01,$00,$AD,$88,$09,$05,$00	;098464
	db $AD,$88,$09,$14,$00,$AD,$88,$09,$00,$00,$05,$8E,$09,$02,$00,$05	;098474
	db $8E,$09,$01,$00									;098484

	db $05,$8E,$09,$06,$00								;098488

	db $35,$91,$09,$0B,$00,$35,$91,$09,$07,$00			;09848D

	db $35,$91,$09,$09,$00								;098497

	db $55,$95,$09,$08,$00,$55,$95,$09,$01,$00,$55,$95,$09,$17,$00,$45	;09849C
	db $99,$09,$10,$00,$45,$99,$09,$08,$00				;0984AC

	db $45,$99,$09,$11,$00								;0984B5

	db $DD,$9D,$09,$00,$00,$DD,$9D,$09,$0A,$00			;0984BA

	db $DD,$9D,$09,$18,$00								;0984C4

	db $9D,$A1,$09,$12,$00,$9D,$A1,$09,$13,$00			;0984C9

	db $9D,$A1,$09,$01,$00								;0984D3

	db $95,$A6,$09,$00,$00,$95,$A6,$09,$17,$00,$A5,$AB,$09,$14,$00	;0984D8

	db $A5,$AB,$09,$0D,$00								;0984E7

	db $35,$AF,$09,$08,$00,$35,$AF,$09,$14,$00,$65,$B2,$09,$0C,$00	;0984EC

	db $65,$B2,$09,$14,$00								;0984FB

	db $2D,$B7,$09,$0C,$00,$2D,$B7,$09,$11,$00,$05,$BB,$09,$11,$00,$05	;098500
	db $BB,$09,$01,$00,$9D,$BF,$09,$18,$00,$9D,$BF,$09,$00,$00,$8D,$C3	;098510
	db $09,$07,$00										;098520

	db $8D,$C3,$09,$02,$00								;098523

	db $F5,$C7,$09,$0A,$00								;098528

	db $F5,$C7,$09,$06,$00								;09852D

	db $E5,$CB,$09,$05,$00								;098532

	db $E5,$CB,$09,$08,$00								;098537

	db $C5,$D0,$09,$0F,$00,$C5,$D0,$09,$14,$00,$9D,$D4,$09,$01,$00,$9D	;09853C
	db $D4,$09,$0B,$00,$8D,$D8,$09,$0C,$00				;09854C

	db $8D,$D8,$09,$16,$00								;098555

	db $45,$DE,$09,$09,$00,$45,$DE,$09,$10,$00,$75,$E1,$09,$00,$03	;09855A

	db $75,$E1,$09,$00,$12								;098569

	db $95,$E5,$09,$0E,$00								;09856E

	db $95,$E5,$09,$15,$00								;098573

	db $CD,$E9,$09,$19,$00,$DD,$F1,$09,$1A,$00,$18,$86,$0A,$15,$00,$38	;098578
	db $90,$0A,$1C,$00,$88,$97,$0A,$1D,$00,$08,$A2,$0A,$12,$00		;098588

	db $C8,$B7,$0A,$08,$00,$08,$AB,$0A,$11,$00,$38,$C3,$0A,$23,$00,$30	;098596
	db $D4,$0A,$21,$00									;0985A6

	db $CD,$E9,$09,$0D,$00,$DD,$F1,$09,$0C,$00,$18,$86,$0A,$1B,$00,$38	;0985AA
	db $90,$0A,$0E,$00,$88,$97,$0A,$01,$00,$08,$A2,$0A,$1E,$00		;0985BA

	db $C8,$B7,$0A,$1D,$00,$08,$AB,$0A,$1F,$00			;0985C8

	db $38,$C3,$0A,$22,$00,$30,$D4,$0A,$20,$00,$88,$E8,$0A,$26,$00	;0985D2

	db $88,$E8,$0A,$27,$00,$1C,$97,$0B,$24,$00,$1C,$97,$0B,$25,$00,$3C	;0985E1
	db $B3,$0B,$FF,$FF									;0985F1

; ==============================================================================
; Tile Graphics Data
; ==============================================================================
; Raw bitmap data for sprites and tiles in SNES 2bpp/4bpp format.
; Data continues to end of bank ($09FFFF).
;
; Note: The remaining ~26KB of data consists of tile patterns.
; Each 8x8 tile in 2bpp format uses 16 bytes.
; Each 8x8 tile in 4bpp format uses 32 bytes.
;
; To extract and visualize this data:
; - Use tools/extract_bank09_graphics.py (to be created)
; - Convert to PNG with proper palette application
; - Data format follows SNES tile encoding standards
; ==============================================================================

	db $00,$00,$03,$03,$0F,$0C,$1C,$10,$39,$20,$72,$40,$E4,$80,$E1,$80	;0985F5
	db $00,$03,$0F,$1F,$3E,$7D,$FB,$FF,$F0,$F0,$FC,$0C,$8E,$02,$67,$01	;098605
	db $83,$00,$3F,$00,$FF,$00,$FF,$00,$F0,$FC,$FE,$9F,$7F,$FF,$FF,$FF	;098615
	db $00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80,$80,$C0,$40,$C0,$40	;098625
	db $00,$00,$00,$00,$80,$80,$C0,$C0,$01,$01,$01,$01,$0D,$0D,$0A,$0F	;098635

; [Graphics data continues for ~26KB to $09FFFF]
; Complete data available in original bank_09.asm
; Extraction tool needed to convert to usable PNG/JSON format

; ==============================================================================
; End of Bank $09
; ==============================================================================
; Total size: 32 KB (complete bank)
; Palette entries: 73 entries (1168 bytes)
; Pointer tables: ~405 bytes
; Graphics data: ~26KB of tile patterns
;
; Next steps:
; - Create extraction tool (tools/extract_bank09_graphics.py)
; - Convert to JSON structure (sprite definitions, palettes)
; - Convert tile data to PNG files with palette application
; - Document sprite usage and animation sequences
; ==============================================================================
