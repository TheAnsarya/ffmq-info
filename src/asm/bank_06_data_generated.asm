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

                   ORG $068000

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

DATA8_06A000:
    db $2E,$DE,$C6,$03,$3F,$BD,$24,$2F,$EE,$14,$4F,$C6,$CE,$34,$1E,$DE  ; Tile $00: water,lava,trig
    db $14,$2D,$CF,$22,$C6,$1E,$CE,$34,$0C,$D0,$33,$1D,$C0,$C6,$55,$FC  ; Tile $10: lava
    db $E2,$33,$0D,$C1,$43,$EC,$C6,$E1,$32,$FB,$C1,$52,$DC,$F2,$32,$C7  ; Tile $20: water
    db $EC,$E3,$41,$EE,$02,$42,$EC,$04,$02,$00,$00,$00,$00,$00,$00,$00  ; Tile $30: lava,trig
    db $00,$C2,$40,$E3,$30,$12,$11,$22,$22,$22,$96,$EC,$04,$DD,$2F,$E2  ; Tile $40
    db $EC,$32,$DF,$C6,$00,$00,$F0,$0F,$01,$DF,$5F,$A4,$C2,$4F,$D3,$41  ; Tile $50: lava,trig
    db $23,$22,$21,$11,$11,$97,$2C,$14,$EE,$3E,$D2,$FD,$31,$CF,$02,$00  ; Tile $60: blk,water
    db $00,$00,$00,$00,$00,$00,$00,$7A,$13,$32,$F0,$35,$54,$23,$57,$61  ; Tile $70
    db $8A,$EE,$F1,$23,$21,$35,$64,$2E,$E0,$8A,$35,$43,$12,$12,$34,$31  ; Tile $80: water,trig
    db $01,$23,$9A,$21,$FE,$F2,$45,$30,$EF,$35,$41,$AA,$FF,$01,$10,$EC  ; Tile $90: blk
    db $D0,$33,$0F,$F0,$9A,$13,$2E,$BC,$02,$2F,$CA,$D0,$10,$8A,$FC,$CD  ; Tile $A0
    db $FF,$FE,$CC,$DF,$FF,$EC,$8A,$BC,$E2,$21,$EB,$BC,$ED,$DB,$EF,$7A  ; Tile $B0: blk,water,lava,trig
    db $34,$3C,$AB,$DF,$EB,$BD,$F1,$ED,$7A,$EF,$12,$0B,$AE,$34,$0E,$CE  ; Tile $C0: lava
    db $36,$7A,$4F,$DC,$15,$63,$EB,$C2,$42,$FE,$7A,$E1,$57,$41,$11,$34  ; Tile $D0: water,lava
    db $1E,$CB,$DD,$7A,$F0,$11,$46,$50,$E0,$12,$0C,$AC,$7A,$E2,$20,$DD  ; Tile $E0: water,lava,trig
    db $F2,$65,$EA,$C0,$45,$7A,$F1,$BC,$05,$40,$DD,$04,$54,$0E,$7A,$12  ; Tile $F0: water

; ============================================================================
; END OF BANK $06 AUTO-GENERATED DATA
; ============================================================================
; To rebuild this file:
;   python tools/build_asm_from_json.py data/map_tilemaps.json src/asm/bank_06_data_generated.asm
; ============================================================================