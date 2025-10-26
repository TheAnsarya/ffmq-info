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
; Metatile Set 1 - Overworld/Outdoor Locations
; ============================================================================
; Format: 16x16 metatiles (4 bytes each: TL, TR, BL, BR)
; Count: 128 metatiles
; ============================================================================

DATA8_068000:

    ; Metatiles $00-$07
    db $4C,$2C,$80,$EA  ; Metatile $00: Special graphics
    db $4C,$47,$81,$EA  ; Metatile $01: Special graphics
    db $87,$86,$AC,$A1  ; Metatile $02: Unknown pattern
    db $78,$9D,$46,$A1  ; Metatile $03: Special graphics
    db $78,$A1,$92,$A1  ; Metatile $04: Unknown pattern
    db $00,$02,$00,$2C  ; Metatile $05: Ground/floor pattern
    db $00,$48,$00,$1B  ; Metatile $06: Ground/floor pattern
    db $80,$1A,$00,$1A  ; Metatile $07: Wall/building pattern

    ; Metatiles $08-$0F
    db $AE,$BD,$FF,$BD  ; Metatile $08: Unknown pattern
    db $35,$BE,$7D,$BE  ; Metatile $09: Unknown pattern
    db $59,$BE,$A1,$BE  ; Metatile $0A: Unknown pattern
    db $8B,$0B,$08,$C2  ; Metatile $0B: Object/furniture
    db $20,$C2,$10,$48  ; Metatile $0C: Object/furniture
    db $DA,$5A,$E2,$20  ; Metatile $0D: Unknown pattern
    db $A9,$00,$48,$AB  ; Metatile $0E: Special graphics
    db $A2,$00,$06,$DA  ; Metatile $0F: Special graphics

    ; Metatiles $10-$17
    db $2B,$A2,$AA,$BB  ; Metatile $10: Unknown pattern
    db $EC,$40,$21,$F0  ; Metatile $11: Unknown pattern
    db $2E,$A4,$F8,$F0  ; Metatile $12: Unknown pattern
    db $2A,$C4,$48,$D0  ; Metatile $13: Unknown pattern
    db $26,$A9,$F0,$C5  ; Metatile $14: Unknown pattern
    db $00,$D0,$20,$A9  ; Metatile $15: Special graphics
    db $08,$8D,$41,$21  ; Metatile $16: Wall/building pattern
    db $A9,$00,$8D,$40  ; Metatile $17: Object/furniture

    ; Metatiles $18-$1F
    db $21,$A2,$F8,$00  ; Metatile $18: Special graphics
    db $9D,$FF,$05,$CA  ; Metatile $19: Unknown pattern
    db $D0,$FA,$84,$48  ; Metatile $1A: Unknown pattern
    db $A9,$FF,$85,$05  ; Metatile $1B: Unknown pattern
    db $A9,$F0,$85,$00  ; Metatile $1C: Unknown pattern
    db $4C,$5C,$81,$EC  ; Metatile $1D: Unknown pattern
    db $40,$21,$D0,$FB  ; Metatile $1E: Unknown pattern
    db $A2,$00,$00,$AF  ; Metatile $1F: Object/furniture

    ; Metatiles $20-$27
    db $14,$80,$0D,$8D  ; Metatile $20: Object/furniture
    db $42,$21,$AF,$15  ; Metatile $21: Object/furniture
    db $80,$0D,$8D,$43  ; Metatile $22: Object/furniture
    db $21,$A9,$01,$8D  ; Metatile $23: Object/furniture
    db $41,$21,$A9,$CC  ; Metatile $24: Special graphics
    db $8D,$40,$21,$CD  ; Metatile $25: Special graphics
    db $40,$21,$D0,$FB  ; Metatile $26: Unknown pattern
    db $A9,$00,$EB,$BF  ; Metatile $27: Unknown pattern

    ; Metatiles $28-$2F
    db $08,$80,$0D,$85  ; Metatile $28: Object/furniture
    db $14,$BF,$09,$80  ; Metatile $29: Object/furniture
    db $0D,$85,$15,$A9  ; Metatile $2A: Object/furniture
    db $0D,$85,$16,$A0  ; Metatile $2B: Object/furniture
    db $00,$00,$B7,$14  ; Metatile $2C: Wall/building pattern
    db $18,$69,$02,$85  ; Metatile $2D: Object/furniture
    db $10,$C8,$B7,$14  ; Metatile $2E: Special graphics
    db $69,$00,$85,$11  ; Metatile $2F: Wall/building pattern

    ; Metatiles $30-$37
    db $C8,$B7,$14,$8D  ; Metatile $30: Unknown pattern
    db $41,$21,$EB,$8D  ; Metatile $31: Special graphics
    db $40,$21,$CD,$40  ; Metatile $32: Object/furniture
    db $21,$D0,$FB,$1A  ; Metatile $33: Unknown pattern
    db $EB,$C8,$C4,$10  ; Metatile $34: Unknown pattern
    db $D0,$EB,$EB,$1A  ; Metatile $35: Unknown pattern
    db $1A,$1A,$D0,$01  ; Metatile $36: Object/furniture
    db $1A,$E8,$E8,$E0  ; Metatile $37: Unknown pattern

    ; Metatiles $38-$3F
    db $0C,$00,$F0,$1D  ; Metatile $38: Object/furniture
    db $EB,$BF,$14,$80  ; Metatile $39: Unknown pattern
    db $0D,$8D,$42,$21  ; Metatile $3A: Wall/building pattern
    db $BF,$15,$80,$0D  ; Metatile $3B: Object/furniture
    db $8D,$43,$21,$EB  ; Metatile $3C: Special graphics
    db $8D,$41,$21,$8D  ; Metatile $3D: Object/furniture
    db $40,$21,$CD,$40  ; Metatile $3E: Object/furniture
    db $21,$D0,$FB,$80  ; Metatile $3F: Unknown pattern

    ; Metatiles $40-$47
    db $9B,$A0,$00,$02  ; Metatile $40: Object/furniture
    db $8C,$42,$21,$EB  ; Metatile $41: Special graphics
    db $A9,$00,$8D,$41  ; Metatile $42: Object/furniture
    db $21,$EB,$8D,$40  ; Metatile $43: Special graphics
    db $21,$CD,$40,$21  ; Metatile $44: Object/furniture
    db $D0,$FB,$EB,$8D  ; Metatile $45: Unknown pattern
    db $40,$21,$A2,$00  ; Metatile $46: Object/furniture
    db $01,$9D,$FF,$05  ; Metatile $47: Special graphics

    ; Metatiles $48-$4F
    db $CA,$D0,$FA,$A9  ; Metatile $48: Unknown pattern
    db $FF,$85,$05,$C2  ; Metatile $49: Unknown pattern
    db $20,$AF,$78,$9D  ; Metatile $4A: Special graphics
    db $0D,$18,$69,$00  ; Metatile $4B: Wall/building pattern
    db $48,$85,$F8,$85  ; Metatile $4C: Unknown pattern
    db $48,$A2,$00,$08  ; Metatile $4D: Wall/building pattern
    db $CA,$D0,$FD,$E2  ; Metatile $4E: Unknown pattern
    db $20,$A9,$80,$85  ; Metatile $4F: Special graphics

    ; Metatiles $50-$57
    db $FA,$A9,$0D,$85  ; Metatile $50: Unknown pattern
    db $FB,$80,$31,$8B  ; Metatile $51: Unknown pattern
    db $0B,$08,$C2,$20  ; Metatile $52: Wall/building pattern
    db $C2,$10,$48,$DA  ; Metatile $53: Special graphics
    db $5A,$E2,$20,$A9  ; Metatile $54: Unknown pattern
    db $00,$48,$AB,$A2  ; Metatile $55: Special graphics
    db $00,$06,$DA,$2B  ; Metatile $56: Object/furniture
    db $E2,$20,$A5,$00  ; Metatile $57: Special graphics

    ; Metatiles $58-$5F
    db $64,$00,$F0,$14  ; Metatile $58: Object/furniture
    db $30,$0C,$C9,$01  ; Metatile $59: Object/furniture
    db $F0,$19,$C9,$03  ; Metatile $5A: Special graphics
    db $F0,$15,$C9,$70  ; Metatile $5B: Unknown pattern
    db $B0,$03,$4C,$BA  ; Metatile $5C: Special graphics
    db $85,$4C,$0E,$86  ; Metatile $5D: Object/furniture
    db $C2,$20,$C2,$10  ; Metatile $5E: Special graphics
    db $7A,$FA,$68,$28  ; Metatile $5F: Unknown pattern

    ; Metatiles $60-$67
    db $2B,$AB,$6B,$E2  ; Metatile $60: Unknown pattern
    db $20,$EB,$A5,$01  ; Metatile $61: Special graphics
    db $C5,$05,$D0,$61  ; Metatile $62: Special graphics
    db $A6,$02,$86,$06  ; Metatile $63: Object/furniture
    db $8A,$29,$0F,$8D  ; Metatile $64: Object/furniture
    db $41,$21,$A9,$84  ; Metatile $65: Special graphics
    db $CD,$40,$21,$F0  ; Metatile $66: Unknown pattern
    db $FB,$8D,$40,$21  ; Metatile $67: Special graphics

    ; Metatiles $68-$6F
    db $CD,$40,$21,$D0  ; Metatile $68: Special graphics
    db $FB,$A9,$00,$8D  ; Metatile $69: Unknown pattern
    db $40,$21,$EB,$A5  ; Metatile $6A: Special graphics
    db $03,$4A,$4A,$4A  ; Metatile $6B: Wall/building pattern
    db $4A,$8D,$41,$21  ; Metatile $6C: Object/furniture
    db $A9,$81,$CD,$40  ; Metatile $6D: Unknown pattern
    db $21,$F0,$FB,$8D  ; Metatile $6E: Unknown pattern
    db $40,$21,$CD,$40  ; Metatile $6F: Object/furniture

    ; Metatiles $70-$77
    db $21,$D0,$FB,$EB  ; Metatile $70: Unknown pattern
    db $8D,$40,$21,$EB  ; Metatile $71: Special graphics
    db $A5,$02,$29,$F0  ; Metatile $72: Special graphics
    db $85,$02,$A5,$03  ; Metatile $73: Object/furniture
    db $29,$0F,$05,$02  ; Metatile $74: Ground/floor pattern
    db $8D,$41,$21,$A9  ; Metatile $75: Special graphics
    db $81,$CD,$40,$21  ; Metatile $76: Special graphics
    db $F0,$FB,$8D,$40  ; Metatile $77: Unknown pattern

    ; Metatiles $78-$7F
    db $21,$CD,$40,$21  ; Metatile $78: Object/furniture
    db $D0,$FB,$EB,$8D  ; Metatile $79: Unknown pattern
    db $40,$21,$4C,$78  ; Metatile $7A: Object/furniture
    db $81,$20,$25,$86  ; Metatile $7B: Object/furniture
    db $A5,$05,$30,$06  ; Metatile $7C: Wall/building pattern
    db $85,$09,$A6,$06  ; Metatile $7D: Object/furniture
    db $86,$0A,$A5,$01  ; Metatile $7E: Object/furniture
    db $8D,$41,$21,$85  ; Metatile $7F: Object/furniture

; ============================================================================
; Metatile Set 2 - Indoor/Building Floors
; ============================================================================
; Format: 16x16 metatiles (4 bytes each: TL, TR, BL, BR)
; Count: 64 metatiles
; ============================================================================

DATA8_068400:

    ; Metatiles $80-$3F
    db $AE,$BD,$FF,$BD  ; Metatile $80: Unknown pattern
    db $35,$BE,$7D,$BE  ; Metatile $81: Unknown pattern
    db $59,$BE,$A1,$BE  ; Metatile $82: Unknown pattern
    db $8B,$0B,$08,$C2  ; Metatile $83: Object/furniture
    db $20,$C2,$10,$48  ; Metatile $84: Object/furniture
    db $DA,$5A,$E2,$20  ; Metatile $85: Unknown pattern
    db $A9,$00,$48,$AB  ; Metatile $86: Special graphics
    db $A2,$00,$06,$DA  ; Metatile $87: Special graphics

    ; Metatiles $88-$3F
    db $2B,$A2,$AA,$BB  ; Metatile $88: Unknown pattern
    db $EC,$40,$21,$F0  ; Metatile $89: Unknown pattern
    db $2E,$A4,$F8,$F0  ; Metatile $8A: Unknown pattern
    db $2A,$C4,$48,$D0  ; Metatile $8B: Unknown pattern
    db $26,$A9,$F0,$C5  ; Metatile $8C: Unknown pattern
    db $00,$D0,$20,$A9  ; Metatile $8D: Special graphics
    db $08,$8D,$41,$21  ; Metatile $8E: Wall/building pattern
    db $A9,$00,$8D,$40  ; Metatile $8F: Object/furniture

    ; Metatiles $90-$3F
    db $21,$A2,$F8,$00  ; Metatile $90: Special graphics
    db $9D,$FF,$05,$CA  ; Metatile $91: Unknown pattern
    db $D0,$FA,$84,$48  ; Metatile $92: Unknown pattern
    db $A9,$FF,$85,$05  ; Metatile $93: Unknown pattern
    db $A9,$F0,$85,$00  ; Metatile $94: Unknown pattern
    db $4C,$5C,$81,$EC  ; Metatile $95: Unknown pattern
    db $40,$21,$D0,$FB  ; Metatile $96: Unknown pattern
    db $A2,$00,$00,$AF  ; Metatile $97: Object/furniture

    ; Metatiles $98-$3F
    db $14,$80,$0D,$8D  ; Metatile $98: Object/furniture
    db $42,$21,$AF,$15  ; Metatile $99: Object/furniture
    db $80,$0D,$8D,$43  ; Metatile $9A: Object/furniture
    db $21,$A9,$01,$8D  ; Metatile $9B: Object/furniture
    db $41,$21,$A9,$CC  ; Metatile $9C: Special graphics
    db $8D,$40,$21,$CD  ; Metatile $9D: Special graphics
    db $40,$21,$D0,$FB  ; Metatile $9E: Unknown pattern
    db $A9,$00,$EB,$BF  ; Metatile $9F: Unknown pattern

    ; Metatiles $A0-$3F
    db $08,$80,$0D,$85  ; Metatile $A0: Object/furniture
    db $14,$BF,$09,$80  ; Metatile $A1: Object/furniture
    db $0D,$85,$15,$A9  ; Metatile $A2: Object/furniture
    db $0D,$85,$16,$A0  ; Metatile $A3: Object/furniture
    db $00,$00,$B7,$14  ; Metatile $A4: Wall/building pattern
    db $18,$69,$02,$85  ; Metatile $A5: Object/furniture
    db $10,$C8,$B7,$14  ; Metatile $A6: Special graphics
    db $69,$00,$85,$11  ; Metatile $A7: Wall/building pattern

    ; Metatiles $A8-$3F
    db $C8,$B7,$14,$8D  ; Metatile $A8: Unknown pattern
    db $41,$21,$EB,$8D  ; Metatile $A9: Special graphics
    db $40,$21,$CD,$40  ; Metatile $AA: Object/furniture
    db $21,$D0,$FB,$1A  ; Metatile $AB: Unknown pattern
    db $EB,$C8,$C4,$10  ; Metatile $AC: Unknown pattern
    db $D0,$EB,$EB,$1A  ; Metatile $AD: Unknown pattern
    db $1A,$1A,$D0,$01  ; Metatile $AE: Object/furniture
    db $1A,$E8,$E8,$E0  ; Metatile $AF: Unknown pattern

    ; Metatiles $B0-$3F
    db $0C,$00,$F0,$1D  ; Metatile $B0: Object/furniture
    db $EB,$BF,$14,$80  ; Metatile $B1: Unknown pattern
    db $0D,$8D,$42,$21  ; Metatile $B2: Wall/building pattern
    db $BF,$15,$80,$0D  ; Metatile $B3: Object/furniture
    db $8D,$43,$21,$EB  ; Metatile $B4: Special graphics
    db $8D,$41,$21,$8D  ; Metatile $B5: Object/furniture
    db $40,$21,$CD,$40  ; Metatile $B6: Object/furniture
    db $21,$D0,$FB,$80  ; Metatile $B7: Unknown pattern

    ; Metatiles $B8-$3F
    db $9B,$A0,$00,$02  ; Metatile $B8: Object/furniture
    db $8C,$42,$21,$EB  ; Metatile $B9: Special graphics
    db $A9,$00,$8D,$41  ; Metatile $BA: Object/furniture
    db $21,$EB,$8D,$40  ; Metatile $BB: Special graphics
    db $21,$CD,$40,$21  ; Metatile $BC: Object/furniture
    db $D0,$FB,$EB,$8D  ; Metatile $BD: Unknown pattern
    db $40,$21,$A2,$00  ; Metatile $BE: Object/furniture
    db $01,$9D,$FF,$05  ; Metatile $BF: Special graphics

; ============================================================================
; Metatile Set 3 - Dungeon/Cave Tiles
; ============================================================================
; Format: 16x16 metatiles (4 bytes each: TL, TR, BL, BR)
; Count: 64 metatiles
; ============================================================================

DATA8_068800:

    ; Metatiles $C0-$3F
    db $20,$C2,$10,$48  ; Metatile $C0: Object/furniture
    db $DA,$5A,$E2,$20  ; Metatile $C1: Unknown pattern
    db $A9,$00,$48,$AB  ; Metatile $C2: Special graphics
    db $A2,$00,$06,$DA  ; Metatile $C3: Special graphics
    db $2B,$A2,$AA,$BB  ; Metatile $C4: Unknown pattern
    db $EC,$40,$21,$F0  ; Metatile $C5: Unknown pattern
    db $2E,$A4,$F8,$F0  ; Metatile $C6: Unknown pattern
    db $2A,$C4,$48,$D0  ; Metatile $C7: Unknown pattern

    ; Metatiles $C8-$3F
    db $26,$A9,$F0,$C5  ; Metatile $C8: Unknown pattern
    db $00,$D0,$20,$A9  ; Metatile $C9: Special graphics
    db $08,$8D,$41,$21  ; Metatile $CA: Wall/building pattern
    db $A9,$00,$8D,$40  ; Metatile $CB: Object/furniture
    db $21,$A2,$F8,$00  ; Metatile $CC: Special graphics
    db $9D,$FF,$05,$CA  ; Metatile $CD: Unknown pattern
    db $D0,$FA,$84,$48  ; Metatile $CE: Unknown pattern
    db $A9,$FF,$85,$05  ; Metatile $CF: Unknown pattern

    ; Metatiles $D0-$3F
    db $A9,$F0,$85,$00  ; Metatile $D0: Unknown pattern
    db $4C,$5C,$81,$EC  ; Metatile $D1: Unknown pattern
    db $40,$21,$D0,$FB  ; Metatile $D2: Unknown pattern
    db $A2,$00,$00,$AF  ; Metatile $D3: Object/furniture
    db $14,$80,$0D,$8D  ; Metatile $D4: Object/furniture
    db $42,$21,$AF,$15  ; Metatile $D5: Object/furniture
    db $80,$0D,$8D,$43  ; Metatile $D6: Object/furniture
    db $21,$A9,$01,$8D  ; Metatile $D7: Object/furniture

    ; Metatiles $D8-$3F
    db $41,$21,$A9,$CC  ; Metatile $D8: Special graphics
    db $8D,$40,$21,$CD  ; Metatile $D9: Special graphics
    db $40,$21,$D0,$FB  ; Metatile $DA: Unknown pattern
    db $A9,$00,$EB,$BF  ; Metatile $DB: Unknown pattern
    db $08,$80,$0D,$85  ; Metatile $DC: Object/furniture
    db $14,$BF,$09,$80  ; Metatile $DD: Object/furniture
    db $0D,$85,$15,$A9  ; Metatile $DE: Object/furniture
    db $0D,$85,$16,$A0  ; Metatile $DF: Object/furniture

    ; Metatiles $E0-$3F
    db $00,$00,$B7,$14  ; Metatile $E0: Wall/building pattern
    db $18,$69,$02,$85  ; Metatile $E1: Object/furniture
    db $10,$C8,$B7,$14  ; Metatile $E2: Special graphics
    db $69,$00,$85,$11  ; Metatile $E3: Wall/building pattern
    db $C8,$B7,$14,$8D  ; Metatile $E4: Unknown pattern
    db $41,$21,$EB,$8D  ; Metatile $E5: Special graphics
    db $40,$21,$CD,$40  ; Metatile $E6: Object/furniture
    db $21,$D0,$FB,$1A  ; Metatile $E7: Unknown pattern

    ; Metatiles $E8-$3F
    db $EB,$C8,$C4,$10  ; Metatile $E8: Unknown pattern
    db $D0,$EB,$EB,$1A  ; Metatile $E9: Unknown pattern
    db $1A,$1A,$D0,$01  ; Metatile $EA: Object/furniture
    db $1A,$E8,$E8,$E0  ; Metatile $EB: Unknown pattern
    db $0C,$00,$F0,$1D  ; Metatile $EC: Object/furniture
    db $EB,$BF,$14,$80  ; Metatile $ED: Unknown pattern
    db $0D,$8D,$42,$21  ; Metatile $EE: Wall/building pattern
    db $BF,$15,$80,$0D  ; Metatile $EF: Object/furniture

    ; Metatiles $F0-$3F
    db $8D,$43,$21,$EB  ; Metatile $F0: Special graphics
    db $8D,$41,$21,$8D  ; Metatile $F1: Object/furniture
    db $40,$21,$CD,$40  ; Metatile $F2: Object/furniture
    db $21,$D0,$FB,$80  ; Metatile $F3: Unknown pattern
    db $9B,$A0,$00,$02  ; Metatile $F4: Object/furniture
    db $8C,$42,$21,$EB  ; Metatile $F5: Special graphics
    db $A9,$00,$8D,$41  ; Metatile $F6: Object/furniture
    db $21,$EB,$8D,$40  ; Metatile $F7: Special graphics

    ; Metatiles $F8-$3F
    db $21,$CD,$40,$21  ; Metatile $F8: Object/furniture
    db $D0,$FB,$EB,$8D  ; Metatile $F9: Unknown pattern
    db $40,$21,$A2,$00  ; Metatile $FA: Object/furniture
    db $01,$9D,$FF,$05  ; Metatile $FB: Special graphics
    db $CA,$D0,$FA,$A9  ; Metatile $FC: Unknown pattern
    db $FF,$85,$05,$C2  ; Metatile $FD: Unknown pattern
    db $20,$AF,$78,$9D  ; Metatile $FE: Special graphics
    db $0D,$18,$69,$00  ; Metatile $FF: Wall/building pattern

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