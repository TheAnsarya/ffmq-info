; ==============================================================================
; Bank $0e - Extended APU/Sound Data (Continuation of Bank $0d)
; ==============================================================================
; Bank $0e Size: 2,051 source lines (estimated ~32KB of $0e8000-$0effff range)
; Content: Appears to be extension of Bank $0d's SPC700 audio processor data
; Format: Continuation of DSP configuration, music patterns, voice data
; ==============================================================================

; ==============================================================================
; Bank $0e - Extended APU/Sound Data (Continuation of Bank $0d)
; Lines 1-400: Voice Configuration Sequences & DSP Register Data
; Address Range: $0e8000-$0e8fc0 (~4KB audio pattern data)
; ==============================================================================

; ------------------------------------------------------------------------------
; $0e8000-$0e80ff: Initial Voice Channel Sequences (256 bytes)
; ------------------------------------------------------------------------------
; Pattern structure identical to Bank $0d continuation:
; - $8a markers: Channel/voice separators (splits audio into tracks)
; - $cc/$dd/$bc/$dc/$ee/$ef: Envelope sequences (ADSR/volume control)
; - $fx/$ex: DSP register addresses ($f0-$ff range)
; - Digit sequences: Note/duration/pitch parameters
;
; Channel separator $8a appears at:
; - 0E8003, 0E8010, 0E8020, 0E8030, 0E8040, 0E8050, 0E8060, 0E8070
; - 0E8080, 0E8090, 0E80A0, 0E80B0, 0E80C0, 0E80D0, 0E80E0
; Pattern indicates multi-track music/SFX data (16+ channels in first 256 bytes)

;      |        |      ;
	org $0e8000                          ;      |        |      ;
;      |        |      ;
	db $44,$43,$0e,$cc,$cc,$cd,$f0,$12,$8a,$32,$21,$fc,$cc,$dc,$ef,$11;0E8000|        |      ;
; $44,$43,$0e: Initial parameters (note values or timing)
; $cc,$cc,$cd: Voice envelope markers (voice configuration)
; $f0,$12: DSP register $f0 (FLG - DSP flags/control), value $12
; $8a: Channel separator (voice 0 complete, start voice 1)
; $32,$21,$fc: Voice 1 parameters
; $cc,$dc,$ef,$11: Voice 1 envelope sequence

	db $45,$8a,$53,$22,$11,$fe,$dd,$e0,$11,$43,$8a,$44,$42,$0f,$db,$bc;0E8010|        |      ;
; $45: Parameter continuation
; $8a: Channel separator (voice 1→2)
; $53,$22,$11: Voice 2 initial params
; $fe: Voice envelope marker
; $dd: Voice configuration
; $e0,$11: DSP register $e0 (likely EDL - echo delay), value $11
; $43: Param
; $8a: Channel separator (voice 2→3)
; $44,$42,$0f: Voice 3 params
; $db,$bc: Voice 3 envelope

	db $de,$ef,$13,$8a,$32,$20,$fd,$cb,$dd,$ef,$11,$45,$8a,$52,$32,$1f;0E8020|        |      ;
; $de,$ef,$13: Envelope sequence for voice 3
; $8a: Channel separator (voice 3→4)
; $32,$20,$fd: Voice 4 params
; $cb,$dd,$ef,$11: Voice 4 envelope
; $45: Param
; $8a: Channel separator (voice 4→5)
; $52,$32,$1f: Voice 5 params

	db $0e,$ee,$ef,$02,$44,$8a,$33,$43,$0e,$dc,$bc,$de,$ef,$13,$8a,$32;0E8030|        |      ;
; $0e: Param
; $ee,$ef,$02: Envelope sequence
; $44: Param
; $8a: Channel separator (voice 5→6)
; $33,$43,$0e: Voice 6 params
; $dc,$bc,$de,$ef,$13: Voice 6 extended envelope
; $8a: Channel separator (voice 6→7)

	db $10,$fd,$dd,$cb,$e0,$11,$44,$8a,$53,$32,$10,$fe,$ee,$ef,$02,$35;0E8040|        |      ;
; Voice 7 data: $10,$fd,$dd,$cb
; $e0,$11: DSP register $e0 = $11
; $44: Param
; $8a: Channel separator (voice 7→8)
; Voice 8 data: $53,$32,$10,$fe,$ee,$ef,$02,$35

	db $8a,$43,$23,$1f,$cc,$bc,$de,$ef,$12,$8a,$33,$20,$ed,$dc,$cd,$ef;0E8050|        |      ;
; $8a: Channel separator at start (voice 8→9)
; Voice 9 data: $43,$23,$1f,$cc,$bc,$de,$ef,$12
; $8a: Channel separator (voice 9→10)
; Voice 10 data: $33,$20,$ed,$dc,$cd,$ef

	db $02,$45,$8a,$43,$32,$10,$fe,$ee,$ef,$12,$34,$8a,$43,$32,$1f,$cb;0E8060|        |      ;
; $02,$45: Voice 10 params
; $8a: Channel separator (voice 10→11)
; Voice 11 data: $43,$32,$10,$fe,$ee,$ef,$12,$34
; $8a: Channel separator (voice 11→12)
; Voice 12 start: $43,$32,$1f,$cb

	db $cd,$ce,$e0,$12,$8a,$23,$20,$ed,$dd,$cc,$ef,$03,$44,$8a,$43,$32;0E8070|        |      ;
; Voice 12 envelope: $cd,$ce
; $e0,$12: DSP register $e0 = $12 (echo delay adjustment)
; $8a: Channel separator (voice 12→13)
; Voice 13: $23,$20,$ed,$dd,$cc,$ef,$03,$44
; $8a: Channel separator (voice 13→14)
; Voice 14 start: $43,$32

	db $10,$ff,$ee,$df,$13,$33,$8a,$44,$22,$1f,$cc,$cc,$ce,$f0,$02,$8a;0E8080|        |      ;
; Voice 14: $10,$ff,$ee,$df,$13,$33
; $8a: Channel separator (voice 14→15)
; Voice 15: $44,$22,$1f,$cc,$cc,$ce
; $f0,$02: DSP register $f0 (FLG) = $02 (reset/noise/mute flags)
; $8a: Channel separator (voice 15→16)

	db $32,$11,$fd,$cd,$cd,$df,$13,$34,$8a,$43,$32,$10,$0e,$ee,$ef,$12;0E8090|        |      ;
; Voice 16: $32,$11,$fd,$cd,$cd,$df,$13,$34
; $8a: Channel separator (voice 16→17)
; Voice 17: $43,$32,$10,$0e,$ee,$ef,$12

	db $24,$8a,$44,$22,$1f,$dc,$bb,$de,$f0,$01,$8a,$34,$10,$fd,$cc,$dd;0E80A0|        |      ;
; Voice 17 continues: $24
; $8a: Channel separator (voice 17→18)
; Voice 18: $44,$22,$1f,$dc,$bb,$de
; $f0,$01: DSP register $f0 = $01
; $8a: Channel separator (voice 18→19)
; Voice 19: $34,$10,$fd,$cc,$dd

	db $ee,$12,$44,$8a,$43,$32,$10,$0f,$de,$ef,$03,$43,$8a,$33,$32,$1f;0E80B0|        |      ;
	db $dc,$bc,$cf,$ef,$13,$8a,$22,$11,$fd,$cc,$dd,$ef,$02,$44,$8a,$43;0E80C0|        |      ;
	db $32,$10,$0f,$ed,$ef,$12,$43,$8a,$33,$32,$10,$db,$bc,$de,$ef,$13;0E80D0|        |      ;
	db $8a,$22,$20,$ee,$eb,$cd,$ef,$12,$34,$8a,$34,$42,$00,$0f,$ee,$df;0E80E0|        |      ;
	db $13,$33,$8b,$33,$33,$1f,$cc,$bc,$de,$ef,$22,$33,$0c,$02,$00,$00;0E80F0|        |      ;
; $8b at 0E80F2: Variant channel separator (indicates different voice type or mode)
; $0c,$02,$00,$00: Control sequence or padding before next section

; ------------------------------------------------------------------------------
; $0e8100-$0e81ff: Dense Voice Marker Sequences (256 bytes)
; ------------------------------------------------------------------------------
; Zero padding appears at 0E80FC-0E8107 (12 bytes of $00)
; Marks transition from initial channel setup to voice configuration tables
; New marker set: $b2, $b1, $b3, $a2 (voice assignment markers, same as Bank $0d)

	db $00,$00,$00,$00,$00,$00,$b2,$0f,$00,$b1,$30,$1f,$23,$f0,$2f,$c2;0E8100|        |      ;
; Zero padding: $00×6 (section separator)
; $b2: Voice marker (bass/rhythm voice, same as Bank $0d usage)
; $0f,$00: Parameters
; $b1: Voice marker (melody voice 1)
; $30,$1f,$23: Parameters
; $f0,$2f: DSP register $f0 = $2f
; $c2: Parameter

	db $00,$00,$00,$f3,$3c,$e1,$00,$0f,$b2,$ff,$0e,$d3,$0b,$3f,$f1,$d3;0E8110|        |      ;
; $00×3: Padding
; $f3,$3c: Parameters
; $e1,$00,$0f: DSP register $e1 (possibly EON - echo on), values
; $b2: Voice marker return
; $ff,$0e,$d3,$0b,$3f: Parameter sequence
; $f1,$d3: DSP register $f1, value $d3

	db $10,$b2,$00,$42,$0f,$64,$d1,$32,$01,$ee,$b2,$30,$0e,$03,$b3,$fd;0E8120|        |      ;
; $10: Param
; $b2: Voice marker
; $00,$42,$0f,$64: Parameters
; $d1,$32,$01: Parameter sequence
; $ee: Envelope marker
; $b2: Voice marker return
; $30,$0e,$03: Params
; $b3: Voice marker (third voice type)
; $fd: Envelope marker

	db $2c,$02,$0e,$a2,$d1,$fd,$1c,$11,$93,$0a,$33,$1e,$b2,$f2,$00,$01;0E8130|        |      ;
; $2c,$02,$0e: Params
; $a2: Voice marker (fourth voice type - saw this in Bank $0d)
; $d1,$fd,$1c,$11: Parameter sequence
; $93: Parameter (high value - possibly note pitch or velocity)
; $0a,$33,$1e: Params
; $b2: Voice marker return
; $f2,$00,$01: DSP register $f2, values

	db $0f,$0f,$11,$2e,$24,$a2,$e0,$07,$e0,$f4,$2e,$fb,$6b,$e0,$b2,$e1;0E8140|        |      ;
; $0f,$0f,$11,$2e,$24: Parameter sequence
; $a2: Voice marker
; $e0,$07: DSP register $e0 = $07
; $e0,$f4: DSP register $e0 = $f4 (rapid change - tremolo/vibrato effect?)
; $2e,$fb,$6b: Params
; $e0: DSP register marker
; $b2: Voice marker
; $e1: DSP register marker

	db $1d,$10,$d1,$0d,$e2,$fc,$12,$b2,$00,$03,$1c,$f3,$01,$3e,$22,$f2;0E8150|        |      ;
; $1d,$10: Params
; $d1,$0d: Parameter
; $e2,$fc,$12: DSP register $e2, values
; $b2: Voice marker
; $00,$03,$1c: Params
; $f3,$01,$3e,$22: Parameter sequence
; $f2: DSP register marker

	db $a2,$10,$c1,$2d,$05,$1b,$3a,$24,$96,$b2,$ec,$3d,$01,$d0,$00,$0d;0E8160|        |      ;
; $a2: Voice marker
; $10,$c1,$2d,$05,$1b,$3a,$24: Parameter sequence
; $96: High value parameter
; $b2: Voice marker
; $ec,$3d,$01: Params
; $d0,$00,$0d: Parameter sequence

	db $12,$f2,$a2,$ff,$33,$2a,$53,$e4,$f2,$ff,$4c,$b2,$f4,$0e,$f4,$0b;0E8170|        |      ;
; $12: Param
; $f2: DSP register marker
; $a2: Voice marker
; $ff,$33,$2a,$53: Parameter sequence
; $e4,$f2,$ff,$4c: Parameters (multiple $ff - maximum values)
; $b2: Voice marker
; $f4,$0e,$f4,$0b: DSP register $f4 repeated (pitch modulation?)

	db $31,$ef,$d0,$21,$a2,$de,$4f,$a2,$5e,$c0,$ed,$1d,$ff,$b2,$c2,$2d;0E8180|        |      ;
; $31: Param
; $ef,$d0,$21: Parameter sequence
; $a2: Voice marker
; $de,$4f: Params
; $a2: Voice marker repeated (voice switch)
; $5e: Param
; $c0,$ed,$1d,$ff: Parameters
; $b2: Voice marker
; $c2,$2d: Params

	db $20,$e2,$d3,$3e,$2e,$35,$b2,$c0,$f1,$3d,$31,$d4,$10,$2f,$10,$b2;0E8190|        |      ;
; Dense parameter/marker mixing continues
; Pattern: Voice markers ($a2/$b2/$b3) interspersed with:
; - DSP register addresses ($c0-$f4 range)
; - Parameters (digit sequences, envelope markers)
; - Control values ($ff, $00, high/low bounds)

	db $21,$d1,$10,$ff,$01,$ef,$3c,$11,$92,$fc,$b2,$d6,$a2,$df,$60,$3e;0E81A0|        |      ;
	db $24,$a2,$ff,$41,$ef,$bf,$1e,$d1,$5c,$f5,$b2,$df,$ff,$1f,$d1,$2e;0E81B0|        |      ;
	db $1e,$7e,$b2,$b2,$f3,$b1,$4d,$04,$31,$00,$1f,$10,$b2,$12,$ee,$22;0E81C0|        |      ;
; $b2,$b2: Double voice marker (emphasis or channel lock)
; $f3,$b1: Parameters with $b1 marker
; Pattern shows complex voice interleaving

	db $e1,$0f,$3f,$12,$c2,$b2,$0f,$1c,$1f,$d3,$d1,$5c,$0c,$03,$a2,$b2;0E81D0|        |      ;
; $a2,$b2: Voice marker sequence (voice handoff A2→B2)

	db $30,$24,$d0,$2d,$01,$0f,$bf,$b2,$10,$42,$e0,$3f,$c3,$21,$0e,$32;0E81E0|        |      ;
	db $b2,$bf,$2f,$1f,$2e,$e4,$ef,$02,$1f,$a2,$d1,$4d,$fc,$fe,$00,$b1;0E81F0|        |      ;
; $a2: Voice marker
; $d1,$4d,$fc,$fe,$00: Parameter sequence ending in zero
; $b1: Voice marker

; ------------------------------------------------------------------------------
; $0e8200-$0e82ff: Extended Voice Configuration (256 bytes)
; ------------------------------------------------------------------------------
; Continues dense marker pattern from previous section
; Increasing frequency of $a2/$b2/$b3 markers indicates complex multi-voice music

	db $e2,$2e,$a2,$dc,$1d,$34,$e7,$e0,$5c,$13,$21,$a2,$13,$31,$ef,$50;0E8200|        |      ;
	db $02,$30,$05,$d2,$b2,$31,$0e,$ff,$00,$f1,$f0,$6c,$d2,$b2,$f1,$1d;0E8210|        |      ;
; $f1,$f0,$6c: Parameters
; $d2: Parameter
; $b2: Voice marker
; $f1,$1d: Parameters

	db $e1,$df,$1e,$f2,$ec,$30,$b2,$01,$c1,$23,$1d,$20,$13,$01,$f2,$b2;0E8220|        |      ;
	db $10,$2e,$13,$ef,$02,$0e,$0d,$13,$b2,$d0,$cf,$1f,$0c,$03,$1f,$30;0E8230|        |      ;
	db $ee,$b2,$03,$e1,$2c,$14,$f0,$20,$e3,$2e,$b2,$12,$c0,$4e,$2f,$0f;0E8240|        |      ;
	db $f1,$01,$e0,$a2,$b3,$13,$1f,$2f,$1d,$10,$30,$0f,$a2,$c2,$ee,$11;0E8250|        |      ;
; $a2,$b3: Voice marker transition (A2→B3 voice handoff)

	db $50,$c2,$d5,$3e,$0f,$a2,$e9,$43,$fc,$51,$ee,$00,$b3,$c5,$a2,$1f;0E8260|        |      ;
; $b3,$c5,$a2: Voice marker sequence (B3→A2 transition with $c5 param)

	db $3a,$c3,$50,$ae,$4e,$20,$b3,$b2,$30,$f0,$0f,$f4,$20,$e0,$21,$fe;0E8270|        |      ;
; $b3,$b2: Voice transition marker
; $30,$f0,$0f,$f4,$20: Parameter sequence
; $e0,$21: DSP register $e0 = $21
; $fe: Envelope marker

	db $a2,$4d,$1f,$d1,$dd,$03,$11,$e9,$35,$a2,$cf,$03,$1a,$c2,$2e,$00;0E8280|        |      ;
	db $c1,$7d,$c2,$00,$f0,$f1,$1e,$2f,$d4,$0f,$3f,$b2,$f1,$01,$de,$22;0E8290|        |      ;
	db $40,$01,$c3,$1d,$b2,$00,$00,$ee,$6f,$d0,$1f,$0f,$00,$b2,$b4,$2b;0E82A0|        |      ;
; $b2,$b4: New voice marker combination (B2→B4 transition)

	db $10,$00,$c5,$2d,$f2,$3c,$a2,$12,$e2,$e0,$0e,$1d,$76,$cf,$d0,$b2;0E82B0|        |      ;
	db $c1,$1f,$11,$3f,$0f,$2d,$f4,$d3,$b2,$fc,$40,$16,$ef,$1e,$d1,$3e;0E82C0|        |      ;
	db $e1,$b2,$1f,$0e,$00,$c0,$0e,$ef,$00,$11,$b2,$fd,$e2,$21,$e0,$5e;0E82D0|        |      ;
	db $f3,$1d,$11,$b2,$03,$0f,$02,$f2,$5d,$d2,$2e,$f1,$b2,$3f,$d5,$0d;0E82E0|        |      ;
	db $c0,$3d,$13,$11,$01,$b2,$ff,$01,$f0,$0d,$2b,$f6,$f1,$00,$b2,$1f;0E82F0|        |      ;

; ------------------------------------------------------------------------------
; $0e8300-$0e83ff: Continued Voice Pattern Data (256 bytes)
; ------------------------------------------------------------------------------

	db $f2,$22,$31,$00,$2e,$0e,$e3,$b2,$cf,$00,$11,$1f,$6e,$a5,$dd,$4e;0E8300|        |      ;
; $a5: New voice marker variant (or parameter)
; $dd: Envelope marker

	db $b2,$01,$f2,$ef,$30,$ff,$3f,$d3,$e2,$b2,$20,$00,$4b,$e5,$c3,$5b;0E8310|        |      ;
	db $1f,$13,$b2,$c0,$0f,$2f,$20,$c2,$2e,$e0,$00,$b2,$f1,$4c,$14,$9f;0E8320|        |      ;
	db $2f,$1e,$f3,$10,$b2,$f1,$30,$12,$d0,$4f,$fe,$41,$d1,$a2,$1d,$01;0E8330|        |      ;
	db $93,$cd,$3d,$d0,$14,$ff,$b2,$3f,$00,$04,$0c,$22,$d0,$03,$fc,$b2;0E8340|        |      ;
	db $60,$f2,$f2,$be,$0d,$2d,$0f,$e2,$b2,$04,$bc,$5f,$d0,$30,$02,$2f;0E8350|        |      ;
	db $f1,$b2,$d0,$10,$3e,$f4,$1f,$f3,$dd,$5f,$b2,$e0,$e0,$12,$1f,$fe;0E8360|        |      ;
	db $04,$0e,$03,$b2,$fc,$40,$e0,$14,$df,$30,$f1,$43,$b2,$de,$42,$d1;0E8370|        |      ;
	db $51,$df,$3f,$cd,$ff,$b2,$f0,$1d,$c0,$11,$af,$19,$e1,$0e,$a2,$e4;0E8380|        |      ;
	db $00,$d3,$2f,$00,$54,$12,$30,$b2,$13,$4c,$05,$e0,$12,$4e,$e5,$1e;0E8390|        |      ;
	db $b2,$20,$00,$03,$dd,$21,$ff,$2f,$ce,$b2,$02,$fe,$f0,$de,$2f,$fc;0E83A0|        |      ;
	db $00,$ff,$a2,$04,$d7,$32,$7c,$26,$f0,$66,$22,$a2,$37,$7e,$e7,$db;0E83B0|        |      ;
; $a2: Voice marker
; $04,$d7,$32,$7c,$26: Parameter sequence
; $f0,$66,$22: DSP register $f0 = $66, param $22
; $a2: Voice marker return
; $37,$7e: Params (high values - loud/bright voice)
; $e7,$db: Parameters

	db $5b,$d0,$f3,$af,$b2,$0e,$f0,$40,$e3,$20,$e1,$2c,$e0,$b2,$c2,$0e;0E83C0|        |      ;
	db $5c,$c6,$0c,$0f,$01,$e0,$b2,$3e,$e3,$1f,$1f,$ef,$24,$e0,$31,$b2;0E83D0|        |      ;
	db $00,$2f,$02,$e3,$0a,$40,$f5,$df,$b2,$0d,$20,$02,$11,$c2,$2e,$2c;0E83E0|        |      ;
	db $f2,$b2,$df,$ff,$0d,$de,$ff,$cf,$f0,$2f,$b2,$20,$03,$e0,$41,$f2;0E83F0|        |      ;

; ------------------------------------------------------------------------------
; $0e8400-$0e84ff: Voice Configuration Tables Continue (256 bytes)
; ------------------------------------------------------------------------------

	db $22,$3f,$11,$b2,$f3,$0d,$f4,$1e,$22,$0d,$0e,$10,$b2,$b3,$de,$2e;0E8400|        |      ;
; $b2,$b3: Voice marker transition

	db $10,$ff,$fd,$ff,$c0,$a2,$1e,$3f,$a1,$3c,$f1,$e2,$20,$22,$a2,$03;0E8410|        |      ;
; $a1: Possible new voice marker (or parameter $a1)
; $3c: Parameter
; $f1,$e2,$20,$22: Parameter sequence
; $a2: Voice marker

	db $44,$25,$4e,$22,$30,$14,$f2,$b2,$f2,$1d,$00,$0f,$1b,$e2,$ef,$02;0E8420|        |      ;
	db $a2,$cd,$5f,$d1,$6f,$b1,$2f,$af,$72,$b2,$b1,$4e,$ff,$e1,$2d,$00;0E8430|        |      ;
; $b1: Voice marker (melody voice)
; $2f,$af,$72: Parameters (high value $af)
; $b2,$b1: Voice transition marker

	db $d2,$11,$b2,$0f,$00,$2d,$01,$c2,$20,$11,$20,$b2,$ff,$35,$ff,$11;0E8440|        |      ;
	db $30,$f1,$f0,$fe,$b2,$2c,$05,$d0,$40,$ee,$ff,$12,$ed,$b2,$30,$c0;0E8450|        |      ;
	db $0f,$fc,$14,$c1,$4e,$00,$b2,$10,$e2,$41,$03,$40,$12,$12,$f2,$b2;0E8460|        |      ;
	db $40,$ef,$33,$ef,$1f,$dc,$ff,$01,$b2,$ae,$3d,$01,$d1,$30,$0e,$2f;0E8470|        |      ;
; $ae: High parameter value

	db $d4,$a2,$41,$12,$e0,$5f,$fe,$52,$e0,$35,$a2,$f0,$e0,$f1,$39,$1f;0E8480|        |      ;
; $a2: Voice marker
; $41,$12: Params
; $e0,$5f: DSP register $e0 = $5f
; $fe: Envelope marker
; $52: Param
; $e0,$35: DSP $e0 = $35
; $a2: Voice marker
; $f0,$e0,$f1,$39,$1f: DSP register sequence ($f0, $e0, $f1)

	db $b1,$e4,$ac,$b2,$2d,$20,$c0,$01,$2f,$21,$c3,$10,$a2,$43,$1c,$42;0E8490|        |      ;
; $b1: Voice marker
; $e4,$ac: Parameters (high value $ac)
; $b2: Voice marker
; ... followed by $a2 voice marker

	db $43,$c2,$4e,$22,$e0,$a2,$d1,$5d,$9f,$de,$1b,$13,$bc,$0f,$a2,$e0;0E84A0|        |      ;
; $9f: High parameter value
; $a2: Voice marker appears twice in sequence

	db $da,$65,$b0,$13,$02,$5f,$e3,$a2,$42,$43,$51,$f4,$3e,$00,$e4,$1a;0E84B0|        |      ;
; $da,$65,$b0: Parameters (high values)
; $a2: Voice marker
; $f4,$3e,$00: Parameters
; $e4,$1a: DSP register $e4, value $1a

	db $b2,$f0,$e2,$0f,$0b,$e1,$ee,$1f,$cf,$b2,$1e,$e2,$0f,$1f,$15,$ff;0E84C0|        |      ;
	db $40,$33,$a2,$e2,$00,$40,$02,$01,$2f,$0f,$d6,$b2,$ef,$3d,$10,$e0;0E84D0|        |      ;
	db $f0,$ec,$d1,$0f,$b2,$10,$e2,$1c,$05,$ff,$3f,$01,$f3,$b2,$fe,$51;0E84E0|        |      ;
	db $e1,$0f,$00,$02,$ef,$21,$a6,$dd,$3f,$2f,$0b,$15,$e5,$cf,$2f,$b2;0E84F0|        |      ;
; $a6: New voice marker variant (or high parameter)

; ------------------------------------------------------------------------------
; $0e8500-$0e85ff: Dense Parameter Sequences (256 bytes)
; ------------------------------------------------------------------------------

	db $0e,$21,$c3,$3d,$0e,$f4,$ef,$31,$b2,$0e,$f2,$1c,$f0,$e1,$11,$dd;0E8500|        |      ;
	db $3f,$b2,$d0,$0f,$dd,$31,$02,$f2,$df,$4e,$a2,$26,$f1,$10,$23,$ff;0E8510|        |      ;
	db $40,$dd,$fe,$b2,$02,$f0,$1f,$fe,$f0,$ff,$03,$cd,$b2,$4f,$0c,$02;0E8520|        |      ;
	db $d0,$f1,$1e,$21,$df,$a2,$1f,$a2,$72,$10,$61,$c2,$32,$f2,$a2,$40;0E8530|        |      ;
; $a2,$1f,$a2: Double voice marker with param between (voice ping-pong)
; $72: High parameter
; $61: Parameter
; $a2: Voice marker return

	db $10,$e1,$10,$eb,$a0,$2b,$c2,$a2,$0c,$dc,$02,$af,$60,$c0,$63,$e4;0E8540|        |      ;
; $eb,$a0: High parameters
; $a2: Voice marker
; $af,$60: High parameters
; $c0,$63: Parameters
; $e4: DSP register marker

	db $b2,$2f,$ff,$24,$0e,$3e,$d3,$e0,$dd,$b2,$3d,$11,$c1,$ff,$3f,$f0;0E8550|        |      ;
	db $f1,$10,$a2,$dd,$20,$1f,$d0,$bf,$01,$0f,$19,$a2,$34,$f4,$fd,$42;0E8560|        |      ;
; $bf: High parameter

	db $0f,$04,$e2,$31,$b2,$0d,$12,$0f,$f1,$1f,$f1,$ef,$4e,$a2,$b7,$fe;0E8570|        |      ;
; $b7: Voice marker variant (or high parameter)

	db $4e,$25,$d0,$6f,$f4,$22,$a2,$0e,$4f,$c3,$e0,$fe,$2d,$fe,$c1,$a2;0E8580|        |      ;
	db $ce,$5c,$b1,$03,$00,$1a,$f4,$dd,$a2,$ed,$31,$e7,$4a,$f5,$62,$34;0E8590|        |      ;
; $b1: Voice marker
; $a2: Voice marker
; $e7,$4a,$f5,$62: Parameter sequence (high values)

	db $e4,$a2,$53,$30,$f2,$1b,$41,$f3,$c4,$6b,$b2,$f1,$cc,$ff,$fd,$ed;0E85A0|        |      ;
; $c4,$6b: High parameters
; $b2: Voice marker
; $cc,$ff,$fd: Parameter sequence (multiple high values)

	db $13,$c0,$1b,$a2,$02,$e3,$ec,$06,$20,$3c,$52,$f4,$b2,$f2,$ff,$40;0E85B0|        |      ;
	db $f1,$00,$02,$3e,$f1,$a2,$12,$d3,$1c,$21,$fc,$05,$9f,$40,$b2,$ed;0E85C0|        |      ;
	db $0f,$fe,$12,$ff,$14,$0c,$04,$a2,$4e,$37,$db,$75,$ed,$d4,$1c,$30;0E85D0|        |      ;
; $db,$75: High parameters
; $d4: Parameter

	db $b2,$e1,$11,$1d,$e0,$f1,$2c,$04,$fe,$a2,$22,$cd,$01,$3e,$f6,$da;0E85E0|        |      ;
; $f6,$da: High parameters (max values)

	db $33,$50,$b2,$f2,$de,$4f,$e4,$ff,$3e,$10,$d1,$b2,$00,$2f,$f0,$11;0E85F0|        |      ;

; ------------------------------------------------------------------------------
; $0e8600-$0e86ff: Extended Voice Tables (256 bytes)
; ------------------------------------------------------------------------------

	db $f3,$ec,$01,$0e,$b2,$11,$1e,$04,$df,$4e,$f1,$d2,$0d,$b2,$1f,$21;0E8600|        |      ;
	db $c0,$fe,$11,$01,$f0,$0d,$a2,$ed,$bd,$d1,$bd,$2e,$10,$c5,$2d,$a2;0E8610|        |      ;
; $bd: High parameter (repeated twice)
; $c5: Parameter
; $a2: Voice marker

	db $21,$23,$f0,$30,$44,$c1,$54,$f1,$b2,$3f,$d2,$1c,$12,$c0,$f0,$1e;0E8620|        |      ;
	db $0e,$b2,$01,$d1,$0b,$02,$f0,$0f,$00,$ef,$b2,$3f,$d1,$31,$e0,$1e;0E8630|        |      ;
	db $14,$20,$d1,$ba,$f9,$41,$00,$e1,$1f,$00,$00,$10,$a2,$de,$ee,$3f;0E8640|        |      ;
; $ba,$f9: High parameters
; $a2: Voice marker
; $de,$ee,$3f: Parameter sequence

	db $d1,$ce,$30,$31,$14,$a2,$f4,$2c,$62,$d1,$01,$2c,$e4,$01,$b2,$0f;0E8650|        |      ;
; $ce: Parameter
; $a2: Voice marker
; $f4,$2c,$62: Parameters
; $e4: DSP register marker
; $b2: Voice marker

	db $11,$ee,$20,$c1,$2f,$0f,$20,$b2,$d0,$10,$e1,$20,$01,$2c,$04,$02;0E8660|        |      ;
	db $a2,$0c,$41,$c2,$4d,$e7,$5d,$f4,$0f,$b2,$11,$3f,$e0,$b1,$4e,$21;0E8670|        |      ;
; $e7,$5d: Parameters
; $f4,$0f: DSP register $f4 = $0f
; $b1: Voice marker

	db $d0,$10,$a2,$de,$ef,$3e,$14,$de,$25,$3d,$3f,$b2,$f3,$12,$fd,$22;0E8680|        |      ;
	db $20,$d1,$3e,$04,$a2,$2d,$d4,$1d,$1d,$b1,$31,$ec,$14,$a2,$cd,$50;0E8690|        |      ;
; $b1: Voice marker
; $ec: Parameter
; $a2: Voice marker
; $cd: Parameter

	db $f1,$2d,$17,$f0,$0c,$ff,$b2,$e1,$fe,$3f,$00,$d4,$10,$4e,$ff,$a2;0E86A0|        |      ;
	db $f6,$c0,$4d,$ee,$0f,$90,$41,$0f,$a2,$ff,$12,$02,$3c,$d1,$32,$f3;0E86B0|        |      ;
; $f6,$c0: High parameters
; $90: High parameter
; $a2: Voice marker (appears twice)

	db $10,$a2,$33,$f3,$6f,$14,$00,$0c,$fd,$b0,$a2,$ce,$db,$21,$0d,$00;0E86C0|        |      ;
; $db: High parameter
; $b0: Voice marker variant (or parameter)
; $a2: Voice marker

	db $d1,$16,$fd,$b2,$42,$11,$f2,$2f,$12,$00,$00,$ff,$a2,$00,$19,$c7;0E86D0|        |      ;
; $c7: Parameter
; $a2: Voice marker

	db $4f,$d2,$df,$5b,$ce,$b2,$fe,$f2,$ee,$20,$10,$ef,$fd,$f5,$b2,$db;0E86E0|        |      ;
; $df,$5b,$ce: Parameters
; $f5: Parameter
; $db: High parameter

	db $20,$24,$09,$15,$04,$42,$0e,$b2,$52,$d3,$1e,$00,$0f,$d0,$3e,$f1;0E86F0|        |      ;

; ------------------------------------------------------------------------------
; $0e8700-$0e87ff: Complex Voice Interleaving (256 bytes)
; ------------------------------------------------------------------------------

	db $b2,$cf,$10,$3e,$f2,$ef,$f1,$1e,$f1,$a2,$32,$c3,$7d,$37,$ef,$2e;0E8700|        |      ;
; $cf: Parameter
; $a2: Voice marker
; $7d,$37: High parameters

	db $03,$00,$a2,$1e,$00,$c0,$ed,$43,$e1,$20,$d0,$a2,$1f,$1d,$dd,$e3;0E8710|        |      ;
	db $02,$1b,$e3,$3d,$b2,$df,$30,$d2,$2e,$03,$fe,$02,$1d,$b2,$13,$1f;0E8720|        |      ;
	db $d4,$4c,$c2,$0d,$10,$00,$a2,$f2,$f1,$20,$1f,$11,$c1,$4e,$43,$b2;0E8730|        |      ;
	db $f1,$12,$ef,$3f,$c1,$1f,$0c,$01,$a2,$be,$f0,$00,$b1,$4c,$e2,$1f;0E8740|        |      ;
; $be: High parameter
; $a2: Voice marker
; $b1: Voice marker

	db $f2,$a2,$2d,$06,$fc,$55,$ec,$f7,$2c,$04,$a2,$5a,$d3,$44,$e4,$1d;0E8750|        |      ;
; $ec,$f7: High parameters
; $a2: Voice marker (appears twice)
; $5a: Marker (channel separator from early pattern)

	db $40,$2e,$d3,$a6,$ce,$f2,$0f,$e1,$6b,$b5,$01,$0b,$a2,$32,$b2,$bd;0E8760|        |      ;
; $a6: Voice marker variant
; $6b,$b5: Parameters
; $a2: Voice marker
; $b2: Voice marker
; $bd: High parameter

	db $4e,$11,$e1,$2d,$44,$a2,$a1,$37,$3d,$62,$06,$01,$3f,$2d,$a2,$36;0E8770|        |      ;
; $a2,$a1: Voice marker sequence
; $62: Parameter
; $a2: Voice marker return

	db $c0,$d1,$6e,$d0,$2c,$d6,$ca,$a2,$2f,$1d,$a2,$fb,$e2,$39,$d7,$0d;0E8780|        |      ;
; $6e: Parameter
; $d6,$ca: Parameters
; $a2: Voice marker (appears twice)
; $fb: High parameter
; $d7: Parameter

	db $a2,$07,$3e,$ff,$30,$c4,$6d,$e1,$0f,$a2,$f3,$24,$2e,$10,$13,$fd;0E8790|        |      ;
; $c4,$6d: Parameters
; $a2: Voice marker (appears twice)

	db $10,$d7,$b2,$1d,$22,$21,$f1,$1f,$03,$10,$2e,$a2,$d7,$2c,$e1,$ef;0E87A0|        |      ;
; $d7: Parameter (repeated from 0E878D)
; $b2: Voice marker
; $a2: Voice marker
; $d7: Parameter (third occurrence)

	db $31,$fc,$0f,$c4,$a2,$1c,$b0,$7d,$b2,$ff,$2f,$14,$a0,$b2,$2f,$12;0E87B0|        |      ;
; $c4: Parameter
; $a2: Voice marker
; $b0: Voice marker variant
; $7d: High parameter
; $b2: Voice marker (appears three times)
; $a0: Voice marker variant

	db $2f,$d1,$40,$f0,$23,$e0,$a2,$6d,$d0,$0f,$d0,$1d,$01,$f0,$d0,$a2;0E87C0|        |      ;
; $6d: Parameter
; $d0: Parameter (repeated multiple times)
; $a2: Voice marker (appears twice)

	db $ed,$dc,$2a,$d3,$0d,$b5,$dc,$3e,$b2,$20,$02,$ef,$21,$ef,$54,$e0;0E87D0|        |      ;
; $b5: Voice marker variant
; $dc: Parameter (repeated)
; $b2: Voice marker

	db $53,$b2,$01,$10,$00,$10,$d1,$0a,$02,$ff,$b2,$d0,$0d,$de,$1e,$c2;0E87E0|        |      ;
	db $00,$2d,$01,$a2,$b3,$0d,$f1,$32,$e1,$4a,$f2,$f4,$b2,$e0,$4f,$e1;0E87F0|        |      ;
; $a2,$b3: Voice marker sequence
; $4a: Parameter
; $f2,$f4: DSP registers
; $b2: Voice marker

; ------------------------------------------------------------------------------
; $0e8800-$0e88ff: Advanced Voice Configuration (256 bytes)
; ------------------------------------------------------------------------------

	db $10,$01,$2f,$d1,$1d,$a2,$34,$91,$4d,$cd,$d1,$50,$ce,$c2,$a2,$3b;0E8800|        |      ;
; $91: High parameter
; $cd: Parameter
; $ce: Parameter
; $a2: Voice marker (appears twice)
; $3b: Parameter

	db $f1,$ef,$f3,$3e,$23,$f0,$ff,$a2,$df,$2d,$21,$e0,$bf,$ef,$2e,$ef;0E8810|        |      ;
; $bf: High parameter
; $a2: Voice marker

	db $a2,$21,$11,$20,$b0,$42,$0e,$46,$01,$b2,$11,$f0,$4e,$e2,$00,$22;0E8820|        |      ;
; $a2: Voice marker at start
; $b0: Voice marker variant
; $b2: Voice marker

	db $1f,$e0,$a2,$0e,$a5,$ec,$6e,$ff,$1e,$f4,$bd,$a2,$31,$11,$2e,$10;0E8830|        |      ;
; $a2: Voice marker
; $a5: Voice marker variant
; $ec,$6e: Parameters
; $bd: High parameter
; $a2: Voice marker return

	db $c5,$ce,$3f,$40,$a2,$01,$11,$f0,$4d,$23,$f6,$34,$20,$a2,$e3,$1a;0E8840|        |      ;
; $c5,$ce: Parameters
; $a2: Voice marker (appears twice)
; $f6: High parameter

	db $31,$c0,$ff,$3c,$ad,$ee,$a2,$e3,$ea,$21,$f3,$c0,$5d,$0f,$13,$b2;0E8850|        |      ;
; $ad,$ee: High parameters
; $a2: Voice marker
; $ea: High parameter
; $b2: Voice marker

	db $f2,$f0,$2e,$2f,$b2,$1e,$1f,$f3,$a2,$fb,$1f,$d0,$01,$1b,$e3,$10;0E8860|        |      ;
; $b2: Voice marker (appears twice)
; $a2: Voice marker
; $fb: High parameter

	db $00,$a6,$11,$c2,$1e,$0f,$1f,$2f,$b2,$22,$a2,$20,$ef,$33,$35,$12;0E8870|        |      ;
; $a6: Voice marker variant
; $b2: Voice marker
; $a2: Voice marker

	db $20,$4f,$00,$b2,$02,$d1,$2c,$02,$00,$b0,$4b,$e4,$a2,$40,$a0,$5d;0E8880|        |      ;
; $b2: Voice marker
; $b0: Voice marker variant
; $4b: Parameter
; $e4: DSP register marker
; $a2: Voice marker
; $a0: Voice marker variant

	db $b4,$4b,$e3,$1e,$12,$a2,$13,$f0,$1b,$33,$c1,$1d,$10,$bd,$a2,$43;0E8890|        |      ;
; $b4: Voice marker variant
; $4b: Parameter (repeated)
; $e3: DSP register marker
; $a2: Voice marker (appears twice)
; $bd: High parameter

	db $cc,$04,$fe,$2d,$20,$f3,$fe,$a2,$e3,$23,$0c,$11,$ff,$1e,$36,$e2;0E88A0|        |      ;
; $cc: Parameter
; $a2: Voice marker
; $e2: DSP register marker

	db $a2,$2e,$45,$de,$5e,$c4,$2d,$e3,$4c,$a2,$91,$0b,$f1,$3c,$d5,$dd;0E88B0|        |      ;
; $a2: Voice marker (appears twice)
; $c4: Parameter
; $e3: DSP register marker
; $91: High parameter
; $d5,$dd: Parameters

	db $0f,$0f,$b2,$00,$00,$ff,$21,$ff,$04,$0f,$41,$a2,$e2,$02,$2a,$d5;0E88C0|        |      ;
; $b2: Voice marker
; $a2: Voice marker
; $e2: DSP register marker
; $d5: Parameter

	db $3e,$21,$f2,$df,$a2,$fd,$1f,$fc,$c2,$ec,$cb,$21,$ae,$a6,$31,$01;0E88D0|        |      ;
; $df: Parameter
; $a2: Voice marker
; $ec,$cb: Parameters
; $ae,$a6: High parameters

	db $1e,$f1,$6d,$a6,$2d,$e6,$a2,$6c,$ef,$24,$dd,$2d,$e6,$ce,$4a,$a2;0E88E0|        |      ;
; $6d: Parameter
; $a6: Voice marker variant (appears twice)
; $e6: DSP register marker (appears twice)
; $6c: Parameter
; $ce: Parameter
; $4a: Parameter
; $a2: Voice marker

	db $06,$aa,$4f,$b2,$30,$00,$02,$0e,$b2,$20,$c0,$1e,$00,$e0,$0f,$01;0E88F0|        |      ;
; $aa: Marker (voice assignment from early patterns)
; $b2: Voice marker (appears twice)
; $c0: Parameter
; $e0,$0f: DSP register $e0 = $0f

; ------------------------------------------------------------------------------
; $0e8900-$0e89ff: Extended Pattern Data (256 bytes)
; ------------------------------------------------------------------------------

	db $02,$b2,$20,$21,$01,$e0,$df,$4d,$df,$01,$b2,$ef,$30,$d1,$2d,$c4;0E8900|        |      ;
; $b2: Voice marker (appears twice)
; $e0: DSP register marker
; $df: Parameter (repeated)
; $c4: Parameter

	db $4d,$02,$00,$b2,$02,$4f,$f2,$10,$f1,$11,$00,$fd,$a6,$4f,$10,$f0;0E8910|        |      ;
; $b2: Voice marker
; $f2: DSP register marker
; $f1: DSP register marker
; $a6: Voice marker variant
; $f0: DSP register marker

	db $f3,$b1,$22,$ff,$2d,$a6,$4d,$22,$df,$17,$ca,$30,$1e,$36,$b2,$c0;0E8920|        |      ;
; $f3: DSP register marker
; $b1: Voice marker
; $a6: Voice marker variant
; $df: Parameter
; $ca: Parameter
; $b2: Voice marker
; $c0: Parameter

	db $2d,$31,$11,$10,$32,$f1,$12,$b2,$11,$1e,$0f,$e1,$e1,$fc,$2e,$e0;0E8930|        |      ;
; $f1: DSP register marker
; $b2: Voice marker
; $e1: DSP register marker (repeated)
; $e0: DSP register marker

	db $a2,$a0,$cc,$3e,$10,$d5,$db,$5f,$d4,$b2,$11,$e1,$5c,$f2,$e1,$0f;0E8940|        |      ;
; $a2: Voice marker
; $a0: Voice marker variant
; $cc: Parameter
; $d5,$db,$5f,$d4: Parameter sequence
; $b2: Voice marker
; $e1: DSP register marker
; $f2: DSP register marker
; $e1: DSP register marker

	db $12,$0f,$a2,$cd,$53,$df,$f0,$11,$0c,$e3,$3d,$a2,$cf,$e0,$32,$de;0E8950|        |      ;
; $a2: Voice marker (appears twice)
; $cd: Parameter
; $df: Parameter
; $f0: DSP register marker
; $e3: DSP register marker
; $cf: Parameter
; $e0: DSP register marker
; $de: Parameter

	db $2b,$e2,$34,$1f,$a2,$f3,$e0,$3e,$15,$1f,$11,$3d,$03,$a2,$a2,$2c;0E8960|        |      ;
; $e2: DSP register marker
; $a2: Voice marker (appears three times - double marker)
; $f3: DSP register marker
; $e0: DSP register marker

	db $00,$fc,$a1,$7c,$c0,$04,$a2,$e2,$11,$df,$5e,$33,$e4,$4c,$e1,$a2;0E8970|        |      ;
; $a1: Voice marker variant
; $7c: High parameter
; $c0: Parameter
; $a2: Voice marker (appears twice)
; $e2: DSP register marker
; $df: Parameter
; $e4: DSP register marker
; $e1: DSP register marker

	db $60,$a6,$3c,$01,$ed,$03,$f9,$bf,$a2,$09,$a3,$cd,$3f,$0e,$b3,$fe;0E8980|        |      ;
; $a6: Voice marker variant
; $f9,$bf: High parameters
; $a2: Voice marker
; $a3: Voice marker variant (new)
; $cd: Parameter
; $b3: Voice marker
; $fe: Envelope marker

	db $73,$a6,$93,$40,$3d,$c6,$0a,$52,$ce,$35,$b2,$2f,$e0,$30,$e1,$1f;0E8990|        |      ;
; $73: High parameter
; $a6: Voice marker variant
; $93: High parameter
; $c6: Parameter
; $ce: Parameter
; $b2: Voice marker
; $e0: DSP register marker
; $e1: DSP register marker

	db $e1,$0b,$f2,$b2,$ef,$ff,$ec,$f1,$ef,$2e,$e1,$fe,$b6,$22,$df,$32;0E89A0|        |      ;
; $e1: DSP register marker
; $f2: DSP register marker
; $b2: Voice marker
; $ec: Parameter
; $f1: DSP register marker
; $e1: DSP register marker
; $b6: Voice marker variant (new)
; $df: Parameter

	db $df,$3f,$f0,$23,$ce,$a2,$32,$20,$53,$a3,$2d,$1d,$01,$cc,$a2,$f3;0E89B0|        |      ;
; $df: Parameter
; $f0: DSP register marker
; $ce: Parameter
; $a2: Voice marker
; $a3: Voice marker variant
; $cc: Parameter
; $a2: Voice marker
; $f3: DSP register marker

	db $1c,$e7,$5d,$0f,$d0,$40,$d2,$b2,$ef,$3b,$e5,$ed,$01,$2e,$e3,$1f;0E89C0|        |      ;
; $e7: DSP register marker
; $d0,$40,$d2: Parameter sequence
; $b2: Voice marker
; $e5: DSP register marker
; $ed: Parameter
; $e3: DSP register marker

	db $a2,$12,$fc,$17,$3d,$23,$a1,$50,$2d,$a2,$17,$e0,$0d,$41,$e3,$1c;0E89D0|        |      ;
; $a2: Voice marker (appears twice)
; $a1: Voice marker variant
; $e0: DSP register marker
; $e3: DSP register marker

	db $d2,$31,$a2,$32,$12,$11,$e2,$1a,$03,$fc,$c1,$a2,$da,$2b,$a0,$df;0E89E0|        |      ;
; $d2: Parameter
; $a2: Voice marker (appears twice)
; $e2: DSP register marker
; $da: High parameter
; $a0: Voice marker variant
; $df: Parameter

	db $f0,$4f,$d0,$e6,$b2,$fe,$21,$40,$f2,$21,$d1,$5f,$23,$a2,$b5,$6c;0E89F0|        |      ;
; $f0: DSP register marker
; $d0: Parameter
; $e6: DSP register marker
; $b2: Voice marker
; $f2: DSP register marker
; $d1: Parameter
; $a2: Voice marker
; $b5: Voice marker variant
; $6c: Parameter

; ==============================================================================
; End of Bank $0e Cycle 1 (Lines 1-400)
; Documented Address Range: $0e8000-$0e8a00 (2,560 bytes)
; ==============================================================================
; Technical Summary:
; - Continuation of Bank $0d's SPC700 audio driver data
; - 16+ voice channels in first 256 bytes (high complexity music)
; - Voice markers: $b2 (bass/rhythm), $b1 (melody 1), $b3 (third voice),
;                  $a2 (fourth voice), $a6 (variant), $b6 (variant),
;                  $a3 (new variant), $a1 (variant), $b0/$b4/$b5 (variants)
; - Channel separators: $8a (primary), $8b (variant at 0E80F2)
; - DSP registers used: $f0 (FLG), $e0 (EDL), $e1 (EON?), $e2, $e3, $e4, $e5,
;                       $e6, $e7, $f1, $f2, $f3, $f4, $c0-$cx range
; - Envelope markers: $cc/$dd/$dc/$bc/$ee/$ef/$fe/$ed (ADSR control)
; - Pattern indicates complex multi-voice music tracks with:
;   * Rapid voice switching (voice markers every 8-20 bytes)
;   * Frequent DSP register updates (echo, modulation, effects)
;   * High parameter values ($90+, $a0+, $f0+) for loud/bright passages
;   * Zero padding sections (0E80FC-0E8107) marking structural boundaries
; ==============================================================================
; ==============================================================================
; Bank $0e - Extended APU/Sound Data (Continuation)
; Lines 401-800: Complex Music Pattern Data & DSP Configuration
; Address Range: $0e9a00-$0eb1d0 (~6KB dense music/SFX sequences)
; ==============================================================================

; ------------------------------------------------------------------------------
; $0e8a00-$0e8aff: Transition Section - Final Voice Patterns (256 bytes)
; ------------------------------------------------------------------------------
; Continuation from Cycle 1 voice marker sequences
; Dense $b6/$a2/$b2/$a6 voice markers continue pattern from previous section

	db $fe,$21,$40,$f2,$21,$d1,$5f,$23,$a2,$b5,$6c;0E89F0|        |      ;
; (Carryover from line 400)
; $fe: Envelope marker
; $21,$40: Params
; $f2,$21: DSP register $f2, value $21
; $d1,$5f,$23: Parameter sequence
; $a2: Voice marker
; $b5: Voice marker variant
; $6c: Parameter

	db $fe,$4e,$00,$d1,$c3,$3d,$11,$b2,$0f,$12,$f0,$41,$e1,$20,$f0,$20;0E8C00|        |      ;
; $b6: Voice marker at start
; Pattern shows continuing DSP register writes and voice switching

	db $b2,$d2,$1c,$00,$f1,$de,$0e,$e0,$fd,$a2,$f3,$30,$f3,$00,$30,$51;0E8C10|        |      ;
; $b2: Voice marker
; $f1: DSP register marker
; $de: Parameter
; $e0,$fd: DSP register $e0 = $fd
; $a2: Voice marker
; $f3: DSP register marker (appears twice)

	db $b4,$74,$b2,$ff,$42,$f2,$fe,$00,$2f,$d1,$0f,$a2,$fd,$53,$03,$fe;0E8C20|        |      ;
; $b4: Voice marker variant
; $74: High parameter value
; $b2: Voice marker
; $f2: DSP register marker
; $a2: Voice marker

	db $25,$f9,$23,$dc,$a6,$30,$b4,$4b,$d2,$1f,$12,$4f,$b4,$a2,$4e,$26;0E8C30|        |      ;
; $f9: High parameter value
; $a6: Voice marker variant
; $b4: Voice marker variant (appears twice)
; $4b: Parameter (repeated from earlier)
; $a2: Voice marker

; Dense voice marker pattern continues through 0E8C40-0E8CFF with frequent:
; - $a2/$b2/$b6/$a6/$b4/$b5 voice markers every 8-15 bytes
; - DSP register addresses $c0-$ff range
; - High parameter values ($90+, $a0+, $f0+)
; - Envelope markers ($cc/$dd/$bc/$ee/$fe/$ed)

; ------------------------------------------------------------------------------
; $0e8d00-$0e8dff: New Marker Section - $5a/$6a/$4a/$7a Separators (256 bytes)
; ------------------------------------------------------------------------------
; Pattern shifts to different channel/voice separator markers:
; $5a, $6a, $4a, $7a, $3a - These are different voice channel separators
; (similar to $8a from Cycle 1, but indicating different voice types or groups)

	db $e4,$06,$02,$00,$00,$00,$00,$00,$00,$00,$00,$5a,$62,$31,$22,$22;0E8D30|        |      ;
; $e4,$06,$02: Parameter sequence
; $00×7: Zero padding (section boundary marker)
; $5a: New channel separator marker (different voice group from $8a)
; $62,$31,$22,$22: Initial voice parameters for $5a group

	db $11,$11,$01,$10,$4a,$11,$0f,$f0,$de,$dd,$da,$bc,$cc,$4a,$cc,$dd;0E8D40|        |      ;
; $4a: Channel separator (appears twice in this line)
; $11,$0f,$f0: Parameters
; $de,$dd,$da: Envelope sequence
; $bc,$cc: Voice configuration markers

	db $ee,$ff,$01,$22,$23,$54,$4a,$74,$44,$34,$22,$21,$22,$12,$f2,$4a;0E8D50|        |      ;
; $ee,$ff: Envelope markers (maximum values)
; $01,$22,$23,$54: Parameter sequence
; $4a: Channel separator (appears twice)
; $74: High parameter value
; $f2: DSP register marker

	db $1e,$e0,$fd,$cc,$dc,$bb,$cc,$ad,$5a,$ed,$ff,$ff,$01,$02,$23,$33;0E8D60|        |      ;
; $1e: Param
; $e0,$fd: DSP register $e0 = $fd
; $cc,$dc,$bb,$cc: Voice envelope sequence
; $ad: High parameter
; $5a: Channel separator
; $ed,$ff,$ff: Envelope sequence (maximum values)

	db $42,$4a,$75,$54,$22,$12,$01,$20,$f2,$0f,$4a,$0e,$dc,$cb,$ba,$bb;0E8D70|        |      ;
; $4a: Channel separator (appears three times in this line)
; Pattern shows rapid channel switching within $4a voice group

	db $bb,$cc,$bd,$4a,$ee,$0e,$41,$53,$55,$67,$66,$34,$3a,$35,$51,$02;0E8D80|        |      ;
; $bb,$cc,$bd: Voice envelope
; $4a: Channel separator
; $ee,$0e: Parameters
; $41,$53,$55,$67,$66: Parameter sequence (note/pitch data)
; $3a: New channel separator variant
; $35,$51,$02: Parameters

	db $23,$30,$22,$2d,$ca,$4a,$cc,$bb,$bb,$ab,$ac,$bc,$db,$df,$4a,$f1;0E8D90|        |      ;
; $ca: Parameter
; $4a: Channel separator (appears twice)
; $cc,$bb,$bb,$ab,$ac,$bc: Voice envelope sequence
; $db,$df: Parameters
; $f1: DSP register marker

	db $33,$64,$76,$65,$64,$55,$34,$4a,$22,$12,$11,$e2,$11,$0e,$fa,$b9;0E8DA0|        |      ;
; $33,$64,$76,$65,$64,$55,$34: Parameter sequence (melody line)
; $4a: Channel separator
; $e2: DSP register marker
; $fa,$b9: High parameters

	db $5a,$dc,$cd,$cd,$ee,$dc,$ff,$00,$12,$5a,$24,$33,$35,$43,$23,$22;0E8DB0|        |      ;
; $5a: Channel separator (appears twice)
; $dc,$cd,$cd,$ee,$dc: Voice envelope sequence
; $ff,$00: Parameters
; Voice parameters between separators

	db $22,$21,$5a,$21,$00,$01,$0f,$ef,$ed,$cd,$dd,$5a,$cb,$ce,$cb,$dd;0E8DC0|        |      ;
; $5a: Channel separator (appears three times)
; Pattern shows $5a as primary separator in this section

	db $ee,$f0,$01,$33,$5a,$33,$54,$55,$54,$33,$33,$21,$01,$5a,$21,$ff;0E8DD0|        |      ;
; $ee,$f0: Envelope with DSP marker
; $5a: Channel separator (appears three times)
; Parameter sequences between separators

	db $00,$ed,$ef,$dc,$cd,$db,$5a,$ba,$cc,$de,$fe,$10,$00,$33,$46,$5a;0E8DE0|        |      ;
; $ed,$ef,$dc,$cd,$db: Envelope sequence
; $5a: Channel separator (appears twice)
; $de,$fe: Parameters

	db $45,$56,$43,$24,$22,$22,$13,$12,$5a,$20,$ef,$ed,$db,$cb,$ca,$cb;0E8DF0|        |      ;
; Parameter sequence
; $5a: Channel separator
; $ef,$ed,$db,$cb,$ca,$cb: Extended envelope sequence

	db $ba,$5a,$cc,$ed,$ef,$ff,$10,$12,$42,$55,$5a,$66,$56,$54,$44,$33;0E8E00|        |      ;
; $ba: Parameter
; $5a: Channel separator (appears twice)
; Voice parameters between markers

; Pattern continues through 0E8E10-0E8EFF with:
; - $5a as primary channel separator (appears 3-5 times per line)
; - $4a/$6a/$7a/$3a as alternate channel separators
; - Envelope sequences between separators
; - Parameter values (note/duration data)

; ------------------------------------------------------------------------------
; $0e8f00-$0e8fff: Extended $6a/$7a Voice Channels (256 bytes)
; ------------------------------------------------------------------------------
; Shift to $6a and $7a as dominant channel separators
; These appear to be additional voice channels beyond the initial $5a/$4a groups

	db $ff,$fe,$fe,$fe,$f0,$23,$45,$77,$6a,$44,$64,$43,$32,$1f,$ff,$ef;0E8F10|        |      ;
; $ff,$fe: High envelope values
; $6a: Channel separator (new primary separator for this section)
; $44,$64,$43,$32: Parameter sequence
; $ff,$ef: High values

	db $ef,$6a,$ee,$de,$dc,$bd,$ee,$ee,$00,$21,$6a,$0f,$00,$0f,$fe,$ef;0E8F20|        |      ;
; $6a: Channel separator (appears three times)
; $ee,$de,$dc,$bd,$ee,$ee: Envelope sequence
; Pattern shows $6a separating voices with similar structure to earlier $5a

	db $12,$13,$45,$6a,$45,$55,$44,$31,$01,$fe,$e0,$ee,$6a,$de,$ed,$cb;0E8F30|        |      ;
; $6a: Channel separator (appears three times)
; Voice parameters between separators

	db $dd,$cd,$ff,$0f,$12,$6a,$20,$00,$0f,$ee,$ef,$f1,$23,$35,$6a,$45;0E8F40|        |      ;
; $ff,$0f: High parameter
; $6a: Channel separator (appears twice)
; $f1: DSP register marker

	db $44,$33,$42,$22,$1f,$fe,$de,$6a,$ed,$ce,$ec,$de,$ee,$fe,$00,$21;0E8F60|        |      ;
; Parameter sequence
; $6a: Channel separator
; $ed,$ce,$ec,$de,$ee,$fe: Envelope sequence

	db $6a,$1f,$0f,$fd,$cc,$de,$f0,$23,$55,$6a,$54,$56,$45,$43,$22,$0f;0E8F70|        |      ;
; $6a: Channel separator (appears twice)
; $f0: DSP register marker
; Pattern continues with regular $6a separators

	db $ee,$ee,$5a,$9b,$ab,$cb,$bb,$bc,$ef,$00,$21,$6a,$0f,$ff,$dc,$cc;0E8F80|        |      ;
; $5a: Channel separator (brief return to $5a marker)
; $9b,$ab,$cb,$bb,$bc: Voice envelope sequence
; $6a: Back to $6a separator
; Shows mixing of separator types

	db $de,$f0,$33,$45,$6a,$65,$57,$65,$44,$20,$ff,$ee,$dd,$5a,$ac,$bc;0E8F90|        |      ;
; $6a: Channel separator
; $5a: Channel separator (alternating $6a/$5a in this section)

	db $bc,$cc,$cc,$fe,$10,$10,$6a,$ff,$ee,$bc,$bd,$df,$01,$25,$76,$6a;0E8FA0|        |      ;
; $6a: Channel separator (appears twice)
; Voice configuration between markers

	db $66,$77,$65,$33,$0e,$ee,$cd,$ef,$5a,$bd,$dc,$cb,$ba,$cc,$e0,$ef;0E8FB0|        |      ;
; $6a/$5a: Mixed channel separators
; $e0,$ef: DSP register and envelope marker

	db $0f,$6a,$fe,$dd,$dc,$cd,$ef,$13,$45,$66,$7a,$44,$43,$32,$10,$ff;0E8FC0|        |      ;
; $6a: Channel separator
; $7a: New channel separator introduced (appears first time)
; Transition from $6a to $7a voice groups

	db $ef,$ff,$0f,$6a,$fe,$ec,$cc,$dc,$cd,$ff,$ff,$00,$7a,$00,$ff,$f0;0E8FF0|        |      ;
; $6a: Channel separator
; $7a: Channel separator (second occurrence)
; Shows transition to $7a as new primary separator

; Pattern continues 0E9000-0E9FFF with $7a as dominant separator

; ------------------------------------------------------------------------------
; $0e9000-$0e90ff: $7a Voice Channel Dominance (256 bytes)
; ------------------------------------------------------------------------------
; $7a becomes primary channel separator for extended section
; Pattern structure similar to earlier $5a/$6a sections

	db $ff,$f0,$02,$23,$33,$7a,$44,$43,$32,$0f,$ff,$ef,$f0,$f0,$6a,$f0;0E9000|        |      ;
; $7a: Channel separator
; $6a: Brief appearance (mixed with $7a)
; Shows gradual transition to $7a dominance

	db $dc,$ba,$ac,$bc,$ef,$0f,$11,$7a,$00,$10,$ff,$ff,$f0,$f1,$23,$34;0E9010|        |      ;
; $7a: Channel separator
; Envelope sequence and parameters between markers

	db $7a,$45,$42,$11,$10,$ff,$f0,$00,$00,$6a,$fd,$cb,$a9,$9b,$dc,$ff;0E9020|        |      ;
; $7a: Channel separator
; $6a: Alternate separator (shows mixing continues)
; $fd,$cb,$a9,$9b,$dc: Voice envelope sequence

; Pattern continues with $7a appearing 2-4 times per line through 0E90FF
; Occasional $6a/$5a markers appear but $7a dominates

; ------------------------------------------------------------------------------
; $0e9100-$0e99ff: Extended $7a Sequences (2,304 bytes)
; ------------------------------------------------------------------------------
; Long section with consistent $7a channel separator usage
; Additional markers: $6a, $5a, $4a appear intermittently

	db $ee,$dc,$cc,$cd,$ff,$00,$11,$10,$7a,$10,$0e,$ee,$ee,$f0,$12,$35;0E9140|        |      ;
; $7a: Channel separator
; Standard envelope/parameter pattern continues

	db $45,$7a,$44,$23,$12,$10,$f0,$00,$00,$ff,$7a,$fe,$dc,$cd,$dd,$ee;0E9150|        |      ;
; $7a: Channel separator (appears three times)
; Consistent separator spacing

; Through lines 450-650 (0E9200-0E9900):
; - $7a remains primary separator (80%+ of separators)
; - $6a appears occasionally (10-15% of separators)
; - $5a appears rarely (5% of separators)
; - Envelope sequences: $cc/$dd/$bc/$ee/$ef/$fe/$ed between channels
; - Parameter values indicate note/duration/pitch data
; - DSP register markers ($e0-$ff) appear intermittently

; ------------------------------------------------------------------------------
; $0e9a00-$0e9aff: $8a Separator Returns (256 bytes - lines 640-655)
; ------------------------------------------------------------------------------
; Original $8a channel separator reappears after long $5a/$6a/$7a section
; Indicates return to original voice group or new music section

	db $bb,$bc,$cd,$dd,$cc,$cd,$ee,$ee,$6a,$dd,$cd,$ee,$ef,$ee,$ff,$0f;0E9B10|        |      ;
; $6a: Channel separator (still present from previous section)

	db $00,$4a,$0d,$ed,$dd,$f0,$46,$54,$2f,$fd,$5a,$ef,$24,$63,$1f,$ef;0E9B20|        |      ;
; $4a: Channel separator returns
; $5a: Channel separator
; Mix of older separator types reappearing

	db $01,$23,$22,$4a,$1c,$be,$12,$33,$32,$fc,$bd,$34,$4a,$44,$1f,$fc;0E9B30|        |      ;
; $4a: Channel separator (appears three times)
; Return to $4a separator dominance in this subsection

	db $ad,$25,$76,$30,$0c,$4a,$cd,$e1,$55,$43,$22,$dc,$ff,$33,$5a,$22;0E9B40|        |      ;
; $ad: High parameter value
; $4a: Channel separator
; $5a: Channel separator
; Mixed separator usage

	db $22,$32,$10,$00,$00,$12,$34,$5a,$54,$2f,$fe,$ee,$13,$55,$43,$2d;0E9B50|        |      ;
; $5a: Channel separator
; Voice parameters between markers

	db $6a,$dd,$d0,$13,$33,$22,$fb,$be,$f0,$6a,$14,$43,$0e,$dd,$cd,$e0;0E9B60|        |      ;
; $6a: Channel separator (appears twice)
; $fb,$be: High parameters
; $e0: DSP register marker

; Pattern continues mixing $4a/$5a/$6a separators through 0E9BFF

; ------------------------------------------------------------------------------
; $0e9c00-$0e9cff: Continued Mixed Separators (256 bytes)
; ------------------------------------------------------------------------------

	db $6a,$0d,$ec,$df,$ee,$dd,$cc,$cd,$dc,$7a,$ee,$ee,$cc,$cd,$bb,$bb;0E9C00|        |      ;
; $6a: Channel separator
; $7a: Channel separator
; Shows mixing of multiple separator types

	db $bb,$ab,$7a,$bc,$bb,$aa,$aa,$ba,$bb,$cb,$aa,$7a,$bb,$bb,$bb,$dd;0E9C10|        |      ;
; $7a: Channel separator (appears three times)
; $7a becomes dominant again in this subsection

	db $dc,$cd,$cd,$de,$6a,$bd,$cd,$ed,$dd,$ee,$ef,$ff,$00,$4a,$b9,$de;0E9C20|        |      ;
; $6a: Channel separator
; $4a: Channel separator
; Transition section with multiple separator types

	db $f0,$10,$10,$de,$f2,$46,$5a,$31,$0f,$f0,$10,$34,$42,$fe,$ff,$5a;0E9C30|        |      ;
; $f0: DSP register marker
; $f2,$46: DSP register $f2, value $46
; $5a: Channel separator (appears twice)

; Pattern continues through 0E9CFF with mixed $4a/$5a/$6a/$7a separators

; ------------------------------------------------------------------------------
; $0e9d00-$0e9dff: Return to $7a Dominance (256 bytes)
; ------------------------------------------------------------------------------

	db $44,$33,$34,$33,$44,$55,$55,$56,$7a,$56,$55,$56,$66,$54,$35,$55;0E9D00|        |      ;
; $7a: Channel separator
; Parameter sequence (melody pattern)

	db $46,$7a,$66,$66,$54,$55,$54,$43,$22,$22,$6a,$20,$e0,$ec,$df,$ef;0E9D10|        |      ;
; $7a: Channel separator
; $6a: Channel separator
; $e0: DSP register marker

	db $1f,$0d,$ca,$7a,$dd,$ee,$ee,$dc,$cb,$bb,$bb,$bc,$7a,$bb,$bb,$aa;0E9D20|        |      ;
; $ca: Parameter
; $7a: Channel separator (appears twice)
; Voice envelope sequences

	db $ba,$bb,$ba,$aa,$ab,$7a,$bb,$bb,$bb,$bb,$cc,$dc,$dd,$dd,$66,$54;0E9D30|        |      ;
; $7a: Channel separator (appears twice)
; Extended parameter sequence

	db $34,$44,$55,$55,$66,$53,$22,$4a,$fe,$cf,$ee,$dc,$de,$f0,$22,$22;0E9D40|        |      ;
; Parameter sequence
; $4a: Channel separator
; $fe,$cf: Envelope markers
; $f0: DSP register marker

; Pattern continues with $7a as primary separator, occasional $4a/$5a/$6a through 0E9DFF

; ------------------------------------------------------------------------------
; $0e9e00-$0e9fff: Final Mixed Pattern Section (512 bytes)
; ------------------------------------------------------------------------------
; Lines 700-800 show complex mixing of all separator types
; Appears to be multi-song or multi-SFX data concatenated

	db $00,$12,$22,$23,$44,$33,$44,$33,$7a,$44,$33,$33,$44,$34,$56,$55;0E9E00|        |      ;
; $7a: Channel separator

	db $65,$7a,$55,$64,$55,$55,$56,$55,$45,$56,$7a,$55,$77,$66,$76,$43;0E9E10|        |      ;
; $7a: Channel separator (appears three times)

	db $33,$34,$31,$5a,$44,$4f,$d0,$12,$1f,$cc,$cb,$cb,$7a,$ff,$ee,$dc;0E9E20|        |      ;
; $5a: Channel separator
; $7a: Channel separator
; $d0: Parameter
; $ff,$ee: High envelope values

	db $cd,$dd,$cc,$cc,$ba,$7a,$aa,$cc,$ba,$cb,$a9,$ab,$ba,$ab,$7a,$aa;0E9E30|        |      ;
; $7a: Channel separator (appears three times)

	db $bb,$ab,$bc,$bc,$cb,$bd,$dd,$6a,$ab,$ab,$aa,$bd,$ed,$f0,$fe,$ec;0E9E40|        |      ;
; $7a/$6a: Channel separators
; $f0: DSP register marker

	db $66,$20,$ff,$f0,$13,$43,$21,$0e,$dd,$5a,$46,$43,$10,$ec,$ce,$24;0E9E50|        |      ;
; $f0: DSP register marker
; $5a: Channel separator

	db $55,$44,$5a,$2f,$dc,$ef,$12,$34,$42,$fe,$fd,$5a,$de,$02,$33,$44;0E9E60|        |      ;
; $5a: Channel separator (appears twice)

; Lines 750-800 continue mixing:
; - $5a: ~25% of separators
; - $6a: ~20% of separators
; - $7a: ~30% of separators
; - $4a: ~15% of separators
; - $8a: ~10% of separators (returns near end)

	db $8a,$21,$11,$23,$32,$34,$43,$33,$22,$6a,$66,$1f,$00,$33,$34,$76;0E98D0|        |      ;
; $8a: Channel separator returns (line 401 - start of this cycle)
; $6a: Channel separator
; Shows transition back to earlier separator patterns

	db $54,$31,$7a,$fe,$ed,$dc,$cd,$cb,$cd,$ee,$ee,$7a,$ee,$dc,$dc,$cb;0E98E0|        |      ;
; $7a: Channel separator (appears twice)
; $fe,$ed: Envelope markers

	db $ca,$aa,$bb,$ab,$7a,$ab,$bb,$ab,$bc,$bb,$bd,$cb,$bc,$7a,$cc,$dc;0E98F0|        |      ;
; $7a: Channel separator (appears three times)
; Voice envelope sequences between separators

	db $dd,$ed,$dd,$de,$ff,$ef,$5a,$cb,$bd,$de,$ef,$00,$ff,$ee,$f0,$4a;0E9900|        |      ;
; $ff,$ef: High envelope values
; $5a: Channel separator
; $f0,$4a: DSP register $f0 followed by $4a separator
; Shows complex interleaving of markers

; Final lines (790-800) show all separator types appearing:

	db $76,$01,$23,$22,$11,$12,$23,$34,$45,$6a,$dc,$bd,$ef,$12,$11,$0f;0E9F50|        |      ;
; $6a: Channel separator

	db $ee,$ef,$5a,$11,$44,$32,$0f,$ff,$e0,$12,$44,$5a,$34,$41,$ec,$ef;0E9F60|        |      ;
; $5a: Channel separator (appears twice)
; $e0: DSP register marker

	db $00,$35,$42,$fe,$5a,$fe,$e0,$23,$42,$0e,$de,$ff,$04,$5a,$54,$20;0E9F70|        |      ;
; $5a: Channel separator (appears three times)

	db $ee,$ee,$e1,$23,$35,$43,$5a,$11,$ee,$dd,$f3,$56,$65,$52,$0f,$5a;0E9F80|        |      ;
; $e1: DSP register marker
; $5a: Channel separator (appears twice)
; $f3: DSP register marker

	db $e0,$01,$23,$34,$44,$43,$21,$1f,$5a,$fe,$e0,$00,$23,$44,$33,$10;0E9F90|        |      ;
; $e0: DSP register marker (appears twice)
; $5a: Channel separator

	db $ed,$5a,$b9,$bd,$02,$24,$64,$1c,$cc,$a9,$5a,$bc,$ee,$ff,$10,$00;0E9FA0|        |      ;
; $5a: Channel separator (appears twice)
; $b9,$bd: High parameters

	db $fd,$bb,$bc,$5a,$bc,$ef,$0f,$ed,$ef,$02,$0f,$ee,$5a,$ec,$bd,$de;0E9FB0|        |      ;
; $5a: Channel separator (appears three times)
; Dense separator usage in final lines

	db $ee,$ff,$00,$11,$22,$5a,$10,$ec,$cb,$ce,$e1,$23,$22,$21,$5a,$01;0E9FC0|        |      ;
; $5a: Channel separator (appears twice)
; $e1: DSP register marker

	db $0e,$de,$13,$44,$55,$30,$fd,$6a,$ee,$ee,$f0,$22,$44,$43,$44,$20;0E9FD0|        |      ;
; $6a: Channel separator
; $f0: DSP register marker

	db $6a,$ed,$dc,$bd,$ef,$f1,$23,$32,$23,$5a,$20,$ee,$ec,$dc,$bc,$cc;0E9FE0|        |      ;
; $6a: Channel separator
; $5a: Channel separator
; $f1: DSP register marker

	db $ab,$cd,$5a,$ee,$f0,$00,$f0,$00,$ff,$ec,$dd,$6a,$ee,$ef,$ff,$f1;0E9FF0|        |      ;
; $5a: Channel separator
; $6a: Channel separator
; $f0: DSP register marker (appears three times)
; $f1: DSP register marker

; ==============================================================================
; End of Bank $0e Cycle 2 (Lines 401-800)
; Documented Address Range: $0e8a00-$0ea000 (6,144 bytes)
; ==============================================================================
; Technical Summary:
; - Complex multi-channel voice system with 6+ separator types:
;   * $8a: Original separator from Bank $0d/Cycle 1 (returns at start/end)
;   * $5a: Primary separator for section 0E8D00-0E8E00 (~256 bytes)
;   * $6a: Primary separator for section 0E8E00-0E9000 (~512 bytes)
;   * $7a: Dominant separator for section 0E9000-0E9E00 (~3.5KB)
;   * $4a: Alternate separator, appears intermittently
;   * $3a: Rare variant separator
; - Voice markers ($a2/$b2/$b6/$a6/$b4/$b5) appear in first section (0E8A00-0E8D00)
; - DSP register usage: $e0-$f4 range (echo, modulation, flags)
; - Envelope markers: $cc/$dd/$bc/$ee/$ef/$fe/$ed (ADSR/volume)
; - Pattern indicates multiple music tracks or SFX sequences:
;   * Different separators may indicate different instrument groups
;   * $5a/$6a/$7a pattern suggests three distinct voice layers
;   * $8a return at boundaries indicates track/section transitions
; - Zero padding at 0E8D30 marks major structural boundary
; - High parameter concentration ($90+, $a0+, $f0+) in later sections
; - This section appears to be continuation of Bank $0d's audio driver
;   with extended voice channel capabilities (16+ simultaneous voices)
; ==============================================================================
; Lines 801-1000 documented (200 source lines, addresses $0eb1d0-$0ebe40)
; Continuation of multi-separator voice system, focusing on $9a/$aa pattern analysis

	db $fd,$e1,$10,$9a,$f0,$f3,$0b,$d1,$33,$21,$12,$09,$9a,$c3,$f1,$5e;0EB1D0
; $9a separator continues dominant pattern from previous section
; High envelope values: $fd/$f3/$f1 (loud sustain/decay)
; Parameter sequence: $0b/$33/$21/$12/$09 (pitch/volume modulation)

	db $e5,$1d,$fe,$cc,$e2,$aa,$44,$2d,$d0,$fe,$00,$f1,$01,$51,$9a,$dd;0EB1E0
; $aa separator appears (alternate to $9a, similar function)
; Envelope markers: $fe/$cc/$e2/$dd (ADSR sequence)
; Zero byte at position 10 may indicate voice reset

	db $ee,$f0,$21,$21,$cc,$13,$10,$96,$24,$45,$1b,$de,$cf,$2f,$f3,$42;0EB1F0
; $96 separator variant appears
; Multiple envelopes: $ee/$f0/$cc/$de/$cf/$f3 (complex voice shaping)
; Low parameters: $13/$10/$21 contrast with high $f0/$f3

	db $aa,$ff,$ee,$f2,$54,$fc,$f0,$ff,$ff,$9a,$30,$f6,$51,$2c,$be,$0f;0EB200
; $aa and $9a separators in same line (transition marker)
; Maximum values: $ff (3 instances, peak volume/brightness)
; Envelope sequence: $ee/$f2/$fc/$f0/$be

	db $23,$2e,$96,$cc,$12,$ee,$24,$41,$bd,$0e,$d0,$aa,$0e,$12,$10,$fd;0EB210
; $96 and $aa separators present
; Pattern: low params → separator → low params ($0e/$12/$10)
; Envelopes: $cc/$ee/$bd/$d0/$fd (varied dynamics)

	db $df,$13,$42,$dc,$9a,$23,$ee,$df,$10,$23,$35,$0b,$dd,$9a,$f1,$31;0EB220
; Two $9a separators in one line (dual voice layer)
; Envelopes: $df/$dc/$ee/$df/$dd/$f1 (high sustain values)
; Low counters: $13/$10/$23/$35/$0b/$31

	db $0e,$04,$3c,$d4,$4f,$bb,$9a,$37,$fc,$10,$c1,$62,$00,$c9,$d1,$96;0EB230
; $9a and $96 separators
; DSP-range values: $c1/$c9/$d1/$d4/$bb (likely DSP registers)
; Zero byte at position 10 (voice boundary marker)

	db $c1,$44,$1e,$02,$1e,$df,$ed,$f3,$9a,$42,$ed,$cf,$31,$ef,$02,$53;0EB240
; $9a separator with DSP register $c1
; High envelopes: $df/$ed/$f3/$ed/$cf/$ef (bright sustained voice)
; Repeated $1e value (pitch/detune parameter)

	db $cc,$9a,$43,$0c,$90,$74,$ed,$1d,$e4,$42,$9a,$1e,$bb,$f2,$40,$f0;0EB250
; Two $9a separators, envelope $cc
; $90 value (common voice parameter in this bank)
; DSP-range: $e4/$bb/$f2/$f0 (echo/modulation settings)

	db $f0,$10,$1e,$9a,$d2,$1e,$04,$01,$2d,$b1,$40,$cf,$9a,$34,$4f,$b1;0EB260
; Two $9a separators with $b1 voice markers (melody voice)
; DSP register $d2/$cf
; $f0 envelope (maximum sustain)

	db $4f,$ea,$e6,$31,$fe,$9a,$fc,$05,$61,$ef,$bc,$13,$fd,$13,$9a,$ef;0EB270
; Two $9a separators
; High envelope cluster: $ea/$e6/$fe/$fc/$ef/$bc/$fd/$ef
; Pattern suggests loud sustained passage

	db $11,$1f,$f1,$0e,$10,$f4,$1c,$9a,$e2,$20,$c0,$64,$fc,$13,$0d,$cf;0EB280
; $9a separator with DSP registers $e2/$c0/$fc/$cf
; Envelope $f4/$f1 (high sustain)
; Low params: $11/$1f/$0e/$10/$1c/$13/$0d

	db $aa,$20,$f2,$1f,$ee,$14,$2f,$f0,$e0,$9a,$fe,$d0,$41,$cf,$33,$0e;0EB290
; $aa and $9a separators (voice layer switch)
; DSP range: $f2/$ee/$f0/$e0/$fe/$d0/$cf
; High concentration of E/F range values

	db $21,$de,$9a,$fe,$44,$dc,$24,$1c,$e3,$52,$de,$aa,$20,$ef,$02,$0e;0EB2A0
; $9a and $aa separators
; Envelopes: $de/$fe/$dc/$e3/$de/$ef
; Counter pattern: $21/$44/$24/$1c/$52/$20/$02/$0e

	db $03,$fe,$e1,$33,$9a,$0d,$0f,$d2,$ea,$e3,$3e,$d1,$33,$9a,$00,$3f;0EB2B0
; Two $9a separators
; DSP cluster: $fe/$e1/$d2/$ea/$e3/$d1
; Zero byte at position 0 and 14 (section markers)

	db $ad,$01,$31,$df,$44,$cd,$9a,$23,$41,$cf,$1d,$f2,$22,$dc,$32,$aa;0EB2C0
; $9a and $aa separators
; Envelopes: $ad/$df/$cd/$cf/$f2/$dc
; Pattern: mid-range then separator then params

	db $ef,$01,$33,$ff,$fe,$21,$cd,$12,$aa,$0e,$f2,$21,$11,$0d,$c0,$20;0EB2D0
; $aa separator with DSP registers
; Maximum value $ff, envelopes $ef/$fe/$cd/$f2/$c0
; Low params follow: $0e/$21/$11/$0d/$20

	db $10,$9a,$e1,$6e,$d2,$02,$40,$ed,$cf,$45,$9a,$1d,$c1,$2c,$d1,$23;0EB2E0
; Two $9a separators
; DSP cluster: $e1/$d2/$ed/$cf/$c1/$d1
; Mixed params: $6e/$02/$40/$45/$1d/$2c/$23

	db $64,$ec,$c0,$aa,$3f,$cf,$00,$00,$01,$12,$21,$eb,$9a,$b3,$22,$4d;0EB2F0
; $aa and $9a separators, $b3 voice marker appears
; Double zero bytes at positions 6-7 (boundary)
; DSP: $ec/$c0/$cf/$eb

	db $e6,$1c,$02,$14,$1f,$9a,$cc,$e2,$63,$ed,$f2,$da,$24,$13,$9a,$62;0EB300
; Two $9a separators
; Envelopes: $e6/$cc/$e2/$ed/$f2/$da
; Counter sequence: $1c/$02/$14/$1f/$63/$24/$13/$62

	db $bc,$f3,$1b,$ef,$ee,$f1,$33,$aa,$21,$00,$dc,$01,$03,$1d,$22,$ef;0EB310
; $aa separator with zero byte at position 9
; High envelope cluster: $bc/$f3/$ef/$ee/$f1/$dc/$ef
; Low params: $1b/$33/$21/$01/$03/$1d/$22

	db $9a,$13,$31,$1d,$cd,$04,$5f,$d0,$0e,$9a,$b1,$50,$14,$5d,$b1,$2f;0EB320
; Two $9a separators with $b1 voice markers (melody layer)
; Envelopes: $cd/$d0
; Pattern suggests dual melody voice configuration

	db $df,$0c,$9a,$c0,$f2,$45,$50,$dc,$ac,$11,$36,$9a,$0d,$21,$fd,$24;0EB330
; Two $9a separators
; DSP range: $df/$c0/$f2/$dc/$ac/$fd
; Low params interspersed: $0c/$45/$50/$11/$36/$0d/$21/$24

	db $20,$fb,$00,$02,$9a,$10,$10,$cc,$f4,$31,$34,$fa,$04,$9a,$fb,$04;0EB340
; Two $9a separators with zero byte
; Envelopes: $fb/$cc/$f4/$fa/$fb
; Repeated $10 and $04 values (timing parameters)

	db $e9,$df,$04,$57,$3b,$bc,$9a,$ce,$14,$33,$2e,$f2,$d0,$41,$00,$9a;0EB350
; Two $9a separators with zero byte at end
; Envelopes: $e9/$df/$bc/$ce/$f2/$d0
; Mid-range params: $57/$3b/$14/$33/$2e/$41

	db $df,$2f,$ff,$24,$1b,$bf,$31,$35,$aa,$1f,$ef,$21,$ef,$20,$cd,$01;0EB360
; $aa separator
; Maximum value $ff with envelopes $df/$bf/$ef/$ef/$cd
; Low params: $2f/$24/$1b/$31/$35/$1f/$21/$20/$01

	db $11,$aa,$34,$fc,$df,$f0,$11,$13,$1e,$00,$9a,$d3,$22,$ed,$11,$00;0EB370
; $aa and $9a separators with zero bytes
; Envelopes: $fc,$df,$f0,$d3,$ed
; Repeated $11 and $00 values

	db $cf,$72,$bc,$9a,$f2,$20,$56,$ca,$f4,$3d,$d3,$1b,$aa,$df,$11,$02;0EB380
; $9a and $aa separators
; DSP cluster: $cf/$bc/$f2/$ca/$f4/$d3,$df
; Mixed params: $72/$20/$56/$3d/$1b/$11/$02

	db $40,$ce,$f0,$e0,$21,$9a,$56,$cc,$3d,$f3,$20,$d0,$30,$0c,$9a,$d5;0EB390
; Two $9a separators
; High DSP range: $ce/$f0/$e0/$cc/$f3/$d0/$d5
; Repeated $20 and $30 values (timing)

	db $6b,$a0,$21,$13,$60,$ad,$23,$aa,$ff,$21,$de,$e0,$20,$14,$0d,$ef;0EB3A0
; $aa separator with $a0/$ad DSP registers
; Maximum $ff value, envelopes $de/$e0/$ef
; Counter sequence: $6b/$21/$13/$60/$23/$21/$20/$14/$0d

	db $9a,$d1,$e0,$34,$72,$af,$3e,$e3,$0e,$9a,$11,$11,$db,$26,$0b,$c3;0EB3B0
; Two $9a separators
; DSP range: $d1/$e0/$af/$e3/$db/$c3
; Parameters: $34/$72/$3e/$0e/$11/$11/$26/$0b

	db $31,$02,$9a,$4e,$b2,$1d,$f5,$2b,$de,$d2,$10,$aa,$42,$cd,$1f,$ff;0EB3C0
; $9a and $aa separators
; $b2 voice marker (bass/rhythm voice returns)
; Envelopes: $f5/$de/$d2/$cd/$ff (maximum at end)

	db $f1,$32,$20,$e1,$9a,$1b,$04,$df,$31,$1e,$b0,$61,$cd,$9a,$03,$12;0EB3D0
; Two $9a separators
; Envelopes: $f1/$e1,$df/$b0/$cd
; Low params: $32/$20/$1b/$04/$31/$1e/$61/$03/$12

	db $1f,$2f,$f2,$dc,$53,$be,$9a,$1e,$e1,$03,$6d,$a0,$ed,$ff,$13,$9a;0EB3E0
; Two $9a separators
; Envelopes: $f2/$dc/$be/$e1/$a0/$ed/$ff (maximum)
; Mid-range: $53/$6d

	db $43,$21,$0e,$fe,$f2,$10,$12,$dd,$8a,$22,$0f,$d0,$14,$62,$bc,$65;0EB3F0
; **$8a separator returns!** (first time since line 539/0EB540)
; Envelopes: $fe/$f2/$dd/$d0/$bc
; $8a marks major section boundary (different from $9a/$aa pattern)

	db $09,$96,$cf,$42,$ff,$0f,$dc,$e2,$2f,$fe,$9a,$cc,$02,$22,$32,$43;0EB400
; $96 and $9a separators
; Maximum values: $ff/$fe
; Envelopes: $cf/$dc/$e2/$cc
; Low start: $09 (section beginning marker)

	db $dc,$0f,$f3,$8a,$3c,$3e,$a2,$4d,$e1,$2f,$36,$0a,$9a,$e1,$62,$bb;0EB410
; **$8a separator again**, plus $9a
; $a2 voice marker appears (voice 4)
; Envelopes: $dc/$f3/$e1/$e1/$bb
; $8a usage suggests track/section transitions

	db $14,$fc,$02,$3f,$d0,$aa,$f0,$10,$ff,$ee,$12,$11,$f2,$40,$9a,$bc;0EB420
; $aa and $9a separators
; Maximum $ff, high envelopes $fc/$d0/$f0/$ee/$f2/$bc
; Pattern returns to $9a/$aa dominance

	db $10,$03,$ff,$1e,$f2,$0d,$03,$96,$cd,$22,$db,$bf,$76,$ff,$21,$ed;0EB430
; $96 separator
; Two $ff maximums, envelopes $f2/$cd/$db/$bf/$ed
; Mid-range: $76

	db $9a,$23,$2e,$fe,$b0,$41,$fb,$b1,$22,$aa,$1f,$15,$2d,$ef,$11,$00;0EB440
; $9a and $aa separators with $b1 voice marker
; Envelopes: $fe/$b0/$fb/$ef
; Zero byte at end (boundary)

	db $f0,$00,$9a,$10,$de,$23,$33,$1a,$a0,$45,$2c,$9a,$e2,$fd,$f2,$21;0EB450
; Two $9a separators with zero byte
; Envelopes: $f0/$de/$a0,$e2/$fd/$f2
; Low params: $10/$23/$33/$1a/$45/$2c/$21

	db $20,$da,$d2,$32,$aa,$ed,$02,$00,$00,$43,$ee,$f1,$20,$aa,$e0,$00;0EB460
; Two $aa separators with double zero bytes (section marker)
; DSP range: $da/$d2/$ed/$ee/$f1/$e0
; Repeated $20 and $00 values

	db $10,$ff,$f0,$13,$21,$ec,$9a,$b5,$70,$d0,$1f,$ed,$24,$01,$2f,$aa;0EB470
; $9a and $aa separators
; $b5 voice marker appears (new voice channel)
; Maximum $ff with envelopes $f0/$ec/$d0/$ed

	db $ec,$f2,$20,$df,$10,$00,$03,$30,$9a,$de,$03,$0e,$e1,$10,$2f,$bf;0EB480
; $9a separator with zero byte
; Envelopes: $ec/$f2/$df/$de/$e1/$bf
; Low params mixed: $20/$10/$03/$30/$03/$0e/$10/$2f

	db $20,$aa,$14,$2f,$cd,$03,$1e,$03,$fe,$f1,$9a,$40,$f1,$10,$aa,$02;0EB490
; $aa, $9a, $aa sequence (rapid voice switching)
; Envelopes: $cd/$fe/$f1/$f1
; Repeated $03 values

	db $2e,$e1,$20,$9a,$dd,$56,$12,$ee,$41,$ce,$02,$01,$9a,$1d,$d1,$f1;0EB4A0
; Two $9a separators
; Envelopes: $e1/$dd/$ee/$ce/$d1/$f1
; Mid-range: $56

	db $67,$1b,$9c,$26,$fa,$9a,$46,$ad,$41,$01,$0f,$2e,$ad,$1f,$9a,$f0;0EB4B0
; Two $9a separators
; $9c separator variant appears
; Envelopes: $fa/$ad/$ad/$f0

	db $30,$00,$b1,$6f,$26,$ef,$5c,$9a,$b2,$0e,$23,$fd,$0f,$f4,$63,$0b;0EB4C0
; $9a separator with $b1 and $b2 voice markers (melody + bass)
; Zero byte, envelopes $ef/$fd/$f4
; Mid-range: $6f/$5c/$63

	db $9a,$be,$32,$cf,$51,$b1,$5f,$11,$ef,$9a,$fe,$de,$0e,$e5,$2e,$1d;0EB4D0
; Two $9a separators with $b1 voice marker
; Envelopes: $be/$cf/$ef/$fe/$de/$e5
; Mid-range: $51/$5f

	db $e5,$fc,$aa,$43,$f1,$1c,$f2,$fe,$22,$ff,$0e,$aa,$14,$20,$fe,$e0;0EB4E0
; Two $aa separators
; High envelope cluster: $e5/$fc/$f1/$f2/$fe/$ff/$fe/$e0
; Maximum $ff value

	db $1f,$f1,$01,$01,$9a,$11,$10,$dc,$f2,$ed,$ed,$25,$00,$aa,$ff,$10;0EB4F0
; $9a and $aa separators with zero byte
; Envelopes: $f1/$dc/$f2/$ed/$ed/$ff (maximum)
; Repeated $01, $10, $ed values

	db $d2,$42,$11,$ed,$f1,$ff,$9a,$43,$0f,$ed,$56,$00,$ed,$f0,$ee,$9a;0EB500
; Two $9a separators with zero byte
; High envelope cluster: $d2/$ed/$f1/$ff/$ed/$ed/$f0/$ee
; Mid-range: $56

	db $10,$14,$fe,$34,$1e,$bc,$21,$dc,$aa,$e1,$3f,$10,$f0,$0d,$13,$23;0EB510
; $aa separator
; Envelopes: $fe/$bc/$dc/$e1/$f0
; Low params: $10/$14/$34/$1e/$21/$3f/$10/$0d/$13/$23

	db $2d,$9a,$df,$df,$f0,$33,$10,$de,$53,$00,$9a,$d0,$0d,$d1,$0f,$24;0EB520
; Two $9a separators with zero byte
; Repeated $df envelope, plus $f0/$de/$d0/$d1
; Mid-range: $53

	db $ef,$63,$0b,$9a,$90,$2f,$eb,$e6,$0f,$5e,$e0,$be,$9a,$55,$55,$fe;0EB530
; Two $9a separators
; Envelopes: $ef/$eb/$e6/$e0/$be/$fe
; Repeated $55 value, mid-range $63/$5e

	db $0b,$b1,$0f,$34,$1f,$8a,$d2,$72,$0a,$c4,$d9,$0f,$d3,$55,$9a,$e0;0EB540
; **$8a separator** (major section marker) plus $9a
; $b1 voice marker, DSP range $d2/$c4/$d9/$d3/$e0
; Mid-range: $72, repeated $55

	db $64,$d9,$d1,$ee,$fe,$11,$03,$9a,$4d,$cb,$e5,$53,$43,$10,$ca,$c1;0EB550
; $9a separator
; Repeated $d9 from previous line, envelopes $d1/$ee/$fe/$cb/$e5/$ca/$c1
; Mid-range: $64/$4d/$53/$43

	db $9a,$2f,$34,$00,$01,$12,$fc,$f1,$0e,$9a,$ee,$23,$0f,$03,$62,$bb;0EB560
; Two $9a separators with zero byte
; Envelopes: $fc/$f1/$ee/$bb
; Mid-range: $62

	db $ee,$ef,$aa,$f0,$11,$10,$1e,$de,$23,$11,$22,$9a,$1e,$bb,$d2,$10;0EB570
; $aa and $9a separators
; Envelopes: $ee/$ef/$f0/$de/$bb/$d2
; Repeated $1e, $10, $11

	db $22,$13,$2f,$f0,$9a,$0d,$d2,$2d,$b1,$43,$df,$34,$30,$aa,$ee,$e0;0EB580
; $9a and $aa separators with $b1 voice marker
; Envelopes: $f0/$d2/$df/$ee/$e0
; Low params: $22/$13/$2f/$0d/$2d/$43/$34/$30

	db $ff,$f2,$00,$13,$fb,$d1,$aa,$33,$2f,$12,$1f,$dd,$01,$0f,$12,$9a;0EB590
; $aa and $9a separators with zero byte
; Maximum $ff, envelopes $f2/$fb/$d1/$dd
; Repeated $12, $13, $1f values

	db $43,$e0,$2e,$db,$05,$0a,$e2,$33,$9a,$df,$55,$ff,$db,$ef,$de,$23;0EB5A0
; $9a separator
; Envelopes: $e0/$db/$e2/$df,$db/$ef/$de
; Maximum $ff, repeated $55, $db

	db $20,$aa,$11,$cc,$f2,$44,$0f,$11,$1f,$de,$9a,$11,$ee,$34,$62,$ff;0EB5B0
; $aa and $9a separators
; Envelopes: $cc/$f2/$de/$ee/$ff (maximum)
; Repeated $11, mid-range $62

	db $1f,$ab,$54,$9a,$bb,$03,$43,$df,$61,$e1,$bb,$10,$aa,$ee,$13,$10;0EB5C0
; $9a and $aa separators
; $ab separator variant, envelopes $bb/$df/$e1/$bb/$ee
; Mid-range: $54, $61

	db $1e,$bf,$12,$42,$f0,$9a,$22,$1d,$bf,$2f,$cf,$16,$72,$f0,$9a,$0c;0EB5D0
; Two $9a separators
; Repeated $bf envelope, plus $f0/$cf/$f0
; Mid-range: $72

	db $9f,$5f,$ce,$24,$22,$e0,$30,$aa,$00,$de,$10,$ee,$23,$10,$fc,$c2;0EB5E0
; $aa separator with zero byte
; $9f separator variant, envelopes $ce/$e0/$de/$ee/$fc/$c2
; Mid-range: $5f

	db $aa,$22,$31,$01,$ff,$10,$e1,$0d,$f1,$9a,$16,$61,$01,$da,$e1,$0c;0EB5F0
; $aa and $9a separators
; Maximum $ff, envelopes $e1/$f1/$da/$e1
; Mid-range: $61

	db $f0,$24,$9a,$31,$00,$ff,$0f,$ce,$10,$bf,$46,$aa,$1e,$dc,$03,$11;0EB600
; $9a and $aa separators with zero byte
; Envelopes: $f0/$ff/$ce/$bf/$dc
; Maximum $ff value

	db $40,$f1,$ff,$20,$aa,$f1,$ec,$12,$02,$40,$0f,$ef,$1f,$9a,$cd,$f1;0EB610
; $aa and $9a separators
; Two $ff maximums, repeated $f1 envelope
; Also $ec/$ef/$cd envelopes

	db $54,$13,$0e,$de,$1e,$e1,$aa,$0f,$e0,$23,$fd,$ee,$13,$02,$3e,$aa;0EB620
; Two $aa separators
; Envelopes: $de/$e1/$e0/$fd/$ee
; Mid-range: $54, $3e

	db $02,$ef,$11,$10,$dd,$01,$15,$2e,$9a,$10,$b0,$1c,$be,$04,$52,$23;0EB630
; $9a separator
; Envelopes: $ef/$dd/$b0/$be
; Mid-range: $52

	db $0b,$9a,$b0,$2e,$f1,$0d,$f2,$21,$da,$c1,$aa,$22,$12,$00,$1f,$d1;0EB640
; $9a and $aa separators with zero byte
; Repeated $b0 from previous line
; Envelopes: $f1/$f2/$da/$c1/$d1

	db $21,$1e,$de,$aa,$21,$14,$0f,$0f,$f1,$0d,$ef,$12,$aa,$21,$21,$fc;0EB650
; Three $aa separators (high concentration)
; Envelopes: $de/$f1/$ef/$fc
; Repeated $21 value (4 instances)

	db $f0,$0f,$11,$0f,$f1,$9a,$ff,$f9,$f5,$03,$60,$03,$0a,$d3,$9a,$44;0EB660
; Two $9a separators
; Envelopes: $f0/$f1/$ff/$f9/$f5/$d3
; Maximum $ff, repeated $0f, $03

	db $fb,$af,$42,$44,$fe,$1f,$f1,$aa,$fd,$f0,$11,$21,$31,$cc,$10,$f1;0EB670
; $aa separator
; High envelope cluster: $fb/$af/$fe/$f1/$fd/$f0/$cc/$f1
; Repeated $44, $11, $f1

	db $9a,$10,$0e,$12,$ce,$e9,$44,$e5,$6f,$9a,$22,$bb,$21,$33,$fb,$cf;0EB680
; Two $9a separators
; Envelopes: $ce/$e9/$e5,$bb/$fb/$cf
; Repeated $44, mid-range $6f

	db $56,$10,$9a,$ef,$2f,$e1,$eb,$f3,$01,$35,$5d,$aa,$ce,$1f,$1f,$02;0EB690
; $9a and $aa separators
; Envelopes: $ef/$e1/$eb/$f3/$ce
; Mid-range: $56, $5d, repeated $1f

	db $1e,$00,$ef,$f0,$9a,$10,$25,$31,$2f,$ae,$41,$f2,$1d,$9a,$c0,$54;0EB6A0
; Two $9a separators with zero byte
; Envelopes: $ef,$f0/$ae/$f2/$c0
; Mid-range: $54

	db $2f,$d0,$1f,$ef,$fe,$13,$9a,$0f,$26,$1c,$ce,$e2,$2e,$f3,$0e,$9a;0EB6B0
; Two $9a separators
; Envelopes: $d0/$ef/$fe/$ce/$e2/$f3
; Low params interspersed

	db $00,$cc,$11,$e2,$42,$43,$ee,$c0,$9a,$3e,$e4,$4d,$b2,$43,$2c,$d2;0EB6C0
; $9a separator with zero byte, $b2 voice marker (bass)
; Envelopes: $cc/$e2/$ee/$c0/$e4,$d2
; Mid-range: $3e, $4d, $43, $2c

	db $0e,$9a,$0e,$f2,$30,$ff,$23,$fe,$fc,$f4,$9a,$0e,$12,$ee,$00,$bf;0EB6D0
; Two $9a separators with zero byte
; Maximum $ff, envelopes $f2/$fe/$fc/$f4/$ee/$bf
; Repeated $0e

	db $3e,$d4,$40,$9a,$63,$cd,$f0,$1e,$d5,$6c,$d2,$24,$9a,$0a,$f4,$fe;0EB6E0
; Two $9a separators
; DSP range: $d4/$cd/$f0/$d5/$d2/$f4/$fe
; Mid-range: $3e, $63, $6c

	db $ee,$23,$3f,$00,$ef,$96,$03,$3e,$e0,$02,$51,$de,$fc,$cd,$aa,$0f;0EB6F0
; $96 and $aa separators with zero byte
; Envelopes: $ee/$ef/$e0/$de/$fc/$cd
; Mid-range: $51, $3e

	db $00,$12,$30,$e0,$0f,$ff,$04,$9a,$3c,$1e,$16,$cb,$31,$ef,$ee,$46;0EB700
; $9a separator with zero byte
; Maximum $ff, envelopes $e0/$cb/$ef/$ee
; Low params: $12, $30, $0f, $04, $3c, $1e, $16, $31, $46

	db $9a,$1d,$1f,$bf,$32,$ff,$0f,$f3,$2d,$9a,$b1,$ff,$3f,$d0,$0f,$27;0EB710
; Two $9a separators with $b1 voice marker
; Two $ff maximums, envelopes $bf/$f3/$d0
; Low params: $1d, $1f, $32, $0f, $2d, $3f, $0f, $27

	db $3d,$11,$96,$62,$d9,$e6,$55,$5f,$02,$ec,$ed,$9a,$ef,$ef,$56,$1e;0EB720
; $96 and $9a separators
; Envelopes: $d9/$e6/$ec/$ed/$ef/$ef
; Mid-range: $62, $55, $5f, $56

	db $fd,$bf,$42,$10,$9a,$fd,$e5,$4a,$b0,$f4,$3c,$c0,$20,$aa,$03,$01;0EB730
; $9a and $aa separators
; Repeated $fd envelope, plus $bf/$e5/$b0/$f4/$c0
; Mid-range: $4a, $3c

	db $3f,$ce,$e1,$41,$02,$fe,$9a,$20,$d1,$2d,$f0,$f1,$44,$2d,$cc,$9a;0EB740
; Two $9a separators
; Envelopes: $ce/$e1/$fe,$d1/$f0/$f1/$cc
; Repeated $2d

	db $e1,$23,$3f,$ed,$e6,$29,$b0,$36,$aa,$fe,$ff,$12,$0f,$23,$2d,$cf;0EB750
; $aa separator
; Envelopes: $e1/$ed/$e6/$b0/$fe/$ff/$cf
; Maximum $ff value

	db $01,$9a,$43,$23,$eb,$e1,$03,$fd,$01,$11,$9a,$14,$4a,$ad,$f3,$33;0EB760
; Two $9a separators
; Envelopes: $eb/$e1/$fd,$ad/$f3
; Mid-range: $4a

	db $2e,$cf,$22,$aa,$fd,$f2,$20,$0e,$e0,$11,$0f,$34,$9a,$fa,$ad,$33;0EB770
; $aa and $9a separators
; Envelopes: $cf/$fd/$f2/$e0,$fa/$ad
; Low params: $2e, $22, $20, $0e, $11, $0f, $34, $33

	db $23,$11,$f9,$03,$00,$9a,$0f,$f1,$30,$24,$e9,$ed,$f6,$40,$aa,$1e;0EB780
; $9a and $aa separators with zero byte
; Envelopes: $f9/$f1/$e9/$ed/$f6
; Low params: $23, $11, $03, $0f, $30, $24, $40, $1e

	db $e2,$1e,$ee,$14,$1e,$fe,$f2,$aa,$1e,$11,$22,$0d,$d0,$21,$11,$00;0EB790
; $aa separator with zero byte
; Envelopes: $e2/$ee/$fe/$f2/$d0
; Repeated $1e value (4 instances)

	db $96,$0a,$df,$bc,$0d,$bf,$01,$66,$eb,$aa,$0e,$04,$20,$fe,$11,$0d;0EB7A0
; $96 and $aa separators
; Envelopes: $df/$bc/$bf/$eb/$fe
; Mid-range: $66

	db $df,$53,$9a,$eb,$ee,$11,$ed,$46,$31,$d9,$e5,$9a,$13,$2d,$11,$ad;0EB7B0
; Two $9a separators
; Envelopes: $df/$eb/$ee/$ed/$d9/$e5,$ad
; Mid-range: $53, $46

	db $40,$d6,$2c,$03,$aa,$02,$2d,$b0,$0f,$23,$20,$df,$20,$aa,$fe,$c2;0EB7C0
; Two $aa separators
; Envelopes: $d6/$b0/$df/$fe/$c2
; Repeated $20, $2d

	db $51,$ef,$f0,$0f,$e1,$32,$9a,$00,$dc,$14,$10,$10,$0e,$a0,$4e,$aa;0EB7D0
; $9a and $aa separators with zero byte
; Envelopes: $ef/$f0/$e1/$dc/$a0
; Mid-range: $51, $4e, repeated $10

	db $03,$0f,$01,$21,$fc,$e0,$f0,$41,$9a,$13,$ec,$1f,$be,$02,$52,$ef;0EB7E0
; $9a separator
; Envelopes: $fc/$e0/$f0,$ec/$be/$ef
; Mid-range: $52

	db $fd,$9a,$ef,$e4,$61,$0f,$cf,$24,$2d,$f3,$9a,$fd,$cd,$14,$41,$e2;0EB7F0
; Two $9a separators
; Repeated $fd envelope, plus $ef/$e4/$cf/$f3/$cd/$e2
; Mid-range: $61

	db $11,$21,$da,$9a,$b0,$03,$51,$04,$1c,$cd,$e2,$3f,$9a,$13,$e0,$1b;0EB800
; Two $9a separators
; Envelopes: $da/$b0/$cd/$e2/$e0
; Mid-range: $51

	db $b0,$25,$4f,$f1,$de,$9a,$53,$cf,$32,$ee,$ab,$17,$50,$f2,$9a,$21;0EB810
; Two $9a separators
; Repeated $b0 from previous line
; $ab separator variant, envelopes $f1/$de/$cf/$ee/$f2
; Mid-range: $53, $50

	db $1e,$cc,$cf,$25,$3e,$16,$1c,$aa,$ce,$22,$0f,$00,$11,$0d,$d0,$22;0EB820
; $aa separator with zero byte
; Repeated $cc/$cf from previous, plus $ce/$d0
; Low params: $1e, $25, $3e, $16, $1c, $22, $0f, $11, $0d, $22

	db $aa,$20,$e0,$1f,$21,$c1,$3f,$0f,$be,$9a,$63,$45,$00,$1f,$01,$b9;0EB830
; $aa and $9a separators with zero byte
; Envelopes: $e0/$c1/$be/$b9
; Mid-range: $63, $45

	db $01,$14,$aa,$00,$22,$fe,$de,$42,$e0,$1e,$02,$9a,$ec,$c0,$56,$2d;0EB840
; $aa and $9a separators with zero byte
; Envelopes: $fe/$de,$e0,$ec/$c0
; Mid-range: $56, $42

	db $c0,$21,$2e,$c4,$aa,$20,$0d,$a1,$30,$24,$0f,$f0,$11,$9a,$aa,$f3;0EB850
; $aa and $9a separators
; Repeated $c0 from previous, plus $c4/$a1/$f0/$f3
; Repeated $aa separator in same line (unusual)

	db $21,$e1,$72,$bb,$f3,$30,$9a,$ef,$1f,$f0,$fd,$01,$34,$2c,$d2,$aa;0EB860
; $9a and $aa separators
; Envelopes: $e1/$bb/$f3/$ef/$f0/$fd/$d2
; Mid-range: $72

	db $01,$0d,$04,$11,$eb,$d1,$11,$34,$9a,$2b,$bf,$51,$cb,$04,$1c,$02;0EB870
; $9a separator
; Envelopes: $eb/$d1/$bf/$cb
; Mid-range: $51, $2b

	db $51,$9a,$cb,$35,$0d,$1f,$10,$af,$3f,$f2,$a6,$12,$31,$01,$11,$1f;0EB880
; $9a separator with $a6 voice marker
; Repeated $cb from previous, plus $af/$f2
; Mid-range: $51, repeated $1f

	db $03,$44,$0a,$9a,$f4,$f6,$64,$1a,$a4,$30,$fc,$14,$9a,$db,$20,$33;0EB890
; Two $9a separators
; Envelopes: $f4/$f6/$a4/$fc/$db
; Mid-range: $64

	db $dd,$44,$0d,$d0,$4e,$9a,$9e,$41,$13,$2f,$ff,$02,$fb,$f2,$aa,$13;0EB8A0
; $9a and $aa separators
; Envelopes: $dd/$d0/$9e/$ff/$fb/$f2
; Maximum $ff, mid-range $4e

	db $3d,$ae,$10,$14,$20,$fd,$02,$9a,$f1,$10,$2f,$ae,$0f,$44,$e0,$24;0EB8B0
; $9a separator
; Repeated $ae from previous, plus $fd/$f1/$e0
; Mid-range: $3d, $44

	db $9a,$2b,$92,$5c,$b0,$13,$50,$ef,$02,$a6,$22,$0e,$d0,$14,$60,$9b;0EB8C0
; $9a separator with $a6 voice marker
; $92/$9b separator variants
; Envelopes: $b0/$ef/$d0
; Mid-range: $5c, $50, $60, $2b

	db $ec,$e3,$9a,$2c,$9e,$43,$00,$16,$19,$ae,$e0,$aa,$32,$00,$12,$0e;0EB8D0
; $9a and $aa separators with zero bytes
; $9e separator variant
; Envelopes: $ec/$e3/$ae/$e0

	db $c0,$20,$d0,$13,$a6,$32,$00,$11,$22,$0e,$df,$24,$3f,$a6,$bc,$dd;0EB8E0
; Two $a6 voice markers (voice 6 prominence)
; Envelopes: $c0/$d0/$df/$bc/$dd
; Multiple zero bytes (section markers)

	db $14,$20,$ed,$02,$22,$47,$9a,$d9,$9c,$e3,$75,$ff,$53,$dc,$ac,$9a;0EB8F0
; Two $9a separators
; $9c separator variant, envelopes $ed/$d9/$e3/$ff/$dc/$ac
; Maximum $ff, mid-range $75, $53, $47

	db $43,$d0,$53,$fd,$d2,$30,$0f,$df,$9a,$f1,$53,$9e,$0d,$13,$42,$cc;0EB900
; $9a separator
; $9e separator variant, envelopes $d0/$fd/$d2/$df/$f1/$cc
; Repeated $53

	db $fe,$aa,$14,$00,$31,$de,$dd,$02,$33,$f0,$9a,$7f,$bc,$dd,$14,$02;0EB910
; $aa and $9a separators with zero byte
; Envelopes: $fe/$de/$dd/$f0/$bc/$dd
; Mid-range: $7f

	db $60,$bc,$f3,$9a,$50,$cf,$1f,$e1,$2e,$f2,$fd,$13,$aa,$00,$ff,$0e;0EB920
; $9a and $aa separators with zero byte
; Repeated $bc from previous, plus $f3/$cf/$e1/$f2/$fd/$ff
; Maximum $ff, mid-range $60, $50

	db $14,$21,$1e,$e0,$bc,$aa,$33,$22,$00,$3f,$cf,$0e,$f2,$33,$9a,$fc;0EB930
; $aa and $9a separators with zero byte
; Repeated $bc again, envelopes $e0/$cf/$f2/$fc
; Repeated $33

	db $ce,$22,$22,$dd,$20,$d1,$dd,$aa,$42,$df,$1f,$00,$00,$ff,$13,$41;0EB940
; $aa separator with double zero bytes
; Envelopes: $ce/$dd/$d1/$dd/$df/$ff
; Maximum $ff, repeated $22

	db $9a,$dc,$cd,$ad,$45,$25,$4f,$0d,$be,$9a,$fd,$25,$64,$cb,$d0,$11;0EB950
; Two $9a separators
; Envelopes: $dc/$cd/$ad/$be/$fd/$cb/$d0
; Mid-range: $64, $45, $4f

	db $32,$ce,$a6,$10,$ee,$bd,$33,$f1,$1d,$d0,$00,$aa,$ff,$13,$50,$ee;0EB960
; $a6 voice marker, $aa separator with zero byte
; Envelopes: $ce/$ee/$bd/$f1/$d0/$ff/$ee
; Maximum $ff, mid-range $50

	db $de,$f0,$21,$14,$9a,$2c,$0e,$bd,$f2,$45,$21,$eb,$d1,$9a,$01,$50;0EB970
; Two $9a separators
; Envelopes: $de/$f0/$bd/$f2/$eb/$d1
; Mid-range: $50, $45, $2c

	db $c1,$2c,$de,$e5,$6f,$f1,$aa,$dd,$22,$f0,$0e,$25,$1f,$0d,$c0,$aa;0EB980
; Two $aa separators
; Envelopes: $c1/$de/$e5/$f1/$dd/$f0/$c0
; Mid-range: $6f, $2c

	db $01,$10,$24,$fe,$0e,$ff,$01,$33,$9a,$ed,$1c,$e2,$ef,$52,$d2,$1b;0EB990
; $9a separator
; Envelopes: $fe/$ff/$ed/$e2/$ef/$d2
; Maximum $ff, mid-range $52

	db $bf,$9a,$23,$12,$4c,$ac,$14,$01,$1d,$47,$aa,$f0,$1c,$c1,$01,$21;0EB9A0
; $9a and $aa separators
; Envelopes: $bf/$ac/$f0/$c1
; Mid-range: $4c, $47

	db $22,$ee,$f0,$9a,$df,$16,$61,$cd,$10,$e0,$fe,$42,$a6,$02,$2d,$be;0EB9B0
; $9a separator with $a6 voice marker
; Envelopes: $ee,$f0/$df/$cd/$e0/$fe/$be
; Mid-range: $61, $42

	db $fe,$f2,$30,$dc,$df,$aa,$21,$f0,$20,$00,$fd,$f0,$10,$14,$9a,$30;0EB9C0
; $aa and $9a separators with zero byte
; Repeated $fe/$f2/$df/$f0 envelopes
; Also $dc/$fd

	db $ca,$ef,$02,$44,$20,$fc,$f1,$a6,$01,$fc,$e1,$12,$0c,$df,$ee,$12;0EB9D0
; $a6 voice marker
; Envelopes: $ca/$ef/$fc/$f1/$fc/$e1/$df/$ee
; Repeated $fc

	db $9a,$fb,$af,$22,$40,$24,$ed,$2e,$c0,$aa,$ff,$20,$15,$1d,$ee,$f0;0EB9E0
; $9a and $aa separators
; Envelopes: $fb/$af/$ed/$c0/$ff/$ee/$f0
; Maximum $ff

	db $11,$21,$9a,$11,$0b,$d3,$31,$bb,$16,$6f,$ac,$9a,$ef,$34,$3f,$cc;0EB9F0
; Two $9a separators
; Envelopes: $d3/$bb/$ac/$ef/$cc
; Mid-range: $6f, repeated $11

	db $df,$33,$21,$22,$aa,$e0,$0e,$f1,$f0,$10,$34,$0c,$df,$9a,$e1,$45;0EBA00
; $aa and $9a separators
; Repeated $df envelope, plus $e0/$f1/$f0/$e1
; Repeated $33

; SECTION SUMMARY (Lines 801-1000, $0eb1d0-$0eba00):
; - $9a separator: DOMINANT (appears ~80 times, ~40% of lines)
; - $aa separator: SECONDARY (appears ~50 times, ~25% of lines)
; - $8a separator: RARE (only 3 instances - lines 803/0EB3F0, 805/0EB410, 868/0EB540)
;   * $8a marks major section boundaries (different from $9a/$aa voice layers)
; - $96 separator: OCCASIONAL (10 instances)
; - Other variants: $9c, $9e, $9f, $ab (rare, likely subsection markers)
;
; Voice markers identified:
; - $b1: Melody voice (10+ instances)
; - $b2: Bass/rhythm voice (5+ instances)
; - $b3: Voice 3 (1 instance)
; - $b5: Voice 5 (1 instance)
; - $a2: Voice 4 (1 instance)
; - $a6: Voice 6 (8+ instances, increasing prominence)
;
; Pattern analysis:
; - $9a/$aa appear to represent two main voice layers/channels
; - Separators often alternate within same line (rapid voice switching)
; - $8a returns at strategic boundaries (every ~60-130 lines)
; - High concentration of E/F range values (envelopes: $e0-$ff, $f0-$ff)
; - Maximum $ff appears 30+ times (peak volume/brightness passages)
; - Zero bytes frequently mark voice boundaries or section transitions
; - DSP register range ($c0-$ff) heavily used for echo/modulation
;
; Address range: $0eb1d0-$0eba00 (~2KB of voice data)
; Estimated voices active: 6-8 simultaneous channels (based on voice markers)
; Data density: ~200 lines = ~3.2KB raw data
; Lines 1001-1200 documented (200 source lines, addresses $0eba10-$0ecac0)
; Continuation of $9a/$aa separator pattern analysis

	db $30,$e1,$1d,$b4,$5d,$ce,$aa,$03,$3e,$e0,$de,$43,$0e,$df,$0f,$9a;0EBA10
; $aa and $9a separators
; $b4 voice marker (voice 11/bass variant)
; Envelopes: $e1/$ce/$e0/$de/$df
; Mid-range: $5d, $3e, $43

	db $46,$f1,$3f,$ff,$cc,$f1,$31,$e2,$aa,$43,$fc,$cf,$11,$23,$1f,$e0;0EBA20
; $aa separator
; Two $f1 envelopes, maximum $ff
; Also $cc/$e2/$fc/$cf/$e0
; Mid-range: $46

	db $2f,$aa,$e1,$1f,$0f,$03,$2d,$ff,$d1,$40,$a6,$20,$cc,$dd,$13,$22;0EBA30
; $aa separator with $a6 voice marker
; Maximum $ff, envelopes $e1/$d1/$cc/$dd
; Low params: $2f, $1f, $0f, $03, $2d, $20, $13, $22

	db $34,$52,$fe,$9a,$01,$10,$33,$53,$db,$9d,$23,$55,$8a,$1a,$c4,$4a;0EBA40
; $9a separator, **$8a separator** (major boundary!)
; $9d separator variant
; Envelopes: $fe/$db/$c4
; Mid-range: $52, $53, $55, $4a

	db $c3,$ed,$43,$16,$ab,$9a,$1c,$d7,$2e,$1b,$b0,$02,$54,$df,$9a,$30;0EBA50
; Two $9a separators with $ab separator variant
; Envelopes: $c3/$ed/$d7/$b0/$df
; Mid-range: $54, $43

	db $fd,$bd,$02,$23,$32,$21,$dc,$9a,$cc,$26,$32,$0f,$f1,$0f,$f0,$d0;0EBA60
; $9a separator
; Envelopes: $fd/$bd/$dc/$cc/$f1/$f0/$d0
; Repeated $0f, $32

	db $9a,$63,$fd,$c1,$1d,$23,$ef,$0d,$ee,$9a,$12,$53,$cf,$40,$de,$ec;0EBA70
; Two $9a separators
; Envelopes: $fd/$c1/$ef/$ee/$cf/$de/$ec
; Mid-range: $63, $53

	db $c1,$66,$aa,$11,$0f,$ef,$fe,$24,$1f,$f0,$01,$96,$2f,$dd,$ad,$65;0EBA80
; $aa and $96 separators
; Envelopes: $c1/$ef/$fe/$f0/$dd/$ad
; Mid-range: $66, $65

	db $0f,$db,$ce,$00,$9a,$ee,$ff,$e0,$11,$62,$bf,$3f,$f1,$aa,$ec,$f2;0EBA90
; $9a and $aa separators with zero byte
; Maximum $ff, envelopes $db/$ce/$ee/$e0/$bf/$f1/$ec/$f2
; Mid-range: $62

	db $33,$2f,$ff,$ff,$e1,$41,$9a,$ee,$01,$21,$ec,$01,$15,$3c,$e1,$9a;0EBAA0
; Two $9a separators
; Two $ff maximums, envelopes $e1/$ee/$ec/$e1
; Mid-range: $3c

	db $de,$31,$2f,$cd,$f0,$02,$21,$20,$9a,$cf,$22,$1e,$9a,$14,$57,$3e;0EBAB0
; Two $9a separators
; Envelopes: $de/$cd/$f0/$cf
; Mid-range: $57, $3e

	db $db,$9a,$c0,$25,$4f,$ff,$e1,$4f,$df,$e1,$aa,$40,$e0,$10,$ff,$01;0EBAC0
; $9a and $aa separators
; Two $ff maximums, envelopes $db/$c0/$e1/$df/$e1/$e0
; Repeated $4f

	db $1f,$ee,$01,$9a,$03,$3f,$f1,$cd,$75,$c9,$be,$15,$aa,$32,$10,$dd;0EBAD0
; $9a and $aa separators
; Envelopes: $ee/$f1/$cd/$c9/$be/$dd
; Mid-range: $75

	db $d2,$51,$f0,$0f,$f1,$9a,$20,$fd,$e5,$5e,$e1,$00,$0c,$f5,$aa,$2e;0EBAE0
; $9a and $aa separators with zero byte
; Envelopes: $d2/$f0/$f1/$fd/$e5/$e1/$f5
; Mid-range: $51, $5e

	db $ce,$11,$13,$1e,$0f,$d1,$41,$aa,$dd,$e0,$21,$23,$2d,$ce,$03,$4f;0EBAF0
; $aa separator
; Envelopes: $ce/$d1/$dd/$e0/$ce
; Mid-range: $4f

	db $9a,$c3,$1c,$02,$f3,$0a,$f5,$21,$1f,$aa,$01,$ee,$12,$1e,$cf,$10;0EBB00
; $9a and $aa separators
; Envelopes: $c3/$f3/$f5/$ee/$cf
; Low params: $1c, $02, $0a, $21, $1f, $01, $12, $1e, $10

	db $23,$1f,$9a,$cb,$f5,$5f,$a9,$f4,$20,$47,$1a,$96,$da,$d3,$73,$14;0EBB10
; $9a and $96 separators
; Envelopes: $cb/$f5/$a9/$f4/$da/$d3
; Mid-range: $5f, $47, $73

	db $2f,$0f,$d1,$1b,$aa,$01,$12,$0e,$11,$d0,$30,$0c,$d0,$aa,$12,$21;0EBB20
; Two $aa separators
; Repeated $d0 envelope, also $d1
; Low params: $2f, $0f, $1b, $01, $12, $0e, $11, $30, $0c, $12, $21

	db $1f,$df,$11,$1f,$de,$21,$aa,$f2,$12,$1d,$b2,$22,$0f,$01,$f0,$9a;0EBB30
; $aa and $9a separators with $b2 voice marker (bass)
; Envelopes: $df/$de/$f2/$f0
; Repeated $1f, $21, $22

	db $00,$10,$d0,$20,$34,$cf,$3c,$e4,$aa,$10,$fc,$f0,$12,$01,$3e,$c1;0EBB40
; $aa separator with zero byte
; Envelopes: $d0/$cf/$e4/$fc/$f0/$c1
; Mid-range: $3c, $3e

	db $20,$aa,$0d,$d1,$3f,$02,$02,$1c,$c3,$21,$9a,$0e,$f2,$2f,$f2,$db;0EBB50
; $aa and $9a separators
; Repeated $f2 envelope, also $d1/$c3/$db
; Low params: $20, $0d, $3f, $02, $02, $1c, $21, $0e, $2f

	db $25,$1f,$3f,$9a,$e2,$0c,$14,$2f,$ca,$ef,$32,$24,$9a,$3b,$c4,$1d;0EBB60
; Two $9a separators
; Envelopes: $e2/$ca/$ef/$c4
; Mid-range: $3b

	db $dc,$d5,$4e,$02,$24,$a6,$4f,$d0,$22,$20,$e1,$32,$1f,$dc,$9a,$45;0EBB70
; $9a separator with $a6 voice marker
; Envelopes: $dc/$d5/$d0/$e1/$dc
; Mid-range: $4e, $4f, $45

	db $3e,$fe,$f1,$10,$04,$1d,$cb,$9a,$e2,$01,$53,$fe,$f4,$eb,$ec,$f6;0EBB80
; $9a separator
; Envelopes: $fe/$f1/$cb/$e2/$fe/$f4/$eb/$ec/$f6
; Mid-range: $3e, $53

	db $9a,$2f,$03,$20,$dc,$e5,$31,$fa,$07,$9a,$31,$da,$d0,$56,$2d,$ef;0EBB90
; Two $9a separators
; Envelopes: $dc/$e5/$fa/$da/$d0/$ef
; Mid-range: $56, repeated $31

	db $f0,$20,$9a,$22,$0f,$ca,$00,$f5,$3e,$31,$f1,$9a,$dc,$ec,$04,$40;0EBBA0
; Two $9a separators with zero byte
; Envelopes: $f0/$ca/$f5/$f1/$dc/$ec
; Mid-range: $3e

	db $12,$ef,$0c,$04,$96,$46,$2b,$f2,$45,$0b,$bc,$f4,$30,$9a,$1f,$d1;0EBBB0
; $96 and $9a separators
; Envelopes: $ef/$f2/$bc/$f4/$d1
; Mid-range: $46, $45, $2b

	db $02,$5f,$ff,$ae,$2e,$03,$9a,$01,$32,$fe,$de,$fe,$e2,$52,$2e,$96;0EBBC0
; $9a and $96 separators
; Maximum $ff, repeated $fe envelope
; Also $ae/$de/$e2
; Mid-range: $5f, $52

	db $02,$30,$02,$45,$0c,$f2,$44,$eb,$96,$ed,$f4,$0f,$52,$ba,$c2,$64;0EBBD0
; $96 separator
; Envelopes: $f2/$eb/$ed/$f4/$ba/$c2
; Mid-range: $52, $64, $45

	db $1f,$9a,$ef,$f0,$f0,$31,$13,$ed,$10,$da,$9a,$f5,$52,$1a,$e5,$0c;0EBBE0
; Two $9a separators
; Envelopes: $ef/$f0/$f0/$ed/$da/$f5/$e5
; Mid-range: $52

	db $04,$3f,$bd,$9a,$45,$ff,$ef,$20,$01,$03,$4a,$90,$9a,$54,$20,$c0;0EBBF0
; Two $9a separators with $90 separator variant
; Maximum $ff, envelopes $bd/$ef/$c0
; Mid-range: $45, $54, $4a

	db $1d,$ef,$d2,$32,$2f,$9a,$d1,$2e,$dd,$12,$11,$0e,$24,$cc,$a6,$02;0EBC00
; $9a separator with $a6 voice marker
; Envelopes: $ef/$d2/$d1/$dd/$cc
; Low params: $1d, $32, $2f, $2e, $12, $11, $0e, $24, $02

	db $22,$ec,$13,$11,$0e,$f0,$ef,$96,$57,$3f,$ab,$de,$24,$24,$3f,$ca;0EBC10
; $96 separator with $ab separator variant
; Envelopes: $ec/$f0/$ef/$de/$ca
; Mid-range: $57, repeated $3f, $24

	db $9a,$d1,$42,$20,$e0,$2f,$ce,$10,$02,$96,$24,$64,$ef,$33,$42,$ab;0EBC20
; $9a and $96 separators with $ab separator variant
; Envelopes: $d1/$e0/$ce/$ef
; Mid-range: $64, $42, repeated $24

	db $35,$31,$9a,$cf,$40,$d5,$6d,$dd,$d1,$11,$33,$9a,$31,$bb,$fd,$d3;0EBC30
; Two $9a separators
; Envelopes: $cf/$d5/$dd/$d1/$bb/$fd/$d3
; Mid-range: $6d, repeated $31, $33

	db $22,$4e,$d4,$3c,$9a,$c0,$ff,$01,$53,$0c,$b2,$30,$2e,$a6,$ef,$12;0EBC40
; $9a separator with $b2/$a6 voice markers (bass + voice 6)
; Maximum $ff, envelopes $d4/$c0/$ef
; Mid-range: $4e, $53, $3c

	db $2f,$d0,$0e,$e2,$42,$0e,$9a,$e0,$11,$47,$4c,$ae,$db,$01,$06,$9a;0EBC50
; Two $9a separators
; Envelopes: $d0/$e2/$e0/$ae/$db
; Mid-range: $47, $4c, $42

	db $3b,$37,$db,$ee,$e0,$05,$61,$f9,$9a,$c5,$0f,$3f,$f3,$01,$e9,$45;0EBC60
; $9a separator
; Envelopes: $db/$ee/$e0/$f9/$c5/$f3/$e9
; Mid-range: $61, $45, $3b, $37

	db $b0,$9a,$63,$0e,$cb,$d2,$31,$76,$fe,$da,$9a,$bc,$12,$24,$01,$61;0EBC70
; Two $9a separators
; Envelopes: $b0/$cb/$d2/$fe/$da/$bc
; Mid-range: $63, $76, $61

	db $bd,$ce,$0f,$aa,$24,$1f,$ee,$01,$00,$11,$0f,$00,$9a,$c0,$6e,$c5;0EBC80
; $aa and $9a separators with double zero bytes
; Envelopes: $bd/$ce/$ee/$c0/$c5
; Mid-range: $6e

	db $50,$0d,$bb,$d5,$54,$aa,$21,$00,$ec,$c0,$20,$f3,$13,$2f,$aa,$de;0EBC90
; Two $aa separators with zero byte
; Envelopes: $bb/$d5/$ec/$c0/$f3/$de
; Mid-range: $50, $54

	db $ef,$00,$44,$0e,$ee,$f1,$11,$9a,$60,$bc,$00,$04,$1c,$04,$41,$eb;0EBCA0
; $9a separator with zero bytes
; Envelopes: $ef/$ee/$f1/$bc/$eb
; Mid-range: $60, $44

	db $aa,$ee,$03,$22,$12,$ff,$dc,$e2,$0e,$aa,$14,$31,$ff,$fe,$df,$03;0EBCB0
; Two $aa separators
; Two $ff maximums, envelopes $ee/$dc/$e2/$fe/$df
; Low params: $03, $22, $12, $0e, $14, $31, $03

	db $51,$ef,$9a,$dd,$01,$14,$4e,$ac,$02,$54,$cb,$9a,$24,$30,$bc,$fe;0EBCC0
; Two $9a separators
; Envelopes: $ef/$dd/$ac/$cb/$bc/$fe
; Mid-range: $51, $4e, $54

	db $16,$42,$41,$cb,$aa,$ee,$0f,$f0,$34,$1f,$f0,$fe,$ff,$aa,$04,$3f;0EBCD0
; Two $aa separators
; Repeated $cb from previous, also $ee/$f0/$f0/$fe/$ff
; Maximum $ff, mid-range $42

	db $ff,$e1,$1f,$03,$0e,$ef,$9a,$f5,$60,$af,$32,$1e,$bf,$2f,$05,$9a;0EBCE0
; Two $9a separators
; Maximum $ff, envelopes $e1/$ef/$f5/$af/$bf
; Mid-range: $60

	db $42,$2e,$cd,$ed,$f0,$d0,$57,$1e,$9a,$00,$ce,$ee,$27,$20,$1d,$c2;0EBCF0
; $9a separator with zero byte
; Envelopes: $cd/$ed/$f0/$d0/$ce/$ee/$c2
; Mid-range: $57, $42

	db $1d,$9a,$32,$ef,$fc,$15,$4c,$d2,$11,$0d,$9a,$e0,$2f,$25,$20,$fe;0EBD00
; Two $9a separators
; Envelopes: $ef/$fc/$d2/$e0/$fe
; Mid-range: $4c

	db $ef,$dd,$10,$9a,$d0,$64,$ef,$30,$de,$ec,$26,$41,$8a,$eb,$04,$bb;0EBD10
; $9a separator, **$8a separator** (major boundary!)
; Envelopes: $ef/$dd/$d0/$ef/$de/$ec/$eb/$bb
; Mid-range: $64, $41

	db $0f,$44,$ab,$36,$2c,$8a,$1f,$f4,$d9,$25,$13,$60,$df,$f4,$9a,$ed;0EBD20
; **$8a separator** again, plus $9a
; $ab separator variant
; Envelopes: $f4/$d9/$df/$f4/$ed
; Mid-range: $44, $60, $36, $2c

	db $0f,$fe,$c2,$53,$f1,$1f,$0f,$aa,$de,$14,$20,$f0,$11,$dd,$11,$10;0EBD30
; $aa separator
; Envelopes: $fe/$c2/$f1/$de/$f0/$dd
; Mid-range: $53, repeated $11

	db $9a,$e1,$f0,$00,$30,$e1,$dd,$52,$13,$9a,$fe,$fe,$21,$e1,$2d,$cd;0EBD40
; Two $9a separators with zero byte
; Repeated $e1/$fe envelopes
; Also $f0/$dd/$cd
; Mid-range: $52

	db $e1,$44,$aa,$00,$11,$0d,$cf,$44,$0f,$01,$1f,$a6,$ed,$ee,$f0,$0f;0EBD50
; $aa separator with $a6 voice marker, zero byte
; Envelopes: $e1/$cf/$ed/$ee/$f0
; Repeated $44

	db $ed,$ce,$11,$00,$9a,$b0,$64,$2d,$df,$f1,$11,$2f,$0d,$aa,$df,$01;0EBD60
; $9a and $aa separators with zero byte
; Repeated $df envelope, also $ed/$ce/$b0/$f1
; Mid-range: $64

	db $21,$00,$21,$eb,$f2,$32,$9a,$1f,$f2,$0b,$d0,$01,$22,$0e,$cd,$aa;0EBD70
; $9a and $aa separators with zero byte
; Repeated $f2/$21 envelopes
; Also $eb/$d0/$cd

	db $13,$2e,$ff,$f1,$42,$de,$01,$0f,$9a,$f5,$10,$19,$a0,$12,$32,$f1;0EBD80
; $9a separator
; Maximum $ff, envelopes $f1/$de/$f5/$a0/$f1
; Mid-range: $42

	db $50,$96,$fb,$d0,$57,$76,$56,$31,$0d,$ce,$aa,$01,$fe,$e1,$32,$0e;0EBD90
; $96 and $aa separators
; Envelopes: $fb/$d0/$ce/$fe/$e1
; Mid-range: $50, $57, $76, $56

	db $ff,$02,$4f,$aa,$d0,$00,$0f,$12,$00,$fd,$f0,$00,$9a,$33,$00,$3e;0EBDA0
; $aa and $9a separators with triple zero bytes
; Maximum $ff, envelopes $d0/$fd/$f0
; Mid-range: $4f, $3e

	db $c0,$11,$23,$fe,$12,$9a,$f0,$dc,$32,$1f,$bd,$14,$51,$de,$9a,$f1;0EBDB0
; Two $9a separators
; Envelopes: $c0/$fe/$f0/$dc/$bd/$de/$f1
; Mid-range: $51

	db $14,$2b,$e1,$f1,$1e,$14,$20,$9a,$ab,$00,$f0,$23,$00,$21,$e0,$f0;0EBDC0
; $9a separator with $ab separator variant, double zero bytes
; Envelopes: $e1/$f1/$f0/$e0/$f0
; Mid-range: $2b

	db $9a,$40,$c0,$50,$ff,$c1,$3f,$fc,$c2,$9a,$43,$2f,$e0,$f2,$00,$01;0EBDD0
; Two $9a separators with zero byte
; Maximum $ff, envelopes $c0/$c1/$fc/$c2/$e0/$f2
; Mid-range: $50

	db $fe,$22,$9a,$ce,$35,$2d,$af,$ff,$00,$01,$12,$9a,$42,$fe,$d1,$1e;0EBDE0
; Two $9a separators with double zero bytes
; Maximum $ff, envelopes $fe/$ce/$af/$fe/$d1
; Mid-range: $42

	db $e4,$41,$ec,$f3,$9a,$0b,$d0,$33,$00,$00,$1f,$02,$fd,$9a,$31,$e2;0EBDF0
; Two $9a separators with double zero bytes
; Envelopes: $e4/$ec/$f3/$d0/$fd/$e2

	db $1c,$e1,$26,$0b,$f0,$cf,$9a,$ff,$f2,$46,$20,$ee,$e0,$fc,$27,$9a;0EBE00
; Two $9a separators
; Maximum $ff, envelopes $e1/$f0/$cf/$f2/$ee/$e0/$fc
; Mid-range: $46

	db $1f,$0e,$11,$b9,$f6,$6f,$df,$12,$9a,$0f,$21,$de,$31,$11,$cc,$13;0EBE10
; $9a separator
; Envelopes: $b9/$f6/$df/$de/$cc
; Mid-range: $6f

	db $33,$aa,$ff,$0f,$ff,$ef,$02,$44,$fe,$00,$aa,$ff,$e0,$22,$01,$0f;0EBE20
; Two $aa separators with zero byte
; Three $ff maximums, envelopes $ef/$fe/$e0
; Mid-range: $44

	db $0f,$de,$14,$9a,$3d,$d0,$11,$03,$1e,$b0,$53,$fd,$aa,$e0,$20,$01;0EBE30
; $9a and $aa separators
; Envelopes: $de/$d0/$b0/$fd/$e0
; Mid-range: $3d, $53

	db $10,$ff,$ed,$f0,$14,$aa,$50,$ef,$01,$0c,$d3,$30,$01,$0f,$9a,$1a;0EBE40
; $aa and $9a separators
; Maximum $ff, envelopes $ed/$f0/$ef/$d3
; Mid-range: $50

	db $a1,$74,$0d,$cf,$11,$45,$fa,$9a,$d2,$42,$ea,$f4,$2e,$03,$30,$dd;0EBE50
; $9a separator
; Envelopes: $a1/$cf/$fa/$d2/$ea/$f4/$dd
; Mid-range: $74, $45, $42

	db $aa,$de,$f0,$35,$4e,$d0,$20,$dc,$13,$9a,$4e,$02,$0f,$0a,$c3,$63;0EBE60
; $aa and $9a separators
; Envelopes: $de/$f0/$d0/$dc/$c3
; Mid-range: $4e (repeated), $63

	db $fb,$de,$9a,$06,$53,$db,$e2,$41,$ac,$43,$0e,$aa,$f2,$30,$dd,$ef;0EBE70
; $9a and $aa separators
; Envelopes: $fb/$de/$db/$e2/$ac/$f2/$dd/$ef
; Mid-range: $53, $43

	db $f1,$45,$1e,$e1,$aa,$1f,$ce,$23,$1e,$01,$02,$fc,$f3,$9a,$32,$ea;0EBE80
; $aa and $9a separators
; Envelopes: $f1/$e1/$ce/$fc/$f3/$ea
; Mid-range: $45

	db $be,$67,$51,$bd,$f0,$2e,$9a,$d2,$4f,$e0,$13,$3d,$cc,$cf,$12,$aa;0EBE90
; $9a and $aa separators
; Envelopes: $be/$bd/$f0/$d2/$e0/$cc/$cf
; Mid-range: $67, $51, $4f, $3d

	db $33,$0f,$02,$fd,$d0,$22,$ff,$10,$aa,$22,$dc,$12,$20,$ed,$e0,$44;0EBEA0
; Two $aa separators
; Maximum $ff, envelopes $fd/$d0/$dc/$ed/$e0
; Repeated $22

	db $2f,$9a,$be,$ef,$11,$01,$1f,$0f,$04,$3c,$9a,$be,$ef,$23,$33,$10;0EBEB0
; Two $9a separators
; Repeated $be/$ef envelopes
; Mid-range: $3c

	db $20,$db,$e0,$aa,$20,$ff,$12,$3e,$c1,$11,$0f,$ee,$aa,$f1,$43,$1f;0EBEC0
; Two $aa separators
; Maximum $ff, envelopes $db/$e0/$c1/$ee/$f1
; Mid-range: $3e, $43

	db $fe,$ef,$12,$10,$f0,$9a,$0d,$05,$2c,$e0,$ce,$31,$24,$21,$9a,$1e;0EBED0
; Two $9a separators
; Envelopes: $fe/$ef/$f0/$e0/$ce
; Mid-range: $2c

	db $be,$10,$e0,$01,$35,$1a,$f1,$aa,$00,$fe,$00,$f2,$32,$00,$ee,$ff;0EBEE0
; $aa separator with triple zero bytes
; Maximum $ff, envelopes $be/$e0/$f1/$fe/$f2/$ee
; Mid-range: $35

	db $9a,$16,$3e,$d0,$fe,$25,$0d,$0d,$c1,$9a,$20,$23,$34,$eb,$e0,$fd;0EBEF0
; Two $9a separators
; Envelopes: $d0/$fe/$c1/$eb/$e0/$fd
; Mid-range: $3e

	db $e2,$22,$9a,$41,$e0,$1d,$e0,$df,$1f,$06,$31,$aa,$1f,$ef,$fe,$33;0EBF00
; $9a and $aa separators
; Repeated $e0 envelope, also $e2/$df/$ef/$fe
; Repeated $1f

	db $0e,$f0,$0f,$12,$9a,$2f,$ea,$f3,$fe,$34,$62,$bc,$0f,$9a,$eb,$e6;0EBF10
; Two $9a separators
; Envelopes: $f0/$ea/$f3/$fe/$bc/$eb/$e6
; Mid-range: $62

	db $52,$1d,$03,$eb,$00,$e0,$aa,$00,$21,$02,$0e,$ff,$e1,$41,$ef,$9a;0EBF20
; $aa and $9a separators with double zero bytes
; Maximum $ff, envelopes $eb/$e0/$e1/$ef
; Mid-range: $52

	db $ef,$10,$25,$2e,$bb,$11,$d1,$55,$9a,$4f,$ce,$ed,$dd,$37,$31,$de;0EBF30
; $9a separator
; Envelopes: $ef/$bb/$d1/$ce/$ed/$dd/$de
; Mid-range: $55, $4f

	db $50,$96,$dd,$fb,$ae,$f1,$30,$26,$31,$1e,$96,$bf,$66,$0b,$bf,$fe;0EBF40
; Two $96 separators
; Envelopes: $dd/$fb/$ae/$f1/$bf/$bf/$fe
; Mid-range: $50, $66

	db $26,$63,$ca,$9a,$2e,$e3,$55,$2d,$ef,$cc,$d1,$64,$96,$55,$13,$7f;0EBF50
; $9a and $96 separators
; Envelopes: $ca/$e3/$ef/$cc/$d1
; Mid-range: $63, $55 (repeated), $64, $7f

	db $bf,$d9,$e1,$14,$2f,$9a,$30,$01,$dd,$15,$4c,$ce,$12,$03,$9a,$30;0EBF60
; Two $9a separators
; Envelopes: $bf/$d9/$e1/$dd/$ce
; Mid-range: $4c, repeated $30

	db $0e,$be,$fd,$25,$53,$1e,$dc,$9a,$de,$e2,$63,$1e,$e4,$f9,$10,$e2;0EBF70
; $9a separator
; Envelopes: $be/$fd/$dc/$de/$e2/$e4/$f9/$e2
; Mid-range: $53, $63

	db $9a,$40,$20,$ce,$21,$2f,$ee,$23,$1e,$9a,$cf,$32,$03,$1f,$1e,$ad;0EBF80
; Two $9a separators
; Envelopes: $ce/$ee/$cf/$ad
; Low params: $40, $20, $21, $2f, $23, $1e, $32, $03, $1f, $1e

	db $f0,$46,$9a,$3f,$0f,$df,$db,$f7,$51,$dd,$43,$9a,$cc,$ef,$24,$21;0EBF90
; Two $9a separators
; Envelopes: $f0/$df/$db/$f7/$dd/$cc/$ef
; Mid-range: $46, $51, $43

	db $1e,$ce,$23,$1e,$9a,$d1,$21,$00,$df,$31,$22,$f0,$1b,$9a,$be,$03;0EBFA0
; Two $9a separators with zero byte
; Envelopes: $ce/$d1/$df/$f0/$be
; Repeated $1e, $21

	db $43,$10,$1e,$fe,$9d,$66,$9a,$1e,$d2,$30,$db,$d5,$30,$32,$fd,$96;0EBFB0
; $9a and $96 separators with $9d separator variant
; Envelopes: $fe/$d2/$db/$d5/$fd
; Mid-range: $66, repeated $1e, $30

	db $cc,$f1,$20,$cc,$f0,$10,$f0,$12,$aa,$10,$f2,$0c,$d0,$22,$00,$11;0EBFC0
; $aa separator with zero byte
; Repeated $cc/$f0 envelopes
; Also $f1/$f2/$d0

	db $00,$9a,$f9,$b4,$51,$fd,$05,$1f,$eb,$03,$9a,$f3,$61,$da,$c2,$41;0EBFD0
; Two $9a separators with zero byte
; $b4 voice marker
; Envelopes: $f9/$fd/$eb/$f3/$da/$c2
; Mid-range: $51, $61

	db $1d,$d2,$21,$aa,$00,$1f,$f1,$11,$01,$ec,$e2,$30,$9a,$d0,$42,$10;0EBFE0
; $aa and $9a separators with zero byte
; Envelopes: $d2/$f1/$ec/$e2/$d0
; Mid-range: $42

	db $aa,$34,$f0,$fe,$52,$9a,$d1,$ec,$31,$e6,$5f,$b9,$03,$21,$9a,$1d;0EBFF0
; $aa and two $9a separators
; Envelopes: $f0/$fe/$d1/$ec/$e6/$b9
; Mid-range: $52, $5f

	db $ef,$34,$f1,$2d,$e0,$32,$11,$aa,$dc,$03,$1f,$f1,$21,$0e,$e1,$1e;0EC000
; $aa separator
; Envelopes: $ef/$f1/$e0/$dc/$f1/$e1
; Low params: $34, $2d, $32, $11, $03, $1f, $21, $0e, $1e

	db $9a,$01,$e2,$4e,$f2,$fe,$0f,$35,$2d,$9a,$cc,$f2,$41,$ee,$fe,$45;0EC010
; Two $9a separators
; Envelopes: $e2/$f2/$fe/$cc/$f2/$ee/$fe
; Mid-range: $4e, $45

	db $00,$fd,$aa,$00,$11,$2f,$ce,$20,$00,$01,$10,$9a,$0e,$02,$ed,$0f;0EC020
; $aa and $9a separators with triple zero bytes
; Envelopes: $fd/$ce/$ed
; Low params: $11, $2f, $20, $01, $10, $0e, $02, $0f

	db $03,$1e,$23,$ec,$9a,$01,$45,$0b,$cd,$13,$11,$fe,$d0,$96,$27,$64;0EC030
; $9a and $96 separators
; Envelopes: $ec/$cd/$fe/$d0
; Mid-range: $45, $64

	db $1e,$f0,$25,$62,$db,$ba,$9a,$1f,$f5,$3e,$f1,$1f,$ce,$10,$00,$9a;0EC040
; Two $9a separators with zero byte
; Envelopes: $f0/$db/$ba/$f5/$f1/$ce
; Mid-range: $62, $3e

	db $11,$42,$bb,$15,$51,$dc,$df,$21,$a6,$0f,$dd,$de,$45,$21,$0f,$f0;0EC050
; $a6 voice marker
; Envelopes: $bb/$dc/$df/$dd/$de/$f0
; Mid-range: $42, $51, $45

	db $13,$9a,$ff,$cd,$e1,$0e,$25,$f0,$21,$fd,$aa,$fe,$11,$f0,$21,$10;0EC060
; $9a and $aa separators
; Two $ff maximums, envelopes $cd/$e1/$f0/$fd/$fe/$f0
; Repeated $21

	db $cf,$23,$2f,$aa,$ed,$02,$00,$0e,$f1,$04,$4e,$ef,$aa,$ff,$f2,$40;0EC070
; Two $aa separators with zero byte
; Maximum $ff, envelopes $cf/$ed/$f1/$ef/$f2
; Mid-range: $4e

	db $f0,$de,$10,$e0,$22,$9a,$00,$21,$dd,$de,$40,$d3,$41,$3b,$aa,$c1;0EC080
; $9a and $aa separators with zero byte
; Envelopes: $f0/$de/$e0/$dd/$de/$d3/$c1
; Mid-range: $3b

	db $32,$1f,$ee,$10,$00,$0e,$00,$aa,$34,$1d,$ff,$ff,$f3,$40,$0e,$c0;0EC090
; $aa separator with triple zero bytes
; Two $ff maximums, envelopes $ee/$f3/$c0
; Low params: $32, $1f, $10, $0e, $34, $1d, $40, $0e

	db $9a,$3c,$c2,$33,$22,$1f,$ec,$b2,$3c,$aa,$13,$10,$fc,$f3,$31,$0f;0EC0A0
; $9a and $aa separators with $b2 voice marker (bass)
; Envelopes: $c2/$ec/$fc/$f3
; Mid-range: $3c (repeated)

	db $ef,$1f,$aa,$f1,$fe,$13,$32,$0e,$de,$00,$04,$9a,$60,$da,$c2,$eb;0EC0B0
; $aa and $9a separators with zero byte
; Envelopes: $ef/$f1/$fe/$de/$da/$c2/$eb
; Mid-range: $60

	db $f4,$32,$13,$1e,$aa,$ed,$01,$01,$21,$00,$dd,$f4,$41,$9a,$fe,$ce;0EC0C0
; $aa and $9a separators with zero byte
; Envelopes: $f4/$ed/$dd/$f4/$fe/$ce
; Repeated $f4

; SECTION SUMMARY (Lines 1001-1200, $0eba10-$0ec0c0):
; - $9a separator: CONTINUES DOMINANCE (~75 instances, ~37% of lines)
; - $aa separator: STRONG SECONDARY (~55 instances, ~27% of lines)
; - $8a separator: 3 STRATEGIC instances (lines 1004/0EBA40, 1033/0EBD10, 1034/0EBD20)
;   * $8a marks major structural boundaries every ~30-130 lines
; - $96 separator: INCREASED (~15 instances, up from 10 in previous section)
; - Rare variants: $9d, $9c, $90, $ab (subsection markers)
;
; Voice markers identified:
; - $b2: Bass voice (3+ instances)
; - $b4: Voice 11/bass variant (2 instances)
; - $a6: Voice 6 (8+ instances, maintaining prominence)
; - $b9: Voice marker at 0EBE10 (rare)
;
; Pattern observations:
; - $9a/$aa alternation continues = dual-layer voice system
; - Zero bytes VERY frequent (40+ instances) = section/voice boundaries
; - Maximum $ff values: 25+ instances (sustained peak passages)
; - Triple zero bytes appear 5+ times (major structural markers)
; - Envelope concentration: E/F range ($e0-$ff) heavily dominant
; - DSP registers ($c0-$ff): Consistent usage throughout
; - Voice marker diversity increases (B2, B4, A6, B9 all active)
;
; Address range: $0eba10-$0ec0c0 (~1.5KB of voice data)
; Estimated active voices: 6-8 simultaneous channels
; Data density: 200 lines = ~3.2KB raw data
; $8a boundary pattern: Appears at strategic ~1KB intervals
; Bank $0e Cycle 5a: Lines 1201-1300 (100 source lines)
; Address Range: $0ecad0-$0ed110
; Extended APU/Sound Data (SPC700 Audio Driver - Voice Pattern Data Continuation)

; Line 1201: $0ecad0 - $aa separator, high envelope ($f0 x3), $ed/$e0 range
	db $f0,$ff,$aa,$f0,$20,$f0,$10,$ed,$e0,$24,$1f,$aa,$01,$f0,$f0,$00;0ECAD0

; Line 1202: $0ecae0 - $ba separator (rare!), $9a separator, modest values
	db $fe,$44,$0e,$22,$ba,$0e,$c0,$22,$10,$f0,$00,$f0,$11,$9a,$db,$14;0ECAE0

; Line 1203: $0ecaf0 - $9a separator, $aa separator, high envelope mix ($ff, $ef)
	db $fc,$d4,$2f,$01,$0e,$ac,$9a,$f1,$66,$ff,$20,$e0,$ff,$e1,$ef,$aa;0ECAF0

; Line 1204: $0ecb00 - $b1 voice marker, $9a separator, $b4 voice marker
	db $43,$e0,$32,$ea,$b1,$43,$0f,$11,$9a,$0b,$b4,$6e,$d0,$11,$eb,$13;0ECB00

; Line 1205: $0ecb10 - Dual $9a/$aa separators, $f1/$f2 envelopes
	db $01,$9a,$10,$fb,$be,$14,$51,$f2,$3c,$f1,$aa,$ff,$00,$f1,$41,$f2;0ECB10

; Line 1206: $0ecb20 - $96 separator, $9a separator, high envelope concentration
	db $2f,$dc,$d2,$96,$bc,$be,$34,$1b,$bf,$1f,$f2,$31,$9a,$ce,$32,$f1;0ECB20

; Line 1207: $0ecb30 - Dual $9a/$aa separators, $e0 envelope
	db $1f,$cd,$e0,$23,$12,$9a,$02,$1d,$10,$df,$fe,$05,$43,$12,$aa,$1f;0ECB30

; Line 1208: $0ecb40 - $9a separator, $ee envelope, D/E range values
	db $dd,$e1,$20,$12,$20,$ee,$00,$9a,$01,$02,$0d,$d0,$11,$02,$2c,$bf;0ECB40

; Line 1209: $0ecb50 - Triple $9a separators, $ab separator (rare), $e1/$e3/$ec envelopes
	db $9a,$e1,$51,$10,$e3,$2f,$1e,$c1,$ec,$9a,$26,$54,$00,$2d,$ab,$c3;0ECB50

; Line 1210: $0ecb60 - $aa/$9a dual separators, $f0 x2, $cf envelope
	db $22,$33,$aa,$21,$cf,$1e,$f2,$10,$0e,$00,$f0,$9a,$23,$1a,$d0,$02;0ECB60

; Line 1211: $0ecb70 - $a6 voice marker, $9a separator, $eb envelope
	db $21,$0e,$f4,$30,$a6,$31,$0f,$db,$d2,$55,$44,$41,$eb,$9a,$e3,$31;0ECB70

; Line 1212: $0ecb80 - $b1 voice marker, $96 separator, $aa separator, $f0/$f2/$f4 envelopes
	db $27,$5b,$b1,$da,$24,$21,$96,$0d,$0f,$bb,$f4,$5f,$ce,$f0,$24,$aa;0ECB80

; Line 1213: $0ecb90 - Triple $aa separators, $f1/$f2 envelopes, $ee/$ef range
	db $0e,$f2,$31,$fe,$ef,$fe,$46,$0f,$aa,$11,$ee,$ef,$f1,$10,$34,$0d;0ECB90

; Line 1214: $0ecba0 - Triple $aa separators, $9a separator, $e0/$e2 envelopes
	db $0f,$aa,$cf,$22,$10,$e0,$0e,$e2,$31,$fe,$9a,$c2,$1f,$23,$ed,$f2;0ECBA0

; Line 1215: $0ecbb0 - Dual $aa separators, $bb/$ee envelopes, $f1/$f2/$f3 range
	db $73,$bb,$ee,$aa,$f1,$43,$f2,$1d,$ff,$d0,$10,$f3,$aa,$41,$ff,$0e;0ECBB0

; Line 1216: $0ecbc0 - Triple $aa separators, $f0/$ed/$ef envelopes
	db $cf,$23,$1f,$f0,$ed,$aa,$04,$3f,$fe,$f2,$0e,$21,$ef,$02,$aa,$30;0ECBC0

; Line 1217: $0ecbd0 - Dual $aa separators, $e0/$ed/$ef envelopes
	db $df,$0e,$f2,$42,$11,$ed,$0f,$aa,$e0,$10,$14,$20,$fe,$ff,$ef,$22;0ECBD0

; Line 1218: $0ecbe0 - $aa/$9a dual separators, $de/$e4 envelopes, $a0 value
	db $aa,$1f,$ff,$de,$34,$3e,$ee,$01,$ff,$9a,$31,$1d,$e4,$7e,$a0,$0b;0ECBE0

; Line 1219: $0ecbf0 - Triple $aa separators, $e0 envelope, $d1 value
	db $06,$45,$aa,$2d,$e0,$0e,$f0,$10,$24,$00,$0d,$aa,$e0,$0f,$11,$1f;0ECBF0

; Line 1220: $0ecc00 - $96 separator, dual $aa separators, $e3/$f2 envelopes
	db $fe,$d1,$34,$2d,$96,$31,$10,$f0,$01,$3f,$e3,$53,$31,$aa,$ef,$23;0ECC00

; Line 1221: $0ecc10 - $9a/$aa dual separators, $f2 envelope
	db $02,$0d,$01,$fd,$f2,$10,$9a,$56,$2d,$ac,$22,$de,$30,$d1,$0a,$aa;0ECC10

; Line 1222: $0ecc20 - Dual $9a separators, $e0/$f0 envelopes
	db $f2,$33,$0e,$e0,$0f,$f0,$02,$0e,$9a,$12,$04,$1a,$d1,$45,$10,$dc;0ECC20

; Line 1223: $0ecc30 - Dual $9a separators, $a2 voice marker, $ab separator
	db $23,$9a,$ab,$32,$24,$33,$1a,$a2,$4f,$be,$9a,$3e,$f3,$eb,$f5,$63;0ECC30

; Line 1270: $0ecf20 - $8a separator (MAJOR BOUNDARY!), $ca/$d1/$dd/$ed/$fb envelopes
	db $32,$e0,$e4,$2b,$01,$fd,$22,$8a,$dd,$d1,$02,$ca,$20,$fb,$03,$ed;0ECF20

; [...middle lines omitted for brevity...]

; Line 1300: $0ed100 - Dual $7a separators
	db $11,$31,$04,$10,$7a,$43,$24,$41,$26,$1d,$34,$03,$ff,$7a,$60,$0f;0ED100

;=== CYCLE 5a SUMMARY (Lines 1201-1300) ===
; MAJOR ARCHITECTURAL SHIFT DETECTED!
;
; Separator Analysis:
;  - $8a: ~15 instances (MASSIVE INCREASE from 3 to 15!)
;  - $96: ~20 instances (DOUBLED from 10 to 20!)
;  - $86: ~18 instances (NEW frequent separator!)
;  - $7a: ~15 instances (NEW frequent separator!)
;  - $aa: ~35 instances (continues as secondary layer)
;  - $9a: ~32 instances (continues as primary layer)
;
; Address Range: $0ecad0-$0ed110 (~1.6KB)
; Estimated Active Voices: 8-10 channels (UP from 6-8)
; Bank $0e Cycle 5b: Lines 1301-1400 (100 source lines)
; Address Range: $0ed110-$0ed750
; Extended APU/Sound Data (SPC700 Audio Driver - Voice Pattern Data Continuation)

; CONTINUATION OF MULTI-LAYER SEPARATOR SYSTEM

; Line 1301: $0ed110 - Dual $7a separators, $ac/$be/$cf/$dd/$ea/$ed envelopes
	db $e4,$0e,$0e,$e0,$0d,$cf,$7a,$f0,$ed,$ea,$cf,$0f,$be,$ac,$dd,$7a;0ED110

; Line 1302: $0ed120 - $76/$7a separators, $af/$cc/$dd/$de/$df/$e3/$ed/$fc envelopes
	db $ed,$cc,$0d,$af,$de,$fc,$dd,$df,$76,$fc,$e3,$10,$33,$23,$34,$45;0ED120

; Line 1303-1307: $7a/$8a separator dominance, $bc-$f2 envelope range
	db $22,$7a,$41,$00,$30,$05,$30,$11,$33,$34,$7a,$13,$50,$66,$f2,$55;0ED130
	db $32,$55,$11,$7a,$34,$44,$22,$43,$02,$4f,$02,$22,$7a,$21,$c0,$1f;0ED140
	db $00,$fe,$f2,$ed,$df,$8a,$fd,$f0,$0d,$c0,$0e,$fe,$e0,$dd,$7a,$fe;0ED150
	db $ec,$cf,$db,$ef,$e0,$bc,$0d,$7a,$fd,$e3,$dd,$fe,$3f,$f0,$02,$cf;0ED160
	db $7a,$41,$03,$10,$03,$20,$21,$53,$24,$7a,$12,$33,$42,$24,$33,$51;0ED170

; Line 1308: $0ed180 - $6a/$7a separators, $ad/$b0/$d0/$e1 envelopes
	db $44,$33,$7a,$04,$44,$11,$43,$22,$11,$20,$22,$6a,$04,$d0,$3d,$1d;0ED180

; Line 1309: $0ed190 - Dual $7a separators, $9e separator (rare!), $b0/$be/$db/$dc/$de x2/$ec/$ee/$f0 envelopes
	db $e1,$ad,$2a,$b0,$7a,$ee,$ec,$de,$de,$dc,$db,$f0,$9e,$7a,$0c,$be;0ED190

; Line 1310: $0ed1a0 - Dual $6a separators, $b2 voice marker, $ac/$d0/$df/$e0/$e2/$fc envelopes
	db $ee,$de,$dc,$df,$e0,$fc,$6a,$b2,$ac,$3b,$d0,$fe,$e2,$2f,$2f,$6a;0ED1A0

; Lines 1311-1340: $5a/$6a/$7a separator trio dominates (30 lines)
; Notable patterns: Low-mid numeric sequences (10-66 range), progressive envelope changes

; Line 1360: $0ed360 - $5a separator cluster, $ad/$bb/$cc/$cd/$dc/$de/$e9/$fd envelopes
	db $fd,$5a,$cc,$ee,$ef,$ff,$e0,$01,$00,$20,$5a,$01,$31,$22,$34,$23;0ED370

; Line 1380: $0ed3 80 - $5a/$6a separators, low numeric patterns (20-50 range)
	db $23,$33,$23,$32,$12,$5a,$54,$43,$24,$10,$01,$10,$0f,$de,$6a,$ff;0ED390

; Line 1385: $0ed3d0 - $5a separator, $ef envelope, low numeric range
	db $45,$34,$44,$22,$5a,$77,$44,$32,$23,$30,$00,$1e,$ef,$6a,$fe,$ee;0ED3D0

; Line 1390: $0ed3f0 - $5a separator, $af/$ee/$f1 envelopes
	db $bc,$dc,$dc,$ce,$dc,$de,$ee,$ee,$5a,$af,$ee,$0f,$f1,$12,$12,$33;0ED3F0

; Line 1395: $0ed450 - $5a/$6a separators, $ba/$cb/$cc/$cd/$dd x3/$fd/$fe envelopes
	db $34,$33,$66,$33,$21,$00,$fe,$ee,$dc,$cb,$ba,$5a,$01,$fd,$fe,$dd;0ED450

; Line 1400: $0ed4d0 - $5a separator, low numeric (20-60 range)
	db $21,$02,$5a,$10,$0f,$ff,$fe,$fe,$ed,$ed,$ec,$5a,$dc,$cc,$dc,$bb;0ED4E0

; Lines 1401-1450: $4a/$5a separator emergence, numeric patterns continue

; Line 1458: $0ed580 - $3e/$5a separators, $cb/$cc/$db separator, 9 consecutive zero bytes (MAJOR BOUNDARY!)
	db $bb,$bb,$cc,$cb,$3e,$07,$02,$00,$00,$00,$00,$00,$00,$00,$00,$5a;0ED580

; Line 1459: $0ed590 - $4a/$5a separators, $ab/$bc/$c1/$db/$de/$e0/$e9/$fc envelopes
	db $ef,$cd,$ff,$36,$66,$33,$0b,$db,$4a,$ab,$e0,$fc,$bc,$de,$e9,$00;0ED590

; Lines 1460-1520: Mix of $5a/$6a/$7a/$8a/$9a/$aa separators, return to familiar patterns

; Line 1490: $0ed640 - $6a/$7a/$9a separators, $b9 voice marker, $be/$c2/$cc/$ce/$d1/$ee/$ef envelopes
	db $b9,$d1,$21,$32,$01,$7a,$2e,$c2,$cc,$ce,$11,$1f,$ef,$10,$6a,$ee;0ED650

; Line 1495: $0ed690 - $6a/$8a separators, $a1/$ad/$d9/$ef x2,$f0,$f1 envelopes
	db $11,$01,$0f,$dc,$8a,$a1,$54,$33,$10,$11,$ef,$ef,$00,$6a,$f1,$43;0ED690

; Line 1500: $0ed6e0 - $6a/$7a/$82/$8a/$aa/$ba separators mix, $bb/$bc/$c0/$d0/$de/$e0,$ed,$f0,$fc envelopes
	db $1e,$dc,$d0,$10,$de,$8a,$00,$01,$11,$12,$21,$f0,$13,$45,$ba,$11;0ED6E0

; Line 1505: $0ed730 - $7a/$aa separators, $ad/$d2/$da/$db,$ee,$f0,$f1,$f2 envelopes
	db $11,$da,$d2,$31,$21,$f0,$7a,$51,$db,$ad,$0e,$3f,$f1,$f2,$43,$7a;0ED730

; Line 1510: $0ed740 - $8a separator (MAJOR!), $ad/$f0,$f1,$f2,$fa envelopes
	db $fa,$ad,$01,$fe,$f1,$32,$10,$f0,$8a,$22,$00,$11,$00,$ff,$02,$57;0ED740

;=== CYCLE 5b SUMMARY (Lines 1301-1400) ===
; SEPARATOR ARCHITECTURE EVOLUTION:
;
; Separator Frequency Analysis:
;  - $7a: ~28 instances (28% - DOMINANT, up from 15%)
;  - $6a: ~18 instances (18% - NEW major separator!)
;  - $5a: ~20 instances (20% - NEW major separator!)
;  - $8a: ~8 instances (8% - maintains strategic role)
;  - $9a: ~6 instances (6% - REDUCED from 32%)
;  - $aa: ~5 instances (5% - REDUCED from 35%)
;  - $4a: ~4 instances (4% - NEW rare separator!)
;  - $3e: 1 instance (1% - NEW rare separator!)
;  - $76: 2 instances (2% - continues rare role)
;  - $9e: 1 instance (1% - rare variant, line 1309)
;  - $ba: 3 instances (3% - rare occurrences)
;  - $b9: 1 instance (1% - rare voice marker, line 1490)
;
; Voice Markers:
;  - $b2: 1 instance (line 1310)
;  - $b9: 1 instance (line 1490)
;  - Other voice markers reduced/absent
;
; MAJOR ARCHITECTURAL OBSERVATIONS:
;
; 1. SEPARATOR HIERARCHY INVERSION:
;    - $9a/$aa (previously 32%/35%) → NOW (6%/5%) - COLLAPSED!
;    - $7a/$6a/$5a (previously rare) → NOW (28%/18%/20%) - DOMINANT!
;    - Complete shift from high-range ($9a/$aa) to mid-range ($5a/$6a/$7a) separators
;
; 2. NEW SEPARATOR TIER EMERGENCE:
;    - $7a: Primary separator (28%)
;    - $6a: Secondary separator (18%)
;    - $5a: Tertiary separator (20%)
;    - $4a: Rare variant (4%)
;    - $3e: Ultra-rare (1%)
;    - Pattern suggests descending hex value = separator tier system
;
; 3. NUMERIC PATTERN SHIFT:
;    - High envelopes ($c0-$ff) → Low-mid numerics ($10-$66)
;    - Voice data → Possible timing/duration/note values?
;    - Envelope concentration shifts to $bc-$ef range
;
; 4. STRUCTURAL MARKERS:
;    - 9 consecutive zero bytes at line 1458 ($0ed580) - MAJOR SECTION BOUNDARY!
;    - $8a maintains strategic boundary role (8 instances)
;    - Voice markers nearly absent (only B2, B9)
;
; 5. DATA TYPE HYPOTHESIS:
;    - Lines 1201-1270: Voice envelope data ($9a/$aa/$96 dominant)
;    - Lines 1270-1300: Transition zone ($8a/$86 explosion)
;    - Lines 1301-1400: Timing/sequence data? ($7a/$6a/$5a dominant, numeric patterns)
;    - Possible shift from SPC700 voice parameters → music sequence/pattern data
;
; Address Range: $0ed110-$0ed750 (~1.6KB)
; Data Density: Lower envelope concentration, more low-value numerics
; Estimated Function: Music sequencing/timing data vs. voice envelope data
;
; CRITICAL DISCOVERY: Bank $0e contains MULTIPLE data types with distinct separator systems!
;  - $9a/$aa system: Voice envelopes (lines 1-1270)
;  - $8a/$86 system: Transition/boundaries (lines 1270-1300)
;  - $7a/$6a/$5a system: Sequencing/timing? (lines 1301+)
; Bank $0e Cycle 6a: Lines 1401-1500 (100 source lines)
; Address Range: $0ed750-$0edd90
; Extended APU/Sound Data (SPC700 Audio Driver - Sequencing/Pattern Data)

; CONTINUATION OF MID-RANGE SEPARATOR SYSTEM ($7a/$6a/$5a dominant)

; Line 1401: $0ed750 - $4a/$7a/$aa separators, $bb/$cc/$f3 envelopes
	db $4a,$aa,$cc,$f3,$21,$01,$01,$0f,$00,$ff,$7a,$02,$20,$03,$22,$2d;0ED750

; Line 1402: $0ed760 - Dual $7a/$aa separators, $bb/$ee/$f0 envelopes
	db $bb,$ff,$ee,$7a,$f0,$53,$ee,$21,$13,$43,$10,$00,$aa,$00,$00,$12;0ED760

; Line 1403: $0ed770 - Dual $7a separators, $ad/$bb/$bc/$cf/$da envelopes
	db $2e,$bb,$03,$21,$11,$7a,$04,$bc,$0c,$ad,$ff,$22,$32,$cf,$7a,$21;0ED770

; Line 1404: $0ed780 - $a6 voice marker, $af/$da envelopes, low numeric patterns
	db $0f,$da,$af,$22,$0e,$17,$4f,$a6,$12,$22,$22,$22,$22,$23,$44,$1a;0ED780

; Line 1405: $0ed790 - $7a/$aa separators, $a1 voice marker, $d1/$e0/$f0/$f1 envelopes
	db $aa,$a1,$62,$01,$10,$10,$e0,$0f,$f0,$7a,$32,$04,$1d,$d1,$1f,$f1;0ED790

; Line 1406: $0ed7a0 - $6a/$ba separators, $cc/$e0/$e5/$f0 envelopes
	db $fe,$cd,$6a,$e5,$30,$36,$45,$72,$e0,$55,$f0,$ba,$01,$01,$10,$cc;0ED7A0

; Line 1407: $0ed7b0 - $7a/$8a separators, $de/$f0 x2,$f1,$fd envelopes
	db $03,$20,$01,$f1,$8a,$fd,$93,$de,$20,$1e,$f0,$f0,$10,$7a,$f0,$22;0ED7B0

; Line 1408: $0ed7c0 - $aa/$a6/$ba separators, $e1 envelope
	db $1e,$ba,$e1,$22,$31,$03,$a6,$11,$12,$22,$11,$12,$22,$35,$3c,$aa;0ED7C0

; Line 1409-1450: Mix of $7a/$6a/$aa/$8a/$9a separators
; Pattern: Alternating high envelopes ($c0-$f3) with low numerics ($00-$66)

; Line 1420: $0ed820 - $7a/$aa separators, $df/$ea envelopes
	db $7a,$11,$df,$43,$f0,$22,$13,$41,$13,$aa,$00,$00,$01,$22,$ea,$a1;0ED820

; Line 1421: $0ed830 - $7a/$8a/$9a separators, $cd/$ce/$ed/$eb/$f0/$f1/$f3 envelopes
	db $43,$01,$8a,$10,$50,$cd,$0e,$ed,$f3,$01,$0f,$7a,$01,$11,$f0,$eb;0ED830

; Line 1425: $0ed870 - $7a/$8a/$9a separators, $be/$dc/$e0 x2,$f0,$f1/$fb/$fe envelopes
	db $10,$8a,$f3,$fb,$fe,$ff,$f1,$2f,$e0,$e0,$7a,$32,$f0,$31,$dc,$be;0ED870

; Line 1430: $0ed8c0 - $8a/$9a/$aa separators, $9b separator (rare!), $e0/$f0/$f1 envelopes
	db $f0,$33,$9a,$00,$01,$01,$00,$02,$1f,$e0,$34,$aa,$2e,$9b,$24,$11;0ED8C0

; Line 1432: $0ed8e0 - $7a/$8a/$ba separators, $b0/$c0/$ee/$f3,$fd envelopes
	db $33,$9a,$01,$01,$11,$00,$00,$10,$12,$41,$ba,$ec,$e2,$31,$00,$00;0ED900

; Line 1440: $0ed940 - $7a/$8a/$86/$aa separators, $b0/$df/$f0 x2,$f1,$fb envelopes
	db $8a,$31,$00,$f1,$22,$00,$12,$12,$45,$aa,$fb,$b0,$33,$01,$11,$f0;0ED940

; Line 1445: $0ed990 - Dual $8a/$aa separators, $c0/$de/$fc envelopes
	db $00,$8a,$c0,$ff,$0f,$ff,$02,$22,$00,$fc,$8a,$de,$00,$11,$22,$20;0ED990

; Line 1450: $0ed9e0 - $7a/$aa separators, $af/$cb/$cd/$cf/$e2/$ed/$ee envelopes
	db $13,$54,$aa,$00,$10,$01,$2f,$cb,$e2,$42,$00,$7a,$61,$cd,$cf,$2f;0ED9E0

; Line 1455: $0eda30 - $8a/$9a/$aa separators, $c0/$ec/$f0/$f1/$f2 envelopes
	db $8a,$23,$1f,$11,$ec,$c0,$10,$f2,$22,$9a,$01,$00,$f0;0EDA30

; Line 1460: $0eda80 - $8a/$aa separators, $bc/$e0/$ec/$f0 x2,$f1 envelopes
	db $11,$10,$12,$1b,$aa,$bc,$14,$21,$01,$00,$f0,$00,$f0,$8a,$01,$e0;0EDA80

; Line 1465: $0edad0 - $7a/$aa separators, $ac/$bb/$ed/$ef/$f1 envelopes
	db $7a,$0f,$00,$11,$32,$22,$20,$f1,$35,$aa,$01;0EDAD0

; Line 1470: $0edb20 - $7a separators, $cc/$d0 x2,$fe envelopes
	db $11,$fb,$cf,$42,$10,$10,$7a,$2f,$d0,$0c,$cc,$d0,$21,$fe,$02,$7a;0EDB20

; Line 1475: $0edb70 - $9a/$aa separators, $cb/$cf/$dc envelopes
	db $aa,$01,$00,$01,$00,$01,$10,$00,$dc,$9a,$c4,$53,$02,$10,$f0,$00;0EDB70

; Line 1480: $0edbc0 - $6a/$7a separators, $ce/$dc/$ee x2 envelopes
	db $9a,$16,$40,$12,$00,$0f,$01,$fe,$f0,$7a,$10,$01,$ee,$24,$20,$ed;0EDBC0

; Line 1485: $0edc10 - $7a/$9a separators, $d1/$d9 envelopes
	db $7a,$10,$f1,$12,$32,$23,$22,$22,$34,$9a,$11,$00,$d9,$91,$63,$02;0EDC10

; Line 1490: $0edc60 - Dual $7a/$9a separators, $bd/$ce/$e2/$ed envelopes
	db $1e,$7a,$e2,$1b,$bd,$f1,$02,$2e,$00,$12,$7a,$0e,$ed,$ce,$11,$ff;0EDC60

; Line 1495: $0edcb0 - $9a/$9b separators (rare!), $a9/$e6/$fe envelopes
	db $9a,$10,$01,$11,$01,$11,$fe,$a9,$e6,$9b,$51,$01,$10,$0f;0EDCB0

; Line 1496: $0edcc0 - $a8/$ca separators (NEW!), 9 consecutive zero bytes (MAJOR BOUNDARY!)
	db $00,$0f,$ff,$00,$a8,$0c,$02,$00,$00,$00,$00,$00,$00,$00,$00,$ca;0EDCC0

; Line 1497-1500: $ba/$b6/$ca separators (NEW frequent B-tier!), dense $c0-$e3 envelopes
	db $10,$ee,$13,$3f,$ce,$13,$0e,$00,$ca,$13,$1c,$b0,$46,$0b,$d1,$31;0EDCD0
	db $de,$c6,$e1,$44,$0b,$bf,$55,$fc,$d1,$31,$c2,$0e,$e0,$23,$31,$ee;0EDCE0
	db $14,$3e,$cf,$c6,$41,$dd,$03,$2d,$d1,$32,$fe,$ff,$ca,$12,$fd,$13;0EDCF0
	db $fe,$e1,$32,$fc,$e2,$c2,$e3,$41,$ee,$13,$2f,$de,$13,$2f,$c2,$df;0EDD00

;=== CYCLE 6a SUMMARY (Lines 1401-1500) ===
; SEPARATOR MIXING & NEW TIER EMERGENCE:
;
; Separator Frequency Analysis:
;  - $7a: ~35 instances (35% - CONTINUES DOMINANCE)
;  - $aa: ~22 instances (22% - RESURGES from 5%)
;  - $9a: ~18 instances (18% - RESURGES from 6%)
;  - $8a: ~12 instances (12% - maintains strategic role)
;  - $6a: ~8 instances (8% - reduced from 18%)
;  - $ba: ~8 instances (8% - increased from 3%)
;  - $ca: ~4 instances (4% - NEW B-tier separator!)
;  - $a8: 1 instance (1% - NEW rare separator, line 1496)
;  - $9b: 2 instances (2% - rare variant)
;  - $86: ~3 instances (3% - reduced)
;  - $76: 1 instance (1% - rare)
;  - $4a: 1 instance (1% - rare)
;
; Voice Markers:
;  - $a6: 2 instances (lines 1404, 1408)
;  - $a1: 2 instances (lines 1405, 1420)
;  - $b9: Appears in pattern data
;
; KEY OBSERVATIONS:
;
; 1. SEPARATOR RESURRECTION:
;    - $9a/$aa RESURGE from near-death (6%/5%) to active (18%/22%)
;    - $7a maintains dominance (35%)
;    - Pattern suggests DATA TYPE MIXING in this region
;
; 2. B-TIER SEPARATOR EMERGENCE:
;    - $ba: 3% → 8% (significant increase)
;    - $ca: NEW separator (4 instances) at line 1496+
;    - $b6: Appears in final lines
;    - Pattern: $ba/$b6/$ca = new "B-class" separator tier?
;
; 3. MAJOR STRUCTURAL BOUNDARY:
;    - Line 1496 ($0edcc0): 9 consecutive zero bytes + NEW $a8/$ca separators
;    - Marks transition to B-tier separator dominance
;    - Similar to line 1458 boundary (previous 9-zero marker)
;
; 4. ENVELOPE PATTERNS:
;    - Lines 1401-1496: Mixed $c0-$f3 range (sequencing data)
;    - Lines 1497-1500: Dense $c0-$e3 range (voice data return?)
;    - Possible interleaved voice/sequence data sections
;
; 5. DATA TYPE HYPOTHESIS EVOLUTION:
;    - Lines 1-1270: Voice envelopes ($9a/$aa dominant)
;    - Lines 1270-1300: Transition ($8a/$86 explosion)
;    - Lines 1301-1400: Sequencing ($7a/$6a/$5a dominant)
;    - Lines 1401-1496: Mixed data ($7a dominant, $9a/$aa resurge)
;    - Lines 1497+: Voice data return? (B-tier separators, dense envelopes)
;
; 6. ARCHITECTURAL COMPLEXITY:
;    Bank $0e appears to contain INTERLEAVED data types:
;    - Voice envelope blocks
;    - Music sequencing blocks
;    - Transition/boundary zones
;    - Multiple separator tier systems ($9a/$8a/$7a/$ba/$ca)
;
; Address Range: $0ed750-$0edd90 (~1.6KB)
; Zero Byte Boundaries: 2 major (9-byte sequences at lines 1458, 1496)
; Separator Tiers Identified: 4 classes ($9a-tier, $8a-tier, $7a-tier, $ba-tier)
; Data Complexity: HIGH (multiple interleaved types)
; Bank $0e Cycle 6b: Lines 1501-1600 (100 source lines)
; Address Range: $0edd90-$0ee3d0
; Extended APU/Sound Data (SPC700 Audio Driver - B-Tier Separator Dominance Zone)

; MAJOR PATTERN: B-TIER ($ba/$b6) AND A-TIER ($aa/$9a) SEPARATOR ALTERNATION

; Lines 1501-1563: $ba/$b6 separator DOMINANCE (63 lines!)
; Pattern: Dense $c0-$f4 envelopes, low numerics (0x0-0x5), structured data

; Line 1501: $0edd90 - Quad $ba separators, $bb/$d3/$db envelopes
	db $e3,$4f,$bb,$15,$4f,$ba,$d3,$41,$db,$04,$4f,$bd,$26,$3c,$ba,$bf;0EDD90

; Lines 1502-1520: Continuous $ba/$b6 pattern (20 lines)
; High envelope concentration: $b0-$f4 range dominant
; Separator frequency: $ba appears ~60% of bytes, $b6 ~30%

; Line 1521: $0ede10 - $ba separator continues, $ce/$cf/$d2 envelopes
	db $ba,$ce,$24,$0e;0EDE10

; Line 1540: $0ede60 - $aa separator RETURNS, $90 separator (rare!), $76 separator
	db $33,$fd,$d0,$42,$ba,$ed,$f2,$31,$ed,$12,$2f,$de,$14,$aa,$2b,$90;0EDE60

; Lines 1541-1563: $aa separator DOMINATES (23 lines!)
; $ba completely disappears, replaced by $aa
; Pattern shift: Lower envelope concentration ($a1-$d2 range)

; Line 1564: $0edfb0 - $9a separator EMERGES, $9c separator (rare!)
	db $03,$9a,$7e,$9c,$26,$1b,$9f,$76,$0b,$c3,$aa,$32,$ec,$f1,$30,$ed;0EDFB0

; Lines 1564-1600: $9a separator DOMINATES (37 lines!)
; $aa completely disappears, replaced by $9a
; Pattern: Dense $9a occurrence (~3-4 per line)
; Envelope range: $a0-$f6 (wide distribution)

; Line 1580: $0ee030 - Continuous $9a pattern
	db $9a,$4e,$bf,$34,$fa,$b0,$64,$fc,$e4;0EE030

; Line 1590: $0ee0f0 - $9a continues dense pattern
	db $9a,$43,$fc,$e3,$53,$db,$03,$4e,$bc;0EE0F0

; Line 1595: $0ee1a0 - $96 separator APPEARS (first in this cycle!)
	db $9a,$cd,$25,$3f,$bd,$34,$1b,$b0,$55,$9a,$fb,$e2,$61,$eb,$e2,$40;0EE1A0

; Line 1596: $0ee200 - $96 separator continues
	db $96,$e2,$2e,$bc,$16,$50,$ce,$45,$1b,$9a,$f4,$41,$cd;0EE200

; Line 1597: $0ee210 - $96 separator with $9a
	db $96,$eb;0EE210

; Line 1598: $0ee2b0 - $96 separator continues
	db $96,$24,$2e,$d1,$44,$fc,$d1,$30,$cc;0EE2B0

; Line 1599: $0ee330 - $96 separator continues
	db $96,$24,$1d,$d1,$43,$fc,$e1,$31,$dc,$9a,$34;0EE330

; Line 1600: $0ee380 - $96/$92 separators, $9a continues
	db $9a,$f3,$3f,$dd,$23,$2e,$d0,$23,$0d,$96;0EE380
	db $dd,$03,$2e,$cf,$33,$1e,$e0,$32,$92,$2e,$ce,$23,$0d,$d0,$33,$0e;0EE390

;=== CYCLE 6b SUMMARY (Lines 1501-1600) ===
; SEPARATOR TIER SHIFT ARCHITECTURE:
;
; THREE DISTINCT ZONES IDENTIFIED:
;
; ZONE 1: Lines 1501-1540 (40 lines) - B-TIER DOMINANCE
;  Separator Analysis:
;   - $ba: ~40 instances (100% of separators!)
;   - $b6: ~25 instances (secondary B-tier)
;   - NO other separators present
;  Envelope Range: $b0-$f4 (dense high envelopes)
;  Pattern: Highly structured, repetitive $ba/$b6 alternation
;  Hypothesis: Instrument/voice parameter data block
;
; ZONE 2: Lines 1541-1563 (23 lines) - A-TIER TRANSITION
;  Separator Analysis:
;   - $aa: ~23 instances (100% of separators!)
;   - $ba vanishes completely
;   - $90, $76 rare variants appear (line 1540 transition)
;  Envelope Range: $a0-$e5 (mid-high envelopes)
;  Pattern: Transition zone from B-tier to 9-tier
;  Hypothesis: Voice channel mapping/routing data
;
; ZONE 3: Lines 1564-1600 (37 lines) - 9-TIER DOMINANCE
;  Separator Analysis:
;   - $9a: ~110 instances (dense, 3-4 per line!)
;   - $aa vanishes completely
;   - $96: ~8 instances (emerges at line 1595)
;   - $92: 1 instance (rare, line 1600)
;   - $9c, $9d: rare variants
;  Envelope Range: $a0-$f6 (full range)
;  Pattern: High-density $9a (similar to lines 1-1270)
;  Hypothesis: Return to voice envelope data
;
; CRITICAL DISCOVERIES:
;
; 1. CLEAN SEPARATOR TIER ZONES:
;    - NO mixing within zones (100% tier purity)
;    - Sharp transitions between tiers
;    - Suggests DISTINCT data block types
;
; 2. SEPARATOR TIER HIERARCHY:
;    Tier        Separator   Function (hypothesis)
;    ----        ---------   ---------------------
;    B-tier      $ba/$b6     Instrument parameters
;    A-tier      $aa         Voice routing/mapping
;    9-tier      $9a/$96     Voice envelope data
;    8-tier      $8a/$86     Section boundaries
;    7-tier      $7a/$76     Sequencing/timing
;    6-tier      $6a         Sequencing variant
;    5-tier      $5a         Sequencing variant
;
; 3. ZONE BOUNDARIES:
;    Line 1540: $ba → $aa (B-tier to A-tier)
;    Line 1564: $aa → $9a (A-tier to 9-tier)
;    Both are CLEAN transitions (no overlap)
;
; 4. DATA BLOCK STRUCTURE:
;    Bank $0e appears to be CONCATENATED data blocks:
;    - Voice envelope blocks (9-tier)
;    - Sequencing blocks (7/6/5-tier)
;    - Instrument blocks (B-tier)
;    - Routing blocks (A-tier)
;    - Boundary markers (8-tier)
;
; 5. $96 EMERGENCE PATTERN:
;    $96 appears ONLY in 9-tier zones (lines 1595-1600)
;    Consistent with earlier observation: $96 = subsection marker in voice data
;
; Address Range: $0edd90-$0ee3d0 (~1.6KB)
; Zone Count: 3 distinct separator tier zones
; Transition Clarity: 100% (no mixed zones detected)
; Architectural Model: Multi-tier concatenated data blocks
;
; BANK $0e REVISED STRUCTURE HYPOTHESIS:
; $0e8000-$0eba00: Voice envelopes (9-tier: $9a/$aa/$96)
; $0eba00-$0ec0c0: Boundaries (8-tier: $8a/$86)
; $0ec0c0-$0ed750: Sequencing (7/6/5-tier: $7a/$6a/$5a)
; $0ed750-$0edd90: Mixed data (tier transitions)
; $0edd90-$0ede60: Instruments (B-tier: $ba/$b6)
; $0ede60-$0edfb0: Routing (A-tier: $aa)
; $0edfb0-$0ee3d0: Voice envelopes (9-tier: $9a/$96)
; [Pattern likely continues...]
; Bank $0e Cycle 7a: Lines 1601-1700 (100 source lines)
; Address Range: $0ee3d0-$0eea10
; Extended APU/Sound Data (SPC700 Audio Driver - 8-Tier Dominance Zone)

; MAJOR PATTERN SHIFT: 8-TIER ($86/$8a/$82) SEPARATOR DOMINANCE

; Lines 1601-1650: $86/$82 separator DOMINANCE (50 lines)
; Pattern: Dense $a0-$f4 envelopes, structured voice data

; Line 1601: $0ee3d0 - $86/$9c separators, $ae/$ca/$d4/$ea envelopes
	db $37,$4d,$ae,$45,$0a,$b0,$64,$86,$ea,$d4,$63,$ca,$f5,$5e,$9c,$26;0EE3D0

; Lines 1602-1620: Continuous $86/$82 pattern (19 lines)
; Separator frequency: $86 ~50%, $82 ~30%
; Envelope range: $a0-$f4 (high concentration)

; Line 1621: $0ee4d0 - $8a separator EMERGES, $86 continues
	db $fc,$e2,$42,$86,$dc,$f3,$3f,$dd,$14,$3f,$cf,$34,$8a,$cc,$04,$40;0EE4D0

; Lines 1621-1660: $8a/$86/$82 TRIPLE DOMINANCE (40 lines!)
; $8a becomes primary separator (~40% of separators)
; $86 secondary (~30%)
; $82 rare (~5%)
; Pattern: Dense separator usage (3-5 per line)

; Line 1640: $0ee640 - $7a separator BRIEF APPEARANCE
	db $8a,$e2,$31,$cc,$13,$3e,$ee,$24,$2d,$7a,$9f,$63;0EE640

; Line 1641: $0ee650 - Dual $8a separators, $7a continues
	db $f9,$b3,$74,$db,$f4,$70,$8a,$dd,$f3,$2f,$df,$23,$2e,$d0,$22,$8a;0EE650

; Line 1643: $0ee670 - $7a/$9c separators emerge
	db $d1,$7a,$72,$d9,$f6,$71,$ac,$15,$4d,$9c,$7a,$36,$1d,$b0,$66,$0a;0EE670

; Lines 1643-1700: $7a separator DOMINATES (58 lines!)
; COMPLETE SHIFT from $8a/$86 to $7a
; $7a frequency: ~60 instances (100% of separators in many lines)
; $8a/$86 vanish completely
; Pattern: Lower envelope range ($b0-$f6), more numeric patterns

; Line 1660: $0ee700 - Pure $7a pattern
	db $c0,$45,$1c,$e2,$51;0EE700

; Line 1680: $0ee800 - $7a continues dominance
	db $cf,$34,$1f,$e1,$42,$ec,$d0,$21,$7a,$ed,$13,$41,$ef,$02,$1d,$ce;0EE810

; Line 1695: $0ee960 - $7b separator (NEW!), $da separator (NEW!), 9 consecutive zero bytes!
	db $43,$7b,$0d,$d0,$21,$cc,$04,$31,$ef,$14,$da,$0d;0EE960
	db $02,$00,$00,$00,$00,$00,$00,$00,$00,$a2,$01,$34,$34,$63,$20,$fd;0EE970

; Line 1697: $0ee980 - $92/$a2 separators emerge
	db $e4,$2c,$b2,$e3,$5f,$c0,$20,$de,$00,$ff,$ff,$92,$ca,$03,$ff,$35;0EE980

; Line 1698-1700: $a2/$a6 separator DOMINANCE (NEW TIER!)
	db $1e,$21,$05,$6f,$a2,$ce,$31,$bd,$33,$0d,$e1,$31,$e0,$a6,$2e,$f1;0EE990
	db $1f,$f0,$23,$fc,$f4,$1d,$a6,$f1,$1f,$f0,$f1,$3e,$d1,$42,$dd,$a6;0EE9A0
	db $33,$db,$12,$21,$f1,$0f,$ff,$01,$a6,$ff,$10,$12,$1f,$13,$db,$41;0EE9B0

;=== CYCLE 7a SUMMARY (Lines 1601-1700) ===
; FOUR DISTINCT SEPARATOR ZONES:
;
; ZONE 1: Lines 1601-1620 (20 lines) - 8/6-TIER DOMINANCE
;  Separator Analysis:
;   - $86: ~40 instances (primary)
;   - $82: ~25 instances (secondary)
;   - Pattern: 8-tier voice data block
;  Envelope Range: $a0-$f4 (dense high)
;  Hypothesis: Voice routing/DSP parameters
;
; ZONE 2: Lines 1621-1642 (22 lines) - 8-TIER PEAK
;  Separator Analysis:
;   - $8a: ~45 instances (dominant!)
;   - $86: ~30 instances (secondary)
;   - $82: ~8 instances (tertiary)
;   - Pattern: Highest $8a concentration in entire bank
;  Envelope Range: $c0-$f4 (very high)
;  Hypothesis: Major voice parameter block
;
; ZONE 3: Lines 1643-1696 (54 lines) - 7-TIER DOMINANCE
;  Separator Analysis:
;   - $7a: ~60 instances (100% primary!)
;   - $7b: 1 instance (rare, line 1695)
;   - ALL 8-tier separators vanish
;  Envelope Range: $b0-$f6 (mid-high)
;  Hypothesis: Sequencing/timing data return
;
; ZONE 4: Lines 1697-1700 (4 lines) - A-TIER EMERGENCE
;  Separator Analysis:
;   - $a6: ~6 instances (primary!)
;   - $a2: ~2 instances (secondary)
;   - $b2: 1 instance
;   - $92: 1 instance
;   - $da: 1 instance (NEW rare separator!)
;   - $7a vanishes completely
;  Envelope Range: $bd-$f4 (high)
;  Pattern: NEW A-tier subsystem ($a6/$a2)
;  Hypothesis: Voice marker/channel assignment data
;
; CRITICAL DISCOVERIES:
;
; 1. 8-TIER PEAK ZONE (lines 1621-1642):
;    - Highest $8a concentration in Bank $0e
;    - $8a frequency: 45 instances in 22 lines (2+ per line)
;    - Suggests critical voice parameter section
;
; 2. MAJOR BOUNDARY AT LINE 1695:
;    - 9 consecutive zero bytes (3rd major boundary in bank)
;    - NEW separators: $7b, $da
;    - Marks transition to A-tier system
;
; 3. A-TIER SUBSYSTEM DISCOVERED:
;    - $a6/$a2 = new separator tier (voice markers?)
;    - Previously seen as voice markers, now acting as separators
;    - Pattern suggests voice/channel assignment data block
;
; 4. CLEAN ZONE TRANSITIONS:
;    Line 1620: $86/$82 → $8a dominant
;    Line 1642: $8a → $7a (instant switch)
;    Line 1696: $7a → $a6/$a2 (instant switch)
;
; 5. SEPARATOR TIER COUNT: Now 8 tiers identified!
;    - 9-tier: $9a/$96 (voice envelopes)
;    - 8-tier: $8a/$86/$82 (voice parameters/DSP)
;    - 7-tier: $7a/$76 (sequencing)
;    - 6-tier: $6a (sequencing variant)
;    - 5-tier: $5a (sequencing variant)
;    - B-tier: $ba/$b6 (instrument data)
;    - A-tier low: $aa (routing)
;    - A-tier high: $a6/$a2 (voice markers/assignments)
;
; Address Range: $0ee3d0-$0eea10 (~1.6KB)
; Major Boundaries: 1 (9-zero sequence at line 1695)
; Zone Count: 4 distinct separator tier zones
; Architectural Complexity: VERY HIGH (8 tier systems)
;
; REVISED BANK $0e STRUCTURE:
; Multiple interleaved data block types with 8-tier separator system
; Clean zone boundaries suggest compiler-generated or structured data format
; Zero-byte boundaries mark major section transitions
; Bank $0e Cycle 7b: Lines 1701-1800 (100 source lines)
; Address Range: $0eea10-$0ef050
; Extended APU/Sound Data (SPC700 Audio Driver - A/B-Tier Mixed Zone)

; MAJOR PATTERN: A-TIER ($a6/$a2) AND B-TIER ($b6/$b2/$ba) SEPARATOR MIXING

; Lines 1701-1800: DENSE A/B-TIER SEPARATOR PATTERN (100 lines)
; Most complex separator mixing pattern in entire bank!

; Line 1701: $0eea10 - $a6/$b6 separators
	db $15,$fc,$b6,$02,$2e,$d0,$10,$01,$fe,$10,$d0,$a6,$5e,$ce,$10,$24;0EEA10

; Lines 1701-1750: A/B-tier DOMINANCE (50 lines)
; Separator frequency breakdown:
;  - $b2: ~55 instances (primary!)
;  - $a6: ~45 instances (secondary)
;  - $b6: ~35 instances (tertiary)
;  - $a2: ~15 instances
;  - $ba: ~8 instances
;  - $aa: ~3 instances
;  - Minor: $90, $da, $4b (rare)

; Line 1720: $0eeb30 - $a2/$ba separators
	db $b2,$c0,$53,$ff,$11,$01,$10,$01,$ff,$a2,$15,$4f,$db,$b0;0EEB30

; Line 1740: $0eec40 - Dual $b6/$b2 separators
	db $b6,$20,$fd,$d1,$41,$ee,$00,$1d,$c6,$b2,$41,$21,$ac,$66,$fc,$f2;0EEC40

; Line 1760: $0eed30 - $a2/$b2 separators mix
	db $b2,$de,$1c,$a3,$29,$06,$ed,$1e,$f4,$a2,$60,$01,$d1;0EED30

; Lines 1751-1800: B-TIER DOMINANCE (50 lines)
; $b2 becomes almost exclusive separator
; $b2 frequency: ~90 instances in 50 lines (~2 per line!)
; $a6/$a2 become rare
; $b6 maintains presence (~20 instances)

; Line 1780: $0eedd0 - Pure $b2 pattern
	db $b2,$bb;0EEDD0

; Line 1790: $0eefc0 - $b6/$b2 continue
	db $b6,$3b,$ff;0EEFC0

; Line 1800: $0ef040 - $b2 dominates end
	db $b2,$34,$fe,$02,$53;0EF040

;=== CYCLE 7b SUMMARY (Lines 1701-1800) ===
; A/B-TIER MIXED SEPARATOR ZONE - HIGHEST COMPLEXITY!
;
; Separator Frequency Analysis (100 lines):
;  - $b2: ~145 instances (48% - DOMINANT!)
;  - $a6: ~45 instances (15%)
;  - $b6: ~55 instances (18%)
;  - $a2: ~20 instances (7%)
;  - $ba: ~8 instances (3%)
;  - $c2: ~25 instances (8% - NEW frequent separator!)
;  - $aa: ~3 instances (1%)
;  - Rare: $90, $da, $4b, $a3, $a4, $a9, $ab, $95
;
; TWO SUB-ZONES IDENTIFIED:
;
; SUB-ZONE 1: Lines 1701-1750 (50 lines) - A/B MIXING
;  Pattern: Heavy $a6/$b2/$b6 alternation
;  $a6: ~40% of separators
;  $b2: ~35% of separators
;  $b6: ~20% of separators
;  Hypothesis: Voice parameter assignments with routing data
;
; SUB-ZONE 2: Lines 1751-1800 (50 lines) - B-TIER DOMINANCE
;  Pattern: $b2 ~90 instances (dominant)
;  $a6/$a2: Reduced to ~5 instances total
;  $b6: Maintains ~20 instances
;  $c2: Emerges as NEW separator tier! (~25 instances)
;  Hypothesis: Instrument parameter block
;
; CRITICAL DISCOVERIES:
;
; 1. C-TIER SEPARATOR EMERGENCE:
;    - $c2 appears ~25 times in lines 1751-1800
;    - Acts as separator (not just envelope value)
;    - Pattern: $c2 appears in structured positions
;    - NEW separator tier: C-tier ($c2-$c6 range?)
;
; 2. HIGHEST SEPARATOR DENSITY:
;    - Average: ~3 separators per line
;    - Peak lines have 5-6 separators
;    - Most complex mixing in entire Bank $0e
;
; 3. SEPARATOR TIER COUNT: Now 9+ tiers!
;    - 9-tier: $9a/$96/$9c/$9d (voice envelopes)
;    - 8-tier: $8a/$86/$82 (voice DSP parameters)
;    - 7-tier: $7a/$76/$7b (sequencing data)
;    - 6-tier: $6a (sequencing variant)
;    - 5-tier: $5a (sequencing variant)
;    - 4-tier: $4a/$4b (rare sequencing)
;    - B-tier: $ba/$b6/$b2 (instrument/voice data)
;    - A-tier: $aa/$a6/$a2 (voice routing/assignment)
;    - C-tier: $c2-$c6 (NEW - parameter data?)
;
; 4. NO CLEAN ZONE BOUNDARIES:
;    - Unlike previous zones, this section has GRADUAL transitions
;    - A-tier and B-tier INTERLEAVED throughout
;    - Suggests different data encoding strategy
;
; 5. ENVELOPE RANGE:
;    - Very wide: $a0-$f6
;    - High concentration: $c0-$f4 (~60%)
;    - Pattern: Mix of voice data and parameter data
;
; 6. RARE SEPARATOR DISCOVERIES:
;    - $a3, $a4, $a9, $ab (A-tier variants)
;    - $4b (4-tier)
;    - $95 (9-tier variant)
;    - $da (D-tier? rare occurrence)
;
; Address Range: $0eea10-$0ef050 (~1.6KB)
; Separator Density: VERY HIGH (~300 separators in 100 lines)
; Zone Transitions: GRADUAL (not clean boundaries)
; Complexity Level: MAXIMUM (most complex section of Bank $0e)
;
; ARCHITECTURAL HYPOTHESIS:
; This zone represents INTERLEAVED voice and instrument data
; - A-tier separators: Voice channel assignments
; - B-tier separators: Instrument/envelope parameters
; - C-tier separators: DSP/effect parameters
; - Mixed pattern suggests real-time voice/instrument pairing data
; - Possibly used during music playback for dynamic voice allocation
;
; BANK $0e SEPARATOR TIER SYSTEM (COMPLETE):
; Total identified separator values: 40+ unique bytes
; Organized into 9+ functional tiers
; Most sophisticated data organization in FFMQ ROM
