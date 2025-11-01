; ============================================================================
; BANK $06 - Map Tilemap Data (AUTO-GENERATED)
; ============================================================================
; Generated from: map_tilemaps.json
; DO NOT EDIT MANUALLY - Edit JSON and regenerate
;
; Description: Map tilemap and collision data
; Metatile Format: 16x16 pixels (4x 8x8 tiles): [TL, TR, BL, BR]
; Total Metatiles: 256
; Total Collision Entries: 256
; ============================================================================

	org $068000

; ============================================================================
; Collision Data
; ============================================================================
; Format: 1 byte bitfield per tile
; Bit 0: Blocked (0=passable, 1=blocked)
; Bit 1: Water tile (requires Float)
; Bit 2: Lava tile (damages player)
; Bit 3: Event trigger (door, chest, NPC)
; Bit 4-7: Special properties
; Count: 256 entries
; ============================================================================

DATA8_06a000:
	db $2e,$de,$c6,$03,$3f,$bd,$24,$2f,$ee,$14,$4f,$c6,$ce,$34,$1e,$de  ; Tile $00: water,lava,trig
	db $14,$2d,$cf,$22,$c6,$1e,$ce,$34,$0c,$d0,$33,$1d,$c0,$c6,$55,$fc  ; Tile $10: lava
	db $e2,$33,$0d,$c1,$43,$ec,$c6,$e1,$32,$fb,$c1,$52,$dc,$f2,$32,$c7  ; Tile $20: water
	db $ec,$e3,$41,$ee,$02,$42,$ec,$04,$02,$00,$00,$00,$00,$00,$00,$00  ; Tile $30: lava,trig
	db $00,$c2,$40,$e3,$30,$12,$11,$22,$22,$22,$96,$ec,$04,$dd,$2f,$e2  ; Tile $40
	db $ec,$32,$df,$c6,$00,$00,$f0,$0f,$01,$df,$5f,$a4,$c2,$4f,$d3,$41  ; Tile $50: lava,trig
	db $23,$22,$21,$11,$11,$97,$2c,$14,$ee,$3e,$d2,$fd,$31,$cf,$02,$00  ; Tile $60: blk,water
	db $00,$00,$00,$00,$00,$00,$00,$7a,$13,$32,$f0,$35,$54,$23,$57,$61  ; Tile $70
	db $8a,$ee,$f1,$23,$21,$35,$64,$2e,$e0,$8a,$35,$43,$12,$12,$34,$31  ; Tile $80: water,trig
	db $01,$23,$9a,$21,$fe,$f2,$45,$30,$ef,$35,$41,$aa,$ff,$01,$10,$ec  ; Tile $90: blk
	db $d0,$33,$0f,$f0,$9a,$13,$2e,$bc,$02,$2f,$ca,$d0,$10,$8a,$fc,$cd  ; Tile $a0
	db $ff,$fe,$cc,$df,$ff,$ec,$8a,$bc,$e2,$21,$eb,$bc,$ed,$db,$ef,$7a  ; Tile $b0: blk,water,lava,trig
	db $34,$3c,$ab,$df,$eb,$bd,$f1,$ed,$7a,$ef,$12,$0b,$ae,$34,$0e,$ce  ; Tile $c0: lava
	db $36,$7a,$4f,$dc,$15,$63,$eb,$c2,$42,$fe,$7a,$e1,$57,$41,$11,$34  ; Tile $d0: water,lava
	db $1e,$cb,$dd,$7a,$f0,$11,$46,$50,$e0,$12,$0c,$ac,$7a,$e2,$20,$dd  ; Tile $e0: water,lava,trig
	db $f2,$65,$ea,$c0,$45,$7a,$f1,$bc,$05,$40,$dd,$04,$54,$0e,$7a,$12  ; Tile $f0: water

; ============================================================================
; END OF BANK $06 AUTO-GENERATED DATA
; ============================================================================
; To rebuild this file:
;   python tools/build_asm_from_json.py data/map_tilemaps.json src/asm/bank_06_data_generated.asm
; ============================================================================
