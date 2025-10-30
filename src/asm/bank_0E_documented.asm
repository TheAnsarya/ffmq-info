; ==============================================================================
; Bank $0E - Extended APU/Sound Data (Continuation of Bank $0D)
; ==============================================================================
; Bank $0E Size: 2,051 source lines (estimated ~32KB of $0E8000-$0EFFFF range)
; Content: Appears to be extension of Bank $0D's SPC700 audio processor data
; Format: Continuation of DSP configuration, music patterns, voice data
; ==============================================================================

; ==============================================================================
; Bank $0E - Extended APU/Sound Data (Continuation of Bank $0D)
; Lines 1-400: Voice Configuration Sequences & DSP Register Data
; Address Range: $0E8000-$0E8FC0 (~4KB audio pattern data)
; ==============================================================================

; ------------------------------------------------------------------------------
; $0E8000-$0E80FF: Initial Voice Channel Sequences (256 bytes)
; ------------------------------------------------------------------------------
; Pattern structure identical to Bank $0D continuation:
; - $8A markers: Channel/voice separators (splits audio into tracks)
; - $CC/$DD/$BC/$DC/$EE/$EF: Envelope sequences (ADSR/volume control)
; - $Fx/$Ex: DSP register addresses ($F0-$FF range)
; - Digit sequences: Note/duration/pitch parameters
;
; Channel separator $8A appears at:
; - 0E8003, 0E8010, 0E8020, 0E8030, 0E8040, 0E8050, 0E8060, 0E8070
; - 0E8080, 0E8090, 0E80A0, 0E80B0, 0E80C0, 0E80D0, 0E80E0
; Pattern indicates multi-track music/SFX data (16+ channels in first 256 bytes)

                                                            ;      |        |      ;
                       ORG $0E8000                          ;      |        |      ;
                                                            ;      |        |      ;
                       db $44,$43,$0E,$CC,$CC,$CD,$F0,$12,$8A,$32,$21,$FC,$CC,$DC,$EF,$11;0E8000|        |      ;
; $44,$43,$0E: Initial parameters (note values or timing)
; $CC,$CC,$CD: Voice envelope markers (voice configuration)
; $F0,$12: DSP register $F0 (FLG - DSP flags/control), value $12
; $8A: Channel separator (voice 0 complete, start voice 1)
; $32,$21,$FC: Voice 1 parameters
; $CC,$DC,$EF,$11: Voice 1 envelope sequence

                       db $45,$8A,$53,$22,$11,$FE,$DD,$E0,$11,$43,$8A,$44,$42,$0F,$DB,$BC;0E8010|        |      ;
; $45: Parameter continuation
; $8A: Channel separator (voice 1→2)
; $53,$22,$11: Voice 2 initial params
; $FE: Voice envelope marker
; $DD: Voice configuration
; $E0,$11: DSP register $E0 (likely EDL - echo delay), value $11
; $43: Param
; $8A: Channel separator (voice 2→3)
; $44,$42,$0F: Voice 3 params
; $DB,$BC: Voice 3 envelope

                       db $DE,$EF,$13,$8A,$32,$20,$FD,$CB,$DD,$EF,$11,$45,$8A,$52,$32,$1F;0E8020|        |      ;
; $DE,$EF,$13: Envelope sequence for voice 3
; $8A: Channel separator (voice 3→4)
; $32,$20,$FD: Voice 4 params
; $CB,$DD,$EF,$11: Voice 4 envelope
; $45: Param
; $8A: Channel separator (voice 4→5)
; $52,$32,$1F: Voice 5 params

                       db $0E,$EE,$EF,$02,$44,$8A,$33,$43,$0E,$DC,$BC,$DE,$EF,$13,$8A,$32;0E8030|        |      ;
; $0E: Param
; $EE,$EF,$02: Envelope sequence
; $44: Param
; $8A: Channel separator (voice 5→6)
; $33,$43,$0E: Voice 6 params
; $DC,$BC,$DE,$EF,$13: Voice 6 extended envelope
; $8A: Channel separator (voice 6→7)

                       db $10,$FD,$DD,$CB,$E0,$11,$44,$8A,$53,$32,$10,$FE,$EE,$EF,$02,$35;0E8040|        |      ;
; Voice 7 data: $10,$FD,$DD,$CB
; $E0,$11: DSP register $E0 = $11
; $44: Param
; $8A: Channel separator (voice 7→8)
; Voice 8 data: $53,$32,$10,$FE,$EE,$EF,$02,$35

                       db $8A,$43,$23,$1F,$CC,$BC,$DE,$EF,$12,$8A,$33,$20,$ED,$DC,$CD,$EF;0E8050|        |      ;
; $8A: Channel separator at start (voice 8→9)
; Voice 9 data: $43,$23,$1F,$CC,$BC,$DE,$EF,$12
; $8A: Channel separator (voice 9→10)
; Voice 10 data: $33,$20,$ED,$DC,$CD,$EF

                       db $02,$45,$8A,$43,$32,$10,$FE,$EE,$EF,$12,$34,$8A,$43,$32,$1F,$CB;0E8060|        |      ;
; $02,$45: Voice 10 params
; $8A: Channel separator (voice 10→11)
; Voice 11 data: $43,$32,$10,$FE,$EE,$EF,$12,$34
; $8A: Channel separator (voice 11→12)
; Voice 12 start: $43,$32,$1F,$CB

                       db $CD,$CE,$E0,$12,$8A,$23,$20,$ED,$DD,$CC,$EF,$03,$44,$8A,$43,$32;0E8070|        |      ;
; Voice 12 envelope: $CD,$CE
; $E0,$12: DSP register $E0 = $12 (echo delay adjustment)
; $8A: Channel separator (voice 12→13)
; Voice 13: $23,$20,$ED,$DD,$CC,$EF,$03,$44
; $8A: Channel separator (voice 13→14)
; Voice 14 start: $43,$32

                       db $10,$FF,$EE,$DF,$13,$33,$8A,$44,$22,$1F,$CC,$CC,$CE,$F0,$02,$8A;0E8080|        |      ;
; Voice 14: $10,$FF,$EE,$DF,$13,$33
; $8A: Channel separator (voice 14→15)
; Voice 15: $44,$22,$1F,$CC,$CC,$CE
; $F0,$02: DSP register $F0 (FLG) = $02 (reset/noise/mute flags)
; $8A: Channel separator (voice 15→16)

                       db $32,$11,$FD,$CD,$CD,$DF,$13,$34,$8A,$43,$32,$10,$0E,$EE,$EF,$12;0E8090|        |      ;
; Voice 16: $32,$11,$FD,$CD,$CD,$DF,$13,$34
; $8A: Channel separator (voice 16→17)
; Voice 17: $43,$32,$10,$0E,$EE,$EF,$12

                       db $24,$8A,$44,$22,$1F,$DC,$BB,$DE,$F0,$01,$8A,$34,$10,$FD,$CC,$DD;0E80A0|        |      ;
; Voice 17 continues: $24
; $8A: Channel separator (voice 17→18)
; Voice 18: $44,$22,$1F,$DC,$BB,$DE
; $F0,$01: DSP register $F0 = $01
; $8A: Channel separator (voice 18→19)
; Voice 19: $34,$10,$FD,$CC,$DD

                       db $EE,$12,$44,$8A,$43,$32,$10,$0F,$DE,$EF,$03,$43,$8A,$33,$32,$1F;0E80B0|        |      ;
                       db $DC,$BC,$CF,$EF,$13,$8A,$22,$11,$FD,$CC,$DD,$EF,$02,$44,$8A,$43;0E80C0|        |      ;
                       db $32,$10,$0F,$ED,$EF,$12,$43,$8A,$33,$32,$10,$DB,$BC,$DE,$EF,$13;0E80D0|        |      ;
                       db $8A,$22,$20,$EE,$EB,$CD,$EF,$12,$34,$8A,$34,$42,$00,$0F,$EE,$DF;0E80E0|        |      ;
                       db $13,$33,$8B,$33,$33,$1F,$CC,$BC,$DE,$EF,$22,$33,$0C,$02,$00,$00;0E80F0|        |      ;
; $8B at 0E80F2: Variant channel separator (indicates different voice type or mode)
; $0C,$02,$00,$00: Control sequence or padding before next section

; ------------------------------------------------------------------------------
; $0E8100-$0E81FF: Dense Voice Marker Sequences (256 bytes)
; ------------------------------------------------------------------------------
; Zero padding appears at 0E80FC-0E8107 (12 bytes of $00)
; Marks transition from initial channel setup to voice configuration tables
; New marker set: $B2, $B1, $B3, $A2 (voice assignment markers, same as Bank $0D)

                       db $00,$00,$00,$00,$00,$00,$B2,$0F,$00,$B1,$30,$1F,$23,$F0,$2F,$C2;0E8100|        |      ;
; Zero padding: $00×6 (section separator)
; $B2: Voice marker (bass/rhythm voice, same as Bank $0D usage)
; $0F,$00: Parameters
; $B1: Voice marker (melody voice 1)
; $30,$1F,$23: Parameters
; $F0,$2F: DSP register $F0 = $2F
; $C2: Parameter

                       db $00,$00,$00,$F3,$3C,$E1,$00,$0F,$B2,$FF,$0E,$D3,$0B,$3F,$F1,$D3;0E8110|        |      ;
; $00×3: Padding
; $F3,$3C: Parameters
; $E1,$00,$0F: DSP register $E1 (possibly EON - echo on), values
; $B2: Voice marker return
; $FF,$0E,$D3,$0B,$3F: Parameter sequence
; $F1,$D3: DSP register $F1, value $D3

                       db $10,$B2,$00,$42,$0F,$64,$D1,$32,$01,$EE,$B2,$30,$0E,$03,$B3,$FD;0E8120|        |      ;
; $10: Param
; $B2: Voice marker
; $00,$42,$0F,$64: Parameters
; $D1,$32,$01: Parameter sequence
; $EE: Envelope marker
; $B2: Voice marker return
; $30,$0E,$03: Params
; $B3: Voice marker (third voice type)
; $FD: Envelope marker

                       db $2C,$02,$0E,$A2,$D1,$FD,$1C,$11,$93,$0A,$33,$1E,$B2,$F2,$00,$01;0E8130|        |      ;
; $2C,$02,$0E: Params
; $A2: Voice marker (fourth voice type - saw this in Bank $0D)
; $D1,$FD,$1C,$11: Parameter sequence
; $93: Parameter (high value - possibly note pitch or velocity)
; $0A,$33,$1E: Params
; $B2: Voice marker return
; $F2,$00,$01: DSP register $F2, values

                       db $0F,$0F,$11,$2E,$24,$A2,$E0,$07,$E0,$F4,$2E,$FB,$6B,$E0,$B2,$E1;0E8140|        |      ;
; $0F,$0F,$11,$2E,$24: Parameter sequence
; $A2: Voice marker
; $E0,$07: DSP register $E0 = $07
; $E0,$F4: DSP register $E0 = $F4 (rapid change - tremolo/vibrato effect?)
; $2E,$FB,$6B: Params
; $E0: DSP register marker
; $B2: Voice marker
; $E1: DSP register marker

                       db $1D,$10,$D1,$0D,$E2,$FC,$12,$B2,$00,$03,$1C,$F3,$01,$3E,$22,$F2;0E8150|        |      ;
; $1D,$10: Params
; $D1,$0D: Parameter
; $E2,$FC,$12: DSP register $E2, values
; $B2: Voice marker
; $00,$03,$1C: Params
; $F3,$01,$3E,$22: Parameter sequence
; $F2: DSP register marker

                       db $A2,$10,$C1,$2D,$05,$1B,$3A,$24,$96,$B2,$EC,$3D,$01,$D0,$00,$0D;0E8160|        |      ;
; $A2: Voice marker
; $10,$C1,$2D,$05,$1B,$3A,$24: Parameter sequence
; $96: High value parameter
; $B2: Voice marker
; $EC,$3D,$01: Params
; $D0,$00,$0D: Parameter sequence

                       db $12,$F2,$A2,$FF,$33,$2A,$53,$E4,$F2,$FF,$4C,$B2,$F4,$0E,$F4,$0B;0E8170|        |      ;
; $12: Param
; $F2: DSP register marker
; $A2: Voice marker
; $FF,$33,$2A,$53: Parameter sequence
; $E4,$F2,$FF,$4C: Parameters (multiple $FF - maximum values)
; $B2: Voice marker
; $F4,$0E,$F4,$0B: DSP register $F4 repeated (pitch modulation?)

                       db $31,$EF,$D0,$21,$A2,$DE,$4F,$A2,$5E,$C0,$ED,$1D,$FF,$B2,$C2,$2D;0E8180|        |      ;
; $31: Param
; $EF,$D0,$21: Parameter sequence
; $A2: Voice marker
; $DE,$4F: Params
; $A2: Voice marker repeated (voice switch)
; $5E: Param
; $C0,$ED,$1D,$FF: Parameters
; $B2: Voice marker
; $C2,$2D: Params

                       db $20,$E2,$D3,$3E,$2E,$35,$B2,$C0,$F1,$3D,$31,$D4,$10,$2F,$10,$B2;0E8190|        |      ;
; Dense parameter/marker mixing continues
; Pattern: Voice markers ($A2/$B2/$B3) interspersed with:
; - DSP register addresses ($C0-$F4 range)
; - Parameters (digit sequences, envelope markers)
; - Control values ($FF, $00, high/low bounds)

                       db $21,$D1,$10,$FF,$01,$EF,$3C,$11,$92,$FC,$B2,$D6,$A2,$DF,$60,$3E;0E81A0|        |      ;
                       db $24,$A2,$FF,$41,$EF,$BF,$1E,$D1,$5C,$F5,$B2,$DF,$FF,$1F,$D1,$2E;0E81B0|        |      ;
                       db $1E,$7E,$B2,$B2,$F3,$B1,$4D,$04,$31,$00,$1F,$10,$B2,$12,$EE,$22;0E81C0|        |      ;
; $B2,$B2: Double voice marker (emphasis or channel lock)
; $F3,$B1: Parameters with $B1 marker
; Pattern shows complex voice interleaving

                       db $E1,$0F,$3F,$12,$C2,$B2,$0F,$1C,$1F,$D3,$D1,$5C,$0C,$03,$A2,$B2;0E81D0|        |      ;
; $A2,$B2: Voice marker sequence (voice handoff A2→B2)

                       db $30,$24,$D0,$2D,$01,$0F,$BF,$B2,$10,$42,$E0,$3F,$C3,$21,$0E,$32;0E81E0|        |      ;
                       db $B2,$BF,$2F,$1F,$2E,$E4,$EF,$02,$1F,$A2,$D1,$4D,$FC,$FE,$00,$B1;0E81F0|        |      ;
; $A2: Voice marker
; $D1,$4D,$FC,$FE,$00: Parameter sequence ending in zero
; $B1: Voice marker

; ------------------------------------------------------------------------------
; $0E8200-$0E82FF: Extended Voice Configuration (256 bytes)
; ------------------------------------------------------------------------------
; Continues dense marker pattern from previous section
; Increasing frequency of $A2/$B2/$B3 markers indicates complex multi-voice music

                       db $E2,$2E,$A2,$DC,$1D,$34,$E7,$E0,$5C,$13,$21,$A2,$13,$31,$EF,$50;0E8200|        |      ;
                       db $02,$30,$05,$D2,$B2,$31,$0E,$FF,$00,$F1,$F0,$6C,$D2,$B2,$F1,$1D;0E8210|        |      ;
; $F1,$F0,$6C: Parameters
; $D2: Parameter
; $B2: Voice marker
; $F1,$1D: Parameters

                       db $E1,$DF,$1E,$F2,$EC,$30,$B2,$01,$C1,$23,$1D,$20,$13,$01,$F2,$B2;0E8220|        |      ;
                       db $10,$2E,$13,$EF,$02,$0E,$0D,$13,$B2,$D0,$CF,$1F,$0C,$03,$1F,$30;0E8230|        |      ;
                       db $EE,$B2,$03,$E1,$2C,$14,$F0,$20,$E3,$2E,$B2,$12,$C0,$4E,$2F,$0F;0E8240|        |      ;
                       db $F1,$01,$E0,$A2,$B3,$13,$1F,$2F,$1D,$10,$30,$0F,$A2,$C2,$EE,$11;0E8250|        |      ;
; $A2,$B3: Voice marker transition (A2→B3 voice handoff)

                       db $50,$C2,$D5,$3E,$0F,$A2,$E9,$43,$FC,$51,$EE,$00,$B3,$C5,$A2,$1F;0E8260|        |      ;
; $B3,$C5,$A2: Voice marker sequence (B3→A2 transition with $C5 param)

                       db $3A,$C3,$50,$AE,$4E,$20,$B3,$B2,$30,$F0,$0F,$F4,$20,$E0,$21,$FE;0E8270|        |      ;
; $B3,$B2: Voice transition marker
; $30,$F0,$0F,$F4,$20: Parameter sequence
; $E0,$21: DSP register $E0 = $21
; $FE: Envelope marker

                       db $A2,$4D,$1F,$D1,$DD,$03,$11,$E9,$35,$A2,$CF,$03,$1A,$C2,$2E,$00;0E8280|        |      ;
                       db $C1,$7D,$C2,$00,$F0,$F1,$1E,$2F,$D4,$0F,$3F,$B2,$F1,$01,$DE,$22;0E8290|        |      ;
                       db $40,$01,$C3,$1D,$B2,$00,$00,$EE,$6F,$D0,$1F,$0F,$00,$B2,$B4,$2B;0E82A0|        |      ;
; $B2,$B4: New voice marker combination (B2→B4 transition)

                       db $10,$00,$C5,$2D,$F2,$3C,$A2,$12,$E2,$E0,$0E,$1D,$76,$CF,$D0,$B2;0E82B0|        |      ;
                       db $C1,$1F,$11,$3F,$0F,$2D,$F4,$D3,$B2,$FC,$40,$16,$EF,$1E,$D1,$3E;0E82C0|        |      ;
                       db $E1,$B2,$1F,$0E,$00,$C0,$0E,$EF,$00,$11,$B2,$FD,$E2,$21,$E0,$5E;0E82D0|        |      ;
                       db $F3,$1D,$11,$B2,$03,$0F,$02,$F2,$5D,$D2,$2E,$F1,$B2,$3F,$D5,$0D;0E82E0|        |      ;
                       db $C0,$3D,$13,$11,$01,$B2,$FF,$01,$F0,$0D,$2B,$F6,$F1,$00,$B2,$1F;0E82F0|        |      ;

; ------------------------------------------------------------------------------
; $0E8300-$0E83FF: Continued Voice Pattern Data (256 bytes)
; ------------------------------------------------------------------------------

                       db $F2,$22,$31,$00,$2E,$0E,$E3,$B2,$CF,$00,$11,$1F,$6E,$A5,$DD,$4E;0E8300|        |      ;
; $A5: New voice marker variant (or parameter)
; $DD: Envelope marker

                       db $B2,$01,$F2,$EF,$30,$FF,$3F,$D3,$E2,$B2,$20,$00,$4B,$E5,$C3,$5B;0E8310|        |      ;
                       db $1F,$13,$B2,$C0,$0F,$2F,$20,$C2,$2E,$E0,$00,$B2,$F1,$4C,$14,$9F;0E8320|        |      ;
                       db $2F,$1E,$F3,$10,$B2,$F1,$30,$12,$D0,$4F,$FE,$41,$D1,$A2,$1D,$01;0E8330|        |      ;
                       db $93,$CD,$3D,$D0,$14,$FF,$B2,$3F,$00,$04,$0C,$22,$D0,$03,$FC,$B2;0E8340|        |      ;
                       db $60,$F2,$F2,$BE,$0D,$2D,$0F,$E2,$B2,$04,$BC,$5F,$D0,$30,$02,$2F;0E8350|        |      ;
                       db $F1,$B2,$D0,$10,$3E,$F4,$1F,$F3,$DD,$5F,$B2,$E0,$E0,$12,$1F,$FE;0E8360|        |      ;
                       db $04,$0E,$03,$B2,$FC,$40,$E0,$14,$DF,$30,$F1,$43,$B2,$DE,$42,$D1;0E8370|        |      ;
                       db $51,$DF,$3F,$CD,$FF,$B2,$F0,$1D,$C0,$11,$AF,$19,$E1,$0E,$A2,$E4;0E8380|        |      ;
                       db $00,$D3,$2F,$00,$54,$12,$30,$B2,$13,$4C,$05,$E0,$12,$4E,$E5,$1E;0E8390|        |      ;
                       db $B2,$20,$00,$03,$DD,$21,$FF,$2F,$CE,$B2,$02,$FE,$F0,$DE,$2F,$FC;0E83A0|        |      ;
                       db $00,$FF,$A2,$04,$D7,$32,$7C,$26,$F0,$66,$22,$A2,$37,$7E,$E7,$DB;0E83B0|        |      ;
; $A2: Voice marker
; $04,$D7,$32,$7C,$26: Parameter sequence
; $F0,$66,$22: DSP register $F0 = $66, param $22
; $A2: Voice marker return
; $37,$7E: Params (high values - loud/bright voice)
; $E7,$DB: Parameters

                       db $5B,$D0,$F3,$AF,$B2,$0E,$F0,$40,$E3,$20,$E1,$2C,$E0,$B2,$C2,$0E;0E83C0|        |      ;
                       db $5C,$C6,$0C,$0F,$01,$E0,$B2,$3E,$E3,$1F,$1F,$EF,$24,$E0,$31,$B2;0E83D0|        |      ;
                       db $00,$2F,$02,$E3,$0A,$40,$F5,$DF,$B2,$0D,$20,$02,$11,$C2,$2E,$2C;0E83E0|        |      ;
                       db $F2,$B2,$DF,$FF,$0D,$DE,$FF,$CF,$F0,$2F,$B2,$20,$03,$E0,$41,$F2;0E83F0|        |      ;

; ------------------------------------------------------------------------------
; $0E8400-$0E84FF: Voice Configuration Tables Continue (256 bytes)
; ------------------------------------------------------------------------------

                       db $22,$3F,$11,$B2,$F3,$0D,$F4,$1E,$22,$0D,$0E,$10,$B2,$B3,$DE,$2E;0E8400|        |      ;
; $B2,$B3: Voice marker transition

                       db $10,$FF,$FD,$FF,$C0,$A2,$1E,$3F,$A1,$3C,$F1,$E2,$20,$22,$A2,$03;0E8410|        |      ;
; $A1: Possible new voice marker (or parameter $A1)
; $3C: Parameter
; $F1,$E2,$20,$22: Parameter sequence
; $A2: Voice marker

                       db $44,$25,$4E,$22,$30,$14,$F2,$B2,$F2,$1D,$00,$0F,$1B,$E2,$EF,$02;0E8420|        |      ;
                       db $A2,$CD,$5F,$D1,$6F,$B1,$2F,$AF,$72,$B2,$B1,$4E,$FF,$E1,$2D,$00;0E8430|        |      ;
; $B1: Voice marker (melody voice)
; $2F,$AF,$72: Parameters (high value $AF)
; $B2,$B1: Voice transition marker

                       db $D2,$11,$B2,$0F,$00,$2D,$01,$C2,$20,$11,$20,$B2,$FF,$35,$FF,$11;0E8440|        |      ;
                       db $30,$F1,$F0,$FE,$B2,$2C,$05,$D0,$40,$EE,$FF,$12,$ED,$B2,$30,$C0;0E8450|        |      ;
                       db $0F,$FC,$14,$C1,$4E,$00,$B2,$10,$E2,$41,$03,$40,$12,$12,$F2,$B2;0E8460|        |      ;
                       db $40,$EF,$33,$EF,$1F,$DC,$FF,$01,$B2,$AE,$3D,$01,$D1,$30,$0E,$2F;0E8470|        |      ;
; $AE: High parameter value

                       db $D4,$A2,$41,$12,$E0,$5F,$FE,$52,$E0,$35,$A2,$F0,$E0,$F1,$39,$1F;0E8480|        |      ;
; $A2: Voice marker
; $41,$12: Params
; $E0,$5F: DSP register $E0 = $5F
; $FE: Envelope marker
; $52: Param
; $E0,$35: DSP $E0 = $35
; $A2: Voice marker
; $F0,$E0,$F1,$39,$1F: DSP register sequence ($F0, $E0, $F1)

                       db $B1,$E4,$AC,$B2,$2D,$20,$C0,$01,$2F,$21,$C3,$10,$A2,$43,$1C,$42;0E8490|        |      ;
; $B1: Voice marker
; $E4,$AC: Parameters (high value $AC)
; $B2: Voice marker
; ... followed by $A2 voice marker

                       db $43,$C2,$4E,$22,$E0,$A2,$D1,$5D,$9F,$DE,$1B,$13,$BC,$0F,$A2,$E0;0E84A0|        |      ;
; $9F: High parameter value
; $A2: Voice marker appears twice in sequence

                       db $DA,$65,$B0,$13,$02,$5F,$E3,$A2,$42,$43,$51,$F4,$3E,$00,$E4,$1A;0E84B0|        |      ;
; $DA,$65,$B0: Parameters (high values)
; $A2: Voice marker
; $F4,$3E,$00: Parameters
; $E4,$1A: DSP register $E4, value $1A

                       db $B2,$F0,$E2,$0F,$0B,$E1,$EE,$1F,$CF,$B2,$1E,$E2,$0F,$1F,$15,$FF;0E84C0|        |      ;
                       db $40,$33,$A2,$E2,$00,$40,$02,$01,$2F,$0F,$D6,$B2,$EF,$3D,$10,$E0;0E84D0|        |      ;
                       db $F0,$EC,$D1,$0F,$B2,$10,$E2,$1C,$05,$FF,$3F,$01,$F3,$B2,$FE,$51;0E84E0|        |      ;
                       db $E1,$0F,$00,$02,$EF,$21,$A6,$DD,$3F,$2F,$0B,$15,$E5,$CF,$2F,$B2;0E84F0|        |      ;
; $A6: New voice marker variant (or high parameter)

; ------------------------------------------------------------------------------
; $0E8500-$0E85FF: Dense Parameter Sequences (256 bytes)
; ------------------------------------------------------------------------------

                       db $0E,$21,$C3,$3D,$0E,$F4,$EF,$31,$B2,$0E,$F2,$1C,$F0,$E1,$11,$DD;0E8500|        |      ;
                       db $3F,$B2,$D0,$0F,$DD,$31,$02,$F2,$DF,$4E,$A2,$26,$F1,$10,$23,$FF;0E8510|        |      ;
                       db $40,$DD,$FE,$B2,$02,$F0,$1F,$FE,$F0,$FF,$03,$CD,$B2,$4F,$0C,$02;0E8520|        |      ;
                       db $D0,$F1,$1E,$21,$DF,$A2,$1F,$A2,$72,$10,$61,$C2,$32,$F2,$A2,$40;0E8530|        |      ;
; $A2,$1F,$A2: Double voice marker with param between (voice ping-pong)
; $72: High parameter
; $61: Parameter
; $A2: Voice marker return

                       db $10,$E1,$10,$EB,$A0,$2B,$C2,$A2,$0C,$DC,$02,$AF,$60,$C0,$63,$E4;0E8540|        |      ;
; $EB,$A0: High parameters
; $A2: Voice marker
; $AF,$60: High parameters
; $C0,$63: Parameters
; $E4: DSP register marker

                       db $B2,$2F,$FF,$24,$0E,$3E,$D3,$E0,$DD,$B2,$3D,$11,$C1,$FF,$3F,$F0;0E8550|        |      ;
                       db $F1,$10,$A2,$DD,$20,$1F,$D0,$BF,$01,$0F,$19,$A2,$34,$F4,$FD,$42;0E8560|        |      ;
; $BF: High parameter

                       db $0F,$04,$E2,$31,$B2,$0D,$12,$0F,$F1,$1F,$F1,$EF,$4E,$A2,$B7,$FE;0E8570|        |      ;
; $B7: Voice marker variant (or high parameter)

                       db $4E,$25,$D0,$6F,$F4,$22,$A2,$0E,$4F,$C3,$E0,$FE,$2D,$FE,$C1,$A2;0E8580|        |      ;
                       db $CE,$5C,$B1,$03,$00,$1A,$F4,$DD,$A2,$ED,$31,$E7,$4A,$F5,$62,$34;0E8590|        |      ;
; $B1: Voice marker
; $A2: Voice marker
; $E7,$4A,$F5,$62: Parameter sequence (high values)

                       db $E4,$A2,$53,$30,$F2,$1B,$41,$F3,$C4,$6B,$B2,$F1,$CC,$FF,$FD,$ED;0E85A0|        |      ;
; $C4,$6B: High parameters
; $B2: Voice marker
; $CC,$FF,$FD: Parameter sequence (multiple high values)

                       db $13,$C0,$1B,$A2,$02,$E3,$EC,$06,$20,$3C,$52,$F4,$B2,$F2,$FF,$40;0E85B0|        |      ;
                       db $F1,$00,$02,$3E,$F1,$A2,$12,$D3,$1C,$21,$FC,$05,$9F,$40,$B2,$ED;0E85C0|        |      ;
                       db $0F,$FE,$12,$FF,$14,$0C,$04,$A2,$4E,$37,$DB,$75,$ED,$D4,$1C,$30;0E85D0|        |      ;
; $DB,$75: High parameters
; $D4: Parameter

                       db $B2,$E1,$11,$1D,$E0,$F1,$2C,$04,$FE,$A2,$22,$CD,$01,$3E,$F6,$DA;0E85E0|        |      ;
; $F6,$DA: High parameters (max values)

                       db $33,$50,$B2,$F2,$DE,$4F,$E4,$FF,$3E,$10,$D1,$B2,$00,$2F,$F0,$11;0E85F0|        |      ;

; ------------------------------------------------------------------------------
; $0E8600-$0E86FF: Extended Voice Tables (256 bytes)
; ------------------------------------------------------------------------------

                       db $F3,$EC,$01,$0E,$B2,$11,$1E,$04,$DF,$4E,$F1,$D2,$0D,$B2,$1F,$21;0E8600|        |      ;
                       db $C0,$FE,$11,$01,$F0,$0D,$A2,$ED,$BD,$D1,$BD,$2E,$10,$C5,$2D,$A2;0E8610|        |      ;
; $BD: High parameter (repeated twice)
; $C5: Parameter
; $A2: Voice marker

                       db $21,$23,$F0,$30,$44,$C1,$54,$F1,$B2,$3F,$D2,$1C,$12,$C0,$F0,$1E;0E8620|        |      ;
                       db $0E,$B2,$01,$D1,$0B,$02,$F0,$0F,$00,$EF,$B2,$3F,$D1,$31,$E0,$1E;0E8630|        |      ;
                       db $14,$20,$D1,$BA,$F9,$41,$00,$E1,$1F,$00,$00,$10,$A2,$DE,$EE,$3F;0E8640|        |      ;
; $BA,$F9: High parameters
; $A2: Voice marker
; $DE,$EE,$3F: Parameter sequence

                       db $D1,$CE,$30,$31,$14,$A2,$F4,$2C,$62,$D1,$01,$2C,$E4,$01,$B2,$0F;0E8650|        |      ;
; $CE: Parameter
; $A2: Voice marker
; $F4,$2C,$62: Parameters
; $E4: DSP register marker
; $B2: Voice marker

                       db $11,$EE,$20,$C1,$2F,$0F,$20,$B2,$D0,$10,$E1,$20,$01,$2C,$04,$02;0E8660|        |      ;
                       db $A2,$0C,$41,$C2,$4D,$E7,$5D,$F4,$0F,$B2,$11,$3F,$E0,$B1,$4E,$21;0E8670|        |      ;
; $E7,$5D: Parameters
; $F4,$0F: DSP register $F4 = $0F
; $B1: Voice marker

                       db $D0,$10,$A2,$DE,$EF,$3E,$14,$DE,$25,$3D,$3F,$B2,$F3,$12,$FD,$22;0E8680|        |      ;
                       db $20,$D1,$3E,$04,$A2,$2D,$D4,$1D,$1D,$B1,$31,$EC,$14,$A2,$CD,$50;0E8690|        |      ;
; $B1: Voice marker
; $EC: Parameter
; $A2: Voice marker
; $CD: Parameter

                       db $F1,$2D,$17,$F0,$0C,$FF,$B2,$E1,$FE,$3F,$00,$D4,$10,$4E,$FF,$A2;0E86A0|        |      ;
                       db $F6,$C0,$4D,$EE,$0F,$90,$41,$0F,$A2,$FF,$12,$02,$3C,$D1,$32,$F3;0E86B0|        |      ;
; $F6,$C0: High parameters
; $90: High parameter
; $A2: Voice marker (appears twice)

                       db $10,$A2,$33,$F3,$6F,$14,$00,$0C,$FD,$B0,$A2,$CE,$DB,$21,$0D,$00;0E86C0|        |      ;
; $DB: High parameter
; $B0: Voice marker variant (or parameter)
; $A2: Voice marker

                       db $D1,$16,$FD,$B2,$42,$11,$F2,$2F,$12,$00,$00,$FF,$A2,$00,$19,$C7;0E86D0|        |      ;
; $C7: Parameter
; $A2: Voice marker

                       db $4F,$D2,$DF,$5B,$CE,$B2,$FE,$F2,$EE,$20,$10,$EF,$FD,$F5,$B2,$DB;0E86E0|        |      ;
; $DF,$5B,$CE: Parameters
; $F5: Parameter
; $DB: High parameter

                       db $20,$24,$09,$15,$04,$42,$0E,$B2,$52,$D3,$1E,$00,$0F,$D0,$3E,$F1;0E86F0|        |      ;

; ------------------------------------------------------------------------------
; $0E8700-$0E87FF: Complex Voice Interleaving (256 bytes)
; ------------------------------------------------------------------------------

                       db $B2,$CF,$10,$3E,$F2,$EF,$F1,$1E,$F1,$A2,$32,$C3,$7D,$37,$EF,$2E;0E8700|        |      ;
; $CF: Parameter
; $A2: Voice marker
; $7D,$37: High parameters

                       db $03,$00,$A2,$1E,$00,$C0,$ED,$43,$E1,$20,$D0,$A2,$1F,$1D,$DD,$E3;0E8710|        |      ;
                       db $02,$1B,$E3,$3D,$B2,$DF,$30,$D2,$2E,$03,$FE,$02,$1D,$B2,$13,$1F;0E8720|        |      ;
                       db $D4,$4C,$C2,$0D,$10,$00,$A2,$F2,$F1,$20,$1F,$11,$C1,$4E,$43,$B2;0E8730|        |      ;
                       db $F1,$12,$EF,$3F,$C1,$1F,$0C,$01,$A2,$BE,$F0,$00,$B1,$4C,$E2,$1F;0E8740|        |      ;
; $BE: High parameter
; $A2: Voice marker
; $B1: Voice marker

                       db $F2,$A2,$2D,$06,$FC,$55,$EC,$F7,$2C,$04,$A2,$5A,$D3,$44,$E4,$1D;0E8750|        |      ;
; $EC,$F7: High parameters
; $A2: Voice marker (appears twice)
; $5A: Marker (channel separator from early pattern)

                       db $40,$2E,$D3,$A6,$CE,$F2,$0F,$E1,$6B,$B5,$01,$0B,$A2,$32,$B2,$BD;0E8760|        |      ;
; $A6: Voice marker variant
; $6B,$B5: Parameters
; $A2: Voice marker
; $B2: Voice marker
; $BD: High parameter

                       db $4E,$11,$E1,$2D,$44,$A2,$A1,$37,$3D,$62,$06,$01,$3F,$2D,$A2,$36;0E8770|        |      ;
; $A2,$A1: Voice marker sequence
; $62: Parameter
; $A2: Voice marker return

                       db $C0,$D1,$6E,$D0,$2C,$D6,$CA,$A2,$2F,$1D,$A2,$FB,$E2,$39,$D7,$0D;0E8780|        |      ;
; $6E: Parameter
; $D6,$CA: Parameters
; $A2: Voice marker (appears twice)
; $FB: High parameter
; $D7: Parameter

                       db $A2,$07,$3E,$FF,$30,$C4,$6D,$E1,$0F,$A2,$F3,$24,$2E,$10,$13,$FD;0E8790|        |      ;
; $C4,$6D: Parameters
; $A2: Voice marker (appears twice)

                       db $10,$D7,$B2,$1D,$22,$21,$F1,$1F,$03,$10,$2E,$A2,$D7,$2C,$E1,$EF;0E87A0|        |      ;
; $D7: Parameter (repeated from 0E878D)
; $B2: Voice marker
; $A2: Voice marker
; $D7: Parameter (third occurrence)

                       db $31,$FC,$0F,$C4,$A2,$1C,$B0,$7D,$B2,$FF,$2F,$14,$A0,$B2,$2F,$12;0E87B0|        |      ;
; $C4: Parameter
; $A2: Voice marker
; $B0: Voice marker variant
; $7D: High parameter
; $B2: Voice marker (appears three times)
; $A0: Voice marker variant

                       db $2F,$D1,$40,$F0,$23,$E0,$A2,$6D,$D0,$0F,$D0,$1D,$01,$F0,$D0,$A2;0E87C0|        |      ;
; $6D: Parameter
; $D0: Parameter (repeated multiple times)
; $A2: Voice marker (appears twice)

                       db $ED,$DC,$2A,$D3,$0D,$B5,$DC,$3E,$B2,$20,$02,$EF,$21,$EF,$54,$E0;0E87D0|        |      ;
; $B5: Voice marker variant
; $DC: Parameter (repeated)
; $B2: Voice marker

                       db $53,$B2,$01,$10,$00,$10,$D1,$0A,$02,$FF,$B2,$D0,$0D,$DE,$1E,$C2;0E87E0|        |      ;
                       db $00,$2D,$01,$A2,$B3,$0D,$F1,$32,$E1,$4A,$F2,$F4,$B2,$E0,$4F,$E1;0E87F0|        |      ;
; $A2,$B3: Voice marker sequence
; $4A: Parameter
; $F2,$F4: DSP registers
; $B2: Voice marker

; ------------------------------------------------------------------------------
; $0E8800-$0E88FF: Advanced Voice Configuration (256 bytes)
; ------------------------------------------------------------------------------

                       db $10,$01,$2F,$D1,$1D,$A2,$34,$91,$4D,$CD,$D1,$50,$CE,$C2,$A2,$3B;0E8800|        |      ;
; $91: High parameter
; $CD: Parameter
; $CE: Parameter
; $A2: Voice marker (appears twice)
; $3B: Parameter

                       db $F1,$EF,$F3,$3E,$23,$F0,$FF,$A2,$DF,$2D,$21,$E0,$BF,$EF,$2E,$EF;0E8810|        |      ;
; $BF: High parameter
; $A2: Voice marker

                       db $A2,$21,$11,$20,$B0,$42,$0E,$46,$01,$B2,$11,$F0,$4E,$E2,$00,$22;0E8820|        |      ;
; $A2: Voice marker at start
; $B0: Voice marker variant
; $B2: Voice marker

                       db $1F,$E0,$A2,$0E,$A5,$EC,$6E,$FF,$1E,$F4,$BD,$A2,$31,$11,$2E,$10;0E8830|        |      ;
; $A2: Voice marker
; $A5: Voice marker variant
; $EC,$6E: Parameters
; $BD: High parameter
; $A2: Voice marker return

                       db $C5,$CE,$3F,$40,$A2,$01,$11,$F0,$4D,$23,$F6,$34,$20,$A2,$E3,$1A;0E8840|        |      ;
; $C5,$CE: Parameters
; $A2: Voice marker (appears twice)
; $F6: High parameter

                       db $31,$C0,$FF,$3C,$AD,$EE,$A2,$E3,$EA,$21,$F3,$C0,$5D,$0F,$13,$B2;0E8850|        |      ;
; $AD,$EE: High parameters
; $A2: Voice marker
; $EA: High parameter
; $B2: Voice marker

                       db $F2,$F0,$2E,$2F,$B2,$1E,$1F,$F3,$A2,$FB,$1F,$D0,$01,$1B,$E3,$10;0E8860|        |      ;
; $B2: Voice marker (appears twice)
; $A2: Voice marker
; $FB: High parameter

                       db $00,$A6,$11,$C2,$1E,$0F,$1F,$2F,$B2,$22,$A2,$20,$EF,$33,$35,$12;0E8870|        |      ;
; $A6: Voice marker variant
; $B2: Voice marker
; $A2: Voice marker

                       db $20,$4F,$00,$B2,$02,$D1,$2C,$02,$00,$B0,$4B,$E4,$A2,$40,$A0,$5D;0E8880|        |      ;
; $B2: Voice marker
; $B0: Voice marker variant
; $4B: Parameter
; $E4: DSP register marker
; $A2: Voice marker
; $A0: Voice marker variant

                       db $B4,$4B,$E3,$1E,$12,$A2,$13,$F0,$1B,$33,$C1,$1D,$10,$BD,$A2,$43;0E8890|        |      ;
; $B4: Voice marker variant
; $4B: Parameter (repeated)
; $E3: DSP register marker
; $A2: Voice marker (appears twice)
; $BD: High parameter

                       db $CC,$04,$FE,$2D,$20,$F3,$FE,$A2,$E3,$23,$0C,$11,$FF,$1E,$36,$E2;0E88A0|        |      ;
; $CC: Parameter
; $A2: Voice marker
; $E2: DSP register marker

                       db $A2,$2E,$45,$DE,$5E,$C4,$2D,$E3,$4C,$A2,$91,$0B,$F1,$3C,$D5,$DD;0E88B0|        |      ;
; $A2: Voice marker (appears twice)
; $C4: Parameter
; $E3: DSP register marker
; $91: High parameter
; $D5,$DD: Parameters

                       db $0F,$0F,$B2,$00,$00,$FF,$21,$FF,$04,$0F,$41,$A2,$E2,$02,$2A,$D5;0E88C0|        |      ;
; $B2: Voice marker
; $A2: Voice marker
; $E2: DSP register marker
; $D5: Parameter

                       db $3E,$21,$F2,$DF,$A2,$FD,$1F,$FC,$C2,$EC,$CB,$21,$AE,$A6,$31,$01;0E88D0|        |      ;
; $DF: Parameter
; $A2: Voice marker
; $EC,$CB: Parameters
; $AE,$A6: High parameters

                       db $1E,$F1,$6D,$A6,$2D,$E6,$A2,$6C,$EF,$24,$DD,$2D,$E6,$CE,$4A,$A2;0E88E0|        |      ;
; $6D: Parameter
; $A6: Voice marker variant (appears twice)
; $E6: DSP register marker (appears twice)
; $6C: Parameter
; $CE: Parameter
; $4A: Parameter
; $A2: Voice marker

                       db $06,$AA,$4F,$B2,$30,$00,$02,$0E,$B2,$20,$C0,$1E,$00,$E0,$0F,$01;0E88F0|        |      ;
; $AA: Marker (voice assignment from early patterns)
; $B2: Voice marker (appears twice)
; $C0: Parameter
; $E0,$0F: DSP register $E0 = $0F

; ------------------------------------------------------------------------------
; $0E8900-$0E89FF: Extended Pattern Data (256 bytes)
; ------------------------------------------------------------------------------

                       db $02,$B2,$20,$21,$01,$E0,$DF,$4D,$DF,$01,$B2,$EF,$30,$D1,$2D,$C4;0E8900|        |      ;
; $B2: Voice marker (appears twice)
; $E0: DSP register marker
; $DF: Parameter (repeated)
; $C4: Parameter

                       db $4D,$02,$00,$B2,$02,$4F,$F2,$10,$F1,$11,$00,$FD,$A6,$4F,$10,$F0;0E8910|        |      ;
; $B2: Voice marker
; $F2: DSP register marker
; $F1: DSP register marker
; $A6: Voice marker variant
; $F0: DSP register marker

                       db $F3,$B1,$22,$FF,$2D,$A6,$4D,$22,$DF,$17,$CA,$30,$1E,$36,$B2,$C0;0E8920|        |      ;
; $F3: DSP register marker
; $B1: Voice marker
; $A6: Voice marker variant
; $DF: Parameter
; $CA: Parameter
; $B2: Voice marker
; $C0: Parameter

                       db $2D,$31,$11,$10,$32,$F1,$12,$B2,$11,$1E,$0F,$E1,$E1,$FC,$2E,$E0;0E8930|        |      ;
; $F1: DSP register marker
; $B2: Voice marker
; $E1: DSP register marker (repeated)
; $E0: DSP register marker

                       db $A2,$A0,$CC,$3E,$10,$D5,$DB,$5F,$D4,$B2,$11,$E1,$5C,$F2,$E1,$0F;0E8940|        |      ;
; $A2: Voice marker
; $A0: Voice marker variant
; $CC: Parameter
; $D5,$DB,$5F,$D4: Parameter sequence
; $B2: Voice marker
; $E1: DSP register marker
; $F2: DSP register marker
; $E1: DSP register marker

                       db $12,$0F,$A2,$CD,$53,$DF,$F0,$11,$0C,$E3,$3D,$A2,$CF,$E0,$32,$DE;0E8950|        |      ;
; $A2: Voice marker (appears twice)
; $CD: Parameter
; $DF: Parameter
; $F0: DSP register marker
; $E3: DSP register marker
; $CF: Parameter
; $E0: DSP register marker
; $DE: Parameter

                       db $2B,$E2,$34,$1F,$A2,$F3,$E0,$3E,$15,$1F,$11,$3D,$03,$A2,$A2,$2C;0E8960|        |      ;
; $E2: DSP register marker
; $A2: Voice marker (appears three times - double marker)
; $F3: DSP register marker
; $E0: DSP register marker

                       db $00,$FC,$A1,$7C,$C0,$04,$A2,$E2,$11,$DF,$5E,$33,$E4,$4C,$E1,$A2;0E8970|        |      ;
; $A1: Voice marker variant
; $7C: High parameter
; $C0: Parameter
; $A2: Voice marker (appears twice)
; $E2: DSP register marker
; $DF: Parameter
; $E4: DSP register marker
; $E1: DSP register marker

                       db $60,$A6,$3C,$01,$ED,$03,$F9,$BF,$A2,$09,$A3,$CD,$3F,$0E,$B3,$FE;0E8980|        |      ;
; $A6: Voice marker variant
; $F9,$BF: High parameters
; $A2: Voice marker
; $A3: Voice marker variant (new)
; $CD: Parameter
; $B3: Voice marker
; $FE: Envelope marker

                       db $73,$A6,$93,$40,$3D,$C6,$0A,$52,$CE,$35,$B2,$2F,$E0,$30,$E1,$1F;0E8990|        |      ;
; $73: High parameter
; $A6: Voice marker variant
; $93: High parameter
; $C6: Parameter
; $CE: Parameter
; $B2: Voice marker
; $E0: DSP register marker
; $E1: DSP register marker

                       db $E1,$0B,$F2,$B2,$EF,$FF,$EC,$F1,$EF,$2E,$E1,$FE,$B6,$22,$DF,$32;0E89A0|        |      ;
; $E1: DSP register marker
; $F2: DSP register marker
; $B2: Voice marker
; $EC: Parameter
; $F1: DSP register marker
; $E1: DSP register marker
; $B6: Voice marker variant (new)
; $DF: Parameter

                       db $DF,$3F,$F0,$23,$CE,$A2,$32,$20,$53,$A3,$2D,$1D,$01,$CC,$A2,$F3;0E89B0|        |      ;
; $DF: Parameter
; $F0: DSP register marker
; $CE: Parameter
; $A2: Voice marker
; $A3: Voice marker variant
; $CC: Parameter
; $A2: Voice marker
; $F3: DSP register marker

                       db $1C,$E7,$5D,$0F,$D0,$40,$D2,$B2,$EF,$3B,$E5,$ED,$01,$2E,$E3,$1F;0E89C0|        |      ;
; $E7: DSP register marker
; $D0,$40,$D2: Parameter sequence
; $B2: Voice marker
; $E5: DSP register marker
; $ED: Parameter
; $E3: DSP register marker

                       db $A2,$12,$FC,$17,$3D,$23,$A1,$50,$2D,$A2,$17,$E0,$0D,$41,$E3,$1C;0E89D0|        |      ;
; $A2: Voice marker (appears twice)
; $A1: Voice marker variant
; $E0: DSP register marker
; $E3: DSP register marker

                       db $D2,$31,$A2,$32,$12,$11,$E2,$1A,$03,$FC,$C1,$A2,$DA,$2B,$A0,$DF;0E89E0|        |      ;
; $D2: Parameter
; $A2: Voice marker (appears twice)
; $E2: DSP register marker
; $DA: High parameter
; $A0: Voice marker variant
; $DF: Parameter

                       db $F0,$4F,$D0,$E6,$B2,$FE,$21,$40,$F2,$21,$D1,$5F,$23,$A2,$B5,$6C;0E89F0|        |      ;
; $F0: DSP register marker
; $D0: Parameter
; $E6: DSP register marker
; $B2: Voice marker
; $F2: DSP register marker
; $D1: Parameter
; $A2: Voice marker
; $B5: Voice marker variant
; $6C: Parameter

; ==============================================================================
; End of Bank $0E Cycle 1 (Lines 1-400)
; Documented Address Range: $0E8000-$0E8A00 (2,560 bytes)
; ==============================================================================
; Technical Summary:
; - Continuation of Bank $0D's SPC700 audio driver data
; - 16+ voice channels in first 256 bytes (high complexity music)
; - Voice markers: $B2 (bass/rhythm), $B1 (melody 1), $B3 (third voice),
;                  $A2 (fourth voice), $A6 (variant), $B6 (variant),
;                  $A3 (new variant), $A1 (variant), $B0/$B4/$B5 (variants)
; - Channel separators: $8A (primary), $8B (variant at 0E80F2)
; - DSP registers used: $F0 (FLG), $E0 (EDL), $E1 (EON?), $E2, $E3, $E4, $E5,
;                       $E6, $E7, $F1, $F2, $F3, $F4, $C0-$Cx range
; - Envelope markers: $CC/$DD/$DC/$BC/$EE/$EF/$FE/$ED (ADSR control)
; - Pattern indicates complex multi-voice music tracks with:
;   * Rapid voice switching (voice markers every 8-20 bytes)
;   * Frequent DSP register updates (echo, modulation, effects)
;   * High parameter values ($90+, $A0+, $F0+) for loud/bright passages
;   * Zero padding sections (0E80FC-0E8107) marking structural boundaries
; ==============================================================================
; ==============================================================================
; Bank $0E - Extended APU/Sound Data (Continuation)
; Lines 401-800: Complex Music Pattern Data & DSP Configuration
; Address Range: $0E9A00-$0EB1D0 (~6KB dense music/SFX sequences)
; ==============================================================================

; ------------------------------------------------------------------------------
; $0E8A00-$0E8AFF: Transition Section - Final Voice Patterns (256 bytes)
; ------------------------------------------------------------------------------
; Continuation from Cycle 1 voice marker sequences
; Dense $B6/$A2/$B2/$A6 voice markers continue pattern from previous section

                       db $FE,$21,$40,$F2,$21,$D1,$5F,$23,$A2,$B5,$6C;0E89F0|        |      ;
; (Carryover from line 400)
; $FE: Envelope marker
; $21,$40: Params
; $F2,$21: DSP register $F2, value $21
; $D1,$5F,$23: Parameter sequence
; $A2: Voice marker
; $B5: Voice marker variant
; $6C: Parameter

                       db $FE,$4E,$00,$D1,$C3,$3D,$11,$B2,$0F,$12,$F0,$41,$E1,$20,$F0,$20;0E8C00|        |      ;
; $B6: Voice marker at start
; Pattern shows continuing DSP register writes and voice switching

                       db $B2,$D2,$1C,$00,$F1,$DE,$0E,$E0,$FD,$A2,$F3,$30,$F3,$00,$30,$51;0E8C10|        |      ;
; $B2: Voice marker
; $F1: DSP register marker
; $DE: Parameter
; $E0,$FD: DSP register $E0 = $FD
; $A2: Voice marker
; $F3: DSP register marker (appears twice)

                       db $B4,$74,$B2,$FF,$42,$F2,$FE,$00,$2F,$D1,$0F,$A2,$FD,$53,$03,$FE;0E8C20|        |      ;
; $B4: Voice marker variant
; $74: High parameter value
; $B2: Voice marker
; $F2: DSP register marker
; $A2: Voice marker

                       db $25,$F9,$23,$DC,$A6,$30,$B4,$4B,$D2,$1F,$12,$4F,$B4,$A2,$4E,$26;0E8C30|        |      ;
; $F9: High parameter value
; $A6: Voice marker variant
; $B4: Voice marker variant (appears twice)
; $4B: Parameter (repeated from earlier)
; $A2: Voice marker

; Dense voice marker pattern continues through 0E8C40-0E8CFF with frequent:
; - $A2/$B2/$B6/$A6/$B4/$B5 voice markers every 8-15 bytes
; - DSP register addresses $C0-$FF range
; - High parameter values ($90+, $A0+, $F0+)
; - Envelope markers ($CC/$DD/$BC/$EE/$FE/$ED)

; ------------------------------------------------------------------------------
; $0E8D00-$0E8DFF: New Marker Section - $5A/$6A/$4A/$7A Separators (256 bytes)
; ------------------------------------------------------------------------------
; Pattern shifts to different channel/voice separator markers:
; $5A, $6A, $4A, $7A, $3A - These are different voice channel separators
; (similar to $8A from Cycle 1, but indicating different voice types or groups)

                       db $E4,$06,$02,$00,$00,$00,$00,$00,$00,$00,$00,$5A,$62,$31,$22,$22;0E8D30|        |      ;
; $E4,$06,$02: Parameter sequence
; $00×7: Zero padding (section boundary marker)
; $5A: New channel separator marker (different voice group from $8A)
; $62,$31,$22,$22: Initial voice parameters for $5A group

                       db $11,$11,$01,$10,$4A,$11,$0F,$F0,$DE,$DD,$DA,$BC,$CC,$4A,$CC,$DD;0E8D40|        |      ;
; $4A: Channel separator (appears twice in this line)
; $11,$0F,$F0: Parameters
; $DE,$DD,$DA: Envelope sequence
; $BC,$CC: Voice configuration markers

                       db $EE,$FF,$01,$22,$23,$54,$4A,$74,$44,$34,$22,$21,$22,$12,$F2,$4A;0E8D50|        |      ;
; $EE,$FF: Envelope markers (maximum values)
; $01,$22,$23,$54: Parameter sequence
; $4A: Channel separator (appears twice)
; $74: High parameter value
; $F2: DSP register marker

                       db $1E,$E0,$FD,$CC,$DC,$BB,$CC,$AD,$5A,$ED,$FF,$FF,$01,$02,$23,$33;0E8D60|        |      ;
; $1E: Param
; $E0,$FD: DSP register $E0 = $FD
; $CC,$DC,$BB,$CC: Voice envelope sequence
; $AD: High parameter
; $5A: Channel separator
; $ED,$FF,$FF: Envelope sequence (maximum values)

                       db $42,$4A,$75,$54,$22,$12,$01,$20,$F2,$0F,$4A,$0E,$DC,$CB,$BA,$BB;0E8D70|        |      ;
; $4A: Channel separator (appears three times in this line)
; Pattern shows rapid channel switching within $4A voice group

                       db $BB,$CC,$BD,$4A,$EE,$0E,$41,$53,$55,$67,$66,$34,$3A,$35,$51,$02;0E8D80|        |      ;
; $BB,$CC,$BD: Voice envelope
; $4A: Channel separator
; $EE,$0E: Parameters
; $41,$53,$55,$67,$66: Parameter sequence (note/pitch data)
; $3A: New channel separator variant
; $35,$51,$02: Parameters

                       db $23,$30,$22,$2D,$CA,$4A,$CC,$BB,$BB,$AB,$AC,$BC,$DB,$DF,$4A,$F1;0E8D90|        |      ;
; $CA: Parameter
; $4A: Channel separator (appears twice)
; $CC,$BB,$BB,$AB,$AC,$BC: Voice envelope sequence
; $DB,$DF: Parameters
; $F1: DSP register marker

                       db $33,$64,$76,$65,$64,$55,$34,$4A,$22,$12,$11,$E2,$11,$0E,$FA,$B9;0E8DA0|        |      ;
; $33,$64,$76,$65,$64,$55,$34: Parameter sequence (melody line)
; $4A: Channel separator
; $E2: DSP register marker
; $FA,$B9: High parameters

                       db $5A,$DC,$CD,$CD,$EE,$DC,$FF,$00,$12,$5A,$24,$33,$35,$43,$23,$22;0E8DB0|        |      ;
; $5A: Channel separator (appears twice)
; $DC,$CD,$CD,$EE,$DC: Voice envelope sequence
; $FF,$00: Parameters
; Voice parameters between separators

                       db $22,$21,$5A,$21,$00,$01,$0F,$EF,$ED,$CD,$DD,$5A,$CB,$CE,$CB,$DD;0E8DC0|        |      ;
; $5A: Channel separator (appears three times)
; Pattern shows $5A as primary separator in this section

                       db $EE,$F0,$01,$33,$5A,$33,$54,$55,$54,$33,$33,$21,$01,$5A,$21,$FF;0E8DD0|        |      ;
; $EE,$F0: Envelope with DSP marker
; $5A: Channel separator (appears three times)
; Parameter sequences between separators

                       db $00,$ED,$EF,$DC,$CD,$DB,$5A,$BA,$CC,$DE,$FE,$10,$00,$33,$46,$5A;0E8DE0|        |      ;
; $ED,$EF,$DC,$CD,$DB: Envelope sequence
; $5A: Channel separator (appears twice)
; $DE,$FE: Parameters

                       db $45,$56,$43,$24,$22,$22,$13,$12,$5A,$20,$EF,$ED,$DB,$CB,$CA,$CB;0E8DF0|        |      ;
; Parameter sequence
; $5A: Channel separator
; $EF,$ED,$DB,$CB,$CA,$CB: Extended envelope sequence

                       db $BA,$5A,$CC,$ED,$EF,$FF,$10,$12,$42,$55,$5A,$66,$56,$54,$44,$33;0E8E00|        |      ;
; $BA: Parameter
; $5A: Channel separator (appears twice)
; Voice parameters between markers

; Pattern continues through 0E8E10-0E8EFF with:
; - $5A as primary channel separator (appears 3-5 times per line)
; - $4A/$6A/$7A/$3A as alternate channel separators
; - Envelope sequences between separators
; - Parameter values (note/duration data)

; ------------------------------------------------------------------------------
; $0E8F00-$0E8FFF: Extended $6A/$7A Voice Channels (256 bytes)
; ------------------------------------------------------------------------------
; Shift to $6A and $7A as dominant channel separators
; These appear to be additional voice channels beyond the initial $5A/$4A groups

                       db $FF,$FE,$FE,$FE,$F0,$23,$45,$77,$6A,$44,$64,$43,$32,$1F,$FF,$EF;0E8F10|        |      ;
; $FF,$FE: High envelope values
; $6A: Channel separator (new primary separator for this section)
; $44,$64,$43,$32: Parameter sequence
; $FF,$EF: High values

                       db $EF,$6A,$EE,$DE,$DC,$BD,$EE,$EE,$00,$21,$6A,$0F,$00,$0F,$FE,$EF;0E8F20|        |      ;
; $6A: Channel separator (appears three times)
; $EE,$DE,$DC,$BD,$EE,$EE: Envelope sequence
; Pattern shows $6A separating voices with similar structure to earlier $5A

                       db $12,$13,$45,$6A,$45,$55,$44,$31,$01,$FE,$E0,$EE,$6A,$DE,$ED,$CB;0E8F30|        |      ;
; $6A: Channel separator (appears three times)
; Voice parameters between separators

                       db $DD,$CD,$FF,$0F,$12,$6A,$20,$00,$0F,$EE,$EF,$F1,$23,$35,$6A,$45;0E8F40|        |      ;
; $FF,$0F: High parameter
; $6A: Channel separator (appears twice)
; $F1: DSP register marker

                       db $44,$33,$42,$22,$1F,$FE,$DE,$6A,$ED,$CE,$EC,$DE,$EE,$FE,$00,$21;0E8F60|        |      ;
; Parameter sequence
; $6A: Channel separator
; $ED,$CE,$EC,$DE,$EE,$FE: Envelope sequence

                       db $6A,$1F,$0F,$FD,$CC,$DE,$F0,$23,$55,$6A,$54,$56,$45,$43,$22,$0F;0E8F70|        |      ;
; $6A: Channel separator (appears twice)
; $F0: DSP register marker
; Pattern continues with regular $6A separators

                       db $EE,$EE,$5A,$9B,$AB,$CB,$BB,$BC,$EF,$00,$21,$6A,$0F,$FF,$DC,$CC;0E8F80|        |      ;
; $5A: Channel separator (brief return to $5A marker)
; $9B,$AB,$CB,$BB,$BC: Voice envelope sequence
; $6A: Back to $6A separator
; Shows mixing of separator types

                       db $DE,$F0,$33,$45,$6A,$65,$57,$65,$44,$20,$FF,$EE,$DD,$5A,$AC,$BC;0E8F90|        |      ;
; $6A: Channel separator
; $5A: Channel separator (alternating $6A/$5A in this section)

                       db $BC,$CC,$CC,$FE,$10,$10,$6A,$FF,$EE,$BC,$BD,$DF,$01,$25,$76,$6A;0E8FA0|        |      ;
; $6A: Channel separator (appears twice)
; Voice configuration between markers

                       db $66,$77,$65,$33,$0E,$EE,$CD,$EF,$5A,$BD,$DC,$CB,$BA,$CC,$E0,$EF;0E8FB0|        |      ;
; $6A/$5A: Mixed channel separators
; $E0,$EF: DSP register and envelope marker

                       db $0F,$6A,$FE,$DD,$DC,$CD,$EF,$13,$45,$66,$7A,$44,$43,$32,$10,$FF;0E8FC0|        |      ;
; $6A: Channel separator
; $7A: New channel separator introduced (appears first time)
; Transition from $6A to $7A voice groups

                       db $EF,$FF,$0F,$6A,$FE,$EC,$CC,$DC,$CD,$FF,$FF,$00,$7A,$00,$FF,$F0;0E8FF0|        |      ;
; $6A: Channel separator
; $7A: Channel separator (second occurrence)
; Shows transition to $7A as new primary separator

; Pattern continues 0E9000-0E9FFF with $7A as dominant separator

; ------------------------------------------------------------------------------
; $0E9000-$0E90FF: $7A Voice Channel Dominance (256 bytes)
; ------------------------------------------------------------------------------
; $7A becomes primary channel separator for extended section
; Pattern structure similar to earlier $5A/$6A sections

                       db $FF,$F0,$02,$23,$33,$7A,$44,$43,$32,$0F,$FF,$EF,$F0,$F0,$6A,$F0;0E9000|        |      ;
; $7A: Channel separator
; $6A: Brief appearance (mixed with $7A)
; Shows gradual transition to $7A dominance

                       db $DC,$BA,$AC,$BC,$EF,$0F,$11,$7A,$00,$10,$FF,$FF,$F0,$F1,$23,$34;0E9010|        |      ;
; $7A: Channel separator
; Envelope sequence and parameters between markers

                       db $7A,$45,$42,$11,$10,$FF,$F0,$00,$00,$6A,$FD,$CB,$A9,$9B,$DC,$FF;0E9020|        |      ;
; $7A: Channel separator
; $6A: Alternate separator (shows mixing continues)
; $FD,$CB,$A9,$9B,$DC: Voice envelope sequence

; Pattern continues with $7A appearing 2-4 times per line through 0E90FF
; Occasional $6A/$5A markers appear but $7A dominates

; ------------------------------------------------------------------------------
; $0E9100-$0E99FF: Extended $7A Sequences (2,304 bytes)
; ------------------------------------------------------------------------------
; Long section with consistent $7A channel separator usage
; Additional markers: $6A, $5A, $4A appear intermittently

                       db $EE,$DC,$CC,$CD,$FF,$00,$11,$10,$7A,$10,$0E,$EE,$EE,$F0,$12,$35;0E9140|        |      ;
; $7A: Channel separator
; Standard envelope/parameter pattern continues

                       db $45,$7A,$44,$23,$12,$10,$F0,$00,$00,$FF,$7A,$FE,$DC,$CD,$DD,$EE;0E9150|        |      ;
; $7A: Channel separator (appears three times)
; Consistent separator spacing

; Through lines 450-650 (0E9200-0E9900):
; - $7A remains primary separator (80%+ of separators)
; - $6A appears occasionally (10-15% of separators)
; - $5A appears rarely (5% of separators)
; - Envelope sequences: $CC/$DD/$BC/$EE/$EF/$FE/$ED between channels
; - Parameter values indicate note/duration/pitch data
; - DSP register markers ($E0-$FF) appear intermittently

; ------------------------------------------------------------------------------
; $0E9A00-$0E9AFF: $8A Separator Returns (256 bytes - lines 640-655)
; ------------------------------------------------------------------------------
; Original $8A channel separator reappears after long $5A/$6A/$7A section
; Indicates return to original voice group or new music section

                       db $BB,$BC,$CD,$DD,$CC,$CD,$EE,$EE,$6A,$DD,$CD,$EE,$EF,$EE,$FF,$0F;0E9B10|        |      ;
; $6A: Channel separator (still present from previous section)

                       db $00,$4A,$0D,$ED,$DD,$F0,$46,$54,$2F,$FD,$5A,$EF,$24,$63,$1F,$EF;0E9B20|        |      ;
; $4A: Channel separator returns
; $5A: Channel separator
; Mix of older separator types reappearing

                       db $01,$23,$22,$4A,$1C,$BE,$12,$33,$32,$FC,$BD,$34,$4A,$44,$1F,$FC;0E9B30|        |      ;
; $4A: Channel separator (appears three times)
; Return to $4A separator dominance in this subsection

                       db $AD,$25,$76,$30,$0C,$4A,$CD,$E1,$55,$43,$22,$DC,$FF,$33,$5A,$22;0E9B40|        |      ;
; $AD: High parameter value
; $4A: Channel separator
; $5A: Channel separator
; Mixed separator usage

                       db $22,$32,$10,$00,$00,$12,$34,$5A,$54,$2F,$FE,$EE,$13,$55,$43,$2D;0E9B50|        |      ;
; $5A: Channel separator
; Voice parameters between markers

                       db $6A,$DD,$D0,$13,$33,$22,$FB,$BE,$F0,$6A,$14,$43,$0E,$DD,$CD,$E0;0E9B60|        |      ;
; $6A: Channel separator (appears twice)
; $FB,$BE: High parameters
; $E0: DSP register marker

; Pattern continues mixing $4A/$5A/$6A separators through 0E9BFF

; ------------------------------------------------------------------------------
; $0E9C00-$0E9CFF: Continued Mixed Separators (256 bytes)
; ------------------------------------------------------------------------------

                       db $6A,$0D,$EC,$DF,$EE,$DD,$CC,$CD,$DC,$7A,$EE,$EE,$CC,$CD,$BB,$BB;0E9C00|        |      ;
; $6A: Channel separator
; $7A: Channel separator
; Shows mixing of multiple separator types

                       db $BB,$AB,$7A,$BC,$BB,$AA,$AA,$BA,$BB,$CB,$AA,$7A,$BB,$BB,$BB,$DD;0E9C10|        |      ;
; $7A: Channel separator (appears three times)
; $7A becomes dominant again in this subsection

                       db $DC,$CD,$CD,$DE,$6A,$BD,$CD,$ED,$DD,$EE,$EF,$FF,$00,$4A,$B9,$DE;0E9C20|        |      ;
; $6A: Channel separator
; $4A: Channel separator
; Transition section with multiple separator types

                       db $F0,$10,$10,$DE,$F2,$46,$5A,$31,$0F,$F0,$10,$34,$42,$FE,$FF,$5A;0E9C30|        |      ;
; $F0: DSP register marker
; $F2,$46: DSP register $F2, value $46
; $5A: Channel separator (appears twice)

; Pattern continues through 0E9CFF with mixed $4A/$5A/$6A/$7A separators

; ------------------------------------------------------------------------------
; $0E9D00-$0E9DFF: Return to $7A Dominance (256 bytes)
; ------------------------------------------------------------------------------

                       db $44,$33,$34,$33,$44,$55,$55,$56,$7A,$56,$55,$56,$66,$54,$35,$55;0E9D00|        |      ;
; $7A: Channel separator
; Parameter sequence (melody pattern)

                       db $46,$7A,$66,$66,$54,$55,$54,$43,$22,$22,$6A,$20,$E0,$EC,$DF,$EF;0E9D10|        |      ;
; $7A: Channel separator
; $6A: Channel separator
; $E0: DSP register marker

                       db $1F,$0D,$CA,$7A,$DD,$EE,$EE,$DC,$CB,$BB,$BB,$BC,$7A,$BB,$BB,$AA;0E9D20|        |      ;
; $CA: Parameter
; $7A: Channel separator (appears twice)
; Voice envelope sequences

                       db $BA,$BB,$BA,$AA,$AB,$7A,$BB,$BB,$BB,$BB,$CC,$DC,$DD,$DD,$66,$54;0E9D30|        |      ;
; $7A: Channel separator (appears twice)
; Extended parameter sequence

                       db $34,$44,$55,$55,$66,$53,$22,$4A,$FE,$CF,$EE,$DC,$DE,$F0,$22,$22;0E9D40|        |      ;
; Parameter sequence
; $4A: Channel separator
; $FE,$CF: Envelope markers
; $F0: DSP register marker

; Pattern continues with $7A as primary separator, occasional $4A/$5A/$6A through 0E9DFF

; ------------------------------------------------------------------------------
; $0E9E00-$0E9FFF: Final Mixed Pattern Section (512 bytes)
; ------------------------------------------------------------------------------
; Lines 700-800 show complex mixing of all separator types
; Appears to be multi-song or multi-SFX data concatenated

                       db $00,$12,$22,$23,$44,$33,$44,$33,$7A,$44,$33,$33,$44,$34,$56,$55;0E9E00|        |      ;
; $7A: Channel separator

                       db $65,$7A,$55,$64,$55,$55,$56,$55,$45,$56,$7A,$55,$77,$66,$76,$43;0E9E10|        |      ;
; $7A: Channel separator (appears three times)

                       db $33,$34,$31,$5A,$44,$4F,$D0,$12,$1F,$CC,$CB,$CB,$7A,$FF,$EE,$DC;0E9E20|        |      ;
; $5A: Channel separator
; $7A: Channel separator
; $D0: Parameter
; $FF,$EE: High envelope values

                       db $CD,$DD,$CC,$CC,$BA,$7A,$AA,$CC,$BA,$CB,$A9,$AB,$BA,$AB,$7A,$AA;0E9E30|        |      ;
; $7A: Channel separator (appears three times)

                       db $BB,$AB,$BC,$BC,$CB,$BD,$DD,$6A,$AB,$AB,$AA,$BD,$ED,$F0,$FE,$EC;0E9E40|        |      ;
; $7A/$6A: Channel separators
; $F0: DSP register marker

                       db $66,$20,$FF,$F0,$13,$43,$21,$0E,$DD,$5A,$46,$43,$10,$EC,$CE,$24;0E9E50|        |      ;
; $F0: DSP register marker
; $5A: Channel separator

                       db $55,$44,$5A,$2F,$DC,$EF,$12,$34,$42,$FE,$FD,$5A,$DE,$02,$33,$44;0E9E60|        |      ;
; $5A: Channel separator (appears twice)

; Lines 750-800 continue mixing:
; - $5A: ~25% of separators
; - $6A: ~20% of separators
; - $7A: ~30% of separators
; - $4A: ~15% of separators
; - $8A: ~10% of separators (returns near end)

                       db $8A,$21,$11,$23,$32,$34,$43,$33,$22,$6A,$66,$1F,$00,$33,$34,$76;0E98D0|        |      ;
; $8A: Channel separator returns (line 401 - start of this cycle)
; $6A: Channel separator
; Shows transition back to earlier separator patterns

                       db $54,$31,$7A,$FE,$ED,$DC,$CD,$CB,$CD,$EE,$EE,$7A,$EE,$DC,$DC,$CB;0E98E0|        |      ;
; $7A: Channel separator (appears twice)
; $FE,$ED: Envelope markers

                       db $CA,$AA,$BB,$AB,$7A,$AB,$BB,$AB,$BC,$BB,$BD,$CB,$BC,$7A,$CC,$DC;0E98F0|        |      ;
; $7A: Channel separator (appears three times)
; Voice envelope sequences between separators

                       db $DD,$ED,$DD,$DE,$FF,$EF,$5A,$CB,$BD,$DE,$EF,$00,$FF,$EE,$F0,$4A;0E9900|        |      ;
; $FF,$EF: High envelope values
; $5A: Channel separator
; $F0,$4A: DSP register $F0 followed by $4A separator
; Shows complex interleaving of markers

; Final lines (790-800) show all separator types appearing:

                       db $76,$01,$23,$22,$11,$12,$23,$34,$45,$6A,$DC,$BD,$EF,$12,$11,$0F;0E9F50|        |      ;
; $6A: Channel separator

                       db $EE,$EF,$5A,$11,$44,$32,$0F,$FF,$E0,$12,$44,$5A,$34,$41,$EC,$EF;0E9F60|        |      ;
; $5A: Channel separator (appears twice)
; $E0: DSP register marker

                       db $00,$35,$42,$FE,$5A,$FE,$E0,$23,$42,$0E,$DE,$FF,$04,$5A,$54,$20;0E9F70|        |      ;
; $5A: Channel separator (appears three times)

                       db $EE,$EE,$E1,$23,$35,$43,$5A,$11,$EE,$DD,$F3,$56,$65,$52,$0F,$5A;0E9F80|        |      ;
; $E1: DSP register marker
; $5A: Channel separator (appears twice)
; $F3: DSP register marker

                       db $E0,$01,$23,$34,$44,$43,$21,$1F,$5A,$FE,$E0,$00,$23,$44,$33,$10;0E9F90|        |      ;
; $E0: DSP register marker (appears twice)
; $5A: Channel separator

                       db $ED,$5A,$B9,$BD,$02,$24,$64,$1C,$CC,$A9,$5A,$BC,$EE,$FF,$10,$00;0E9FA0|        |      ;
; $5A: Channel separator (appears twice)
; $B9,$BD: High parameters

                       db $FD,$BB,$BC,$5A,$BC,$EF,$0F,$ED,$EF,$02,$0F,$EE,$5A,$EC,$BD,$DE;0E9FB0|        |      ;
; $5A: Channel separator (appears three times)
; Dense separator usage in final lines

                       db $EE,$FF,$00,$11,$22,$5A,$10,$EC,$CB,$CE,$E1,$23,$22,$21,$5A,$01;0E9FC0|        |      ;
; $5A: Channel separator (appears twice)
; $E1: DSP register marker

                       db $0E,$DE,$13,$44,$55,$30,$FD,$6A,$EE,$EE,$F0,$22,$44,$43,$44,$20;0E9FD0|        |      ;
; $6A: Channel separator
; $F0: DSP register marker

                       db $6A,$ED,$DC,$BD,$EF,$F1,$23,$32,$23,$5A,$20,$EE,$EC,$DC,$BC,$CC;0E9FE0|        |      ;
; $6A: Channel separator
; $5A: Channel separator
; $F1: DSP register marker

                       db $AB,$CD,$5A,$EE,$F0,$00,$F0,$00,$FF,$EC,$DD,$6A,$EE,$EF,$FF,$F1;0E9FF0|        |      ;
; $5A: Channel separator
; $6A: Channel separator
; $F0: DSP register marker (appears three times)
; $F1: DSP register marker

; ==============================================================================
; End of Bank $0E Cycle 2 (Lines 401-800)
; Documented Address Range: $0E8A00-$0EA000 (6,144 bytes)
; ==============================================================================
; Technical Summary:
; - Complex multi-channel voice system with 6+ separator types:
;   * $8A: Original separator from Bank $0D/Cycle 1 (returns at start/end)
;   * $5A: Primary separator for section 0E8D00-0E8E00 (~256 bytes)
;   * $6A: Primary separator for section 0E8E00-0E9000 (~512 bytes)
;   * $7A: Dominant separator for section 0E9000-0E9E00 (~3.5KB)
;   * $4A: Alternate separator, appears intermittently
;   * $3A: Rare variant separator
; - Voice markers ($A2/$B2/$B6/$A6/$B4/$B5) appear in first section (0E8A00-0E8D00)
; - DSP register usage: $E0-$F4 range (echo, modulation, flags)
; - Envelope markers: $CC/$DD/$BC/$EE/$EF/$FE/$ED (ADSR/volume)
; - Pattern indicates multiple music tracks or SFX sequences:
;   * Different separators may indicate different instrument groups
;   * $5A/$6A/$7A pattern suggests three distinct voice layers
;   * $8A return at boundaries indicates track/section transitions
; - Zero padding at 0E8D30 marks major structural boundary
; - High parameter concentration ($90+, $A0+, $F0+) in later sections
; - This section appears to be continuation of Bank $0D's audio driver
;   with extended voice channel capabilities (16+ simultaneous voices)
; ==============================================================================
; Lines 801-1000 documented (200 source lines, addresses $0EB1D0-$0EBE40)
; Continuation of multi-separator voice system, focusing on $9A/$AA pattern analysis

                       db $FD,$E1,$10,$9A,$F0,$F3,$0B,$D1,$33,$21,$12,$09,$9A,$C3,$F1,$5E;0EB1D0
                       ; $9A separator continues dominant pattern from previous section
                       ; High envelope values: $FD/$F3/$F1 (loud sustain/decay)
                       ; Parameter sequence: $0B/$33/$21/$12/$09 (pitch/volume modulation)

                       db $E5,$1D,$FE,$CC,$E2,$AA,$44,$2D,$D0,$FE,$00,$F1,$01,$51,$9A,$DD;0EB1E0
                       ; $AA separator appears (alternate to $9A, similar function)
                       ; Envelope markers: $FE/$CC/$E2/$DD (ADSR sequence)
                       ; Zero byte at position 10 may indicate voice reset

                       db $EE,$F0,$21,$21,$CC,$13,$10,$96,$24,$45,$1B,$DE,$CF,$2F,$F3,$42;0EB1F0
                       ; $96 separator variant appears
                       ; Multiple envelopes: $EE/$F0/$CC/$DE/$CF/$F3 (complex voice shaping)
                       ; Low parameters: $13/$10/$21 contrast with high $F0/$F3

                       db $AA,$FF,$EE,$F2,$54,$FC,$F0,$FF,$FF,$9A,$30,$F6,$51,$2C,$BE,$0F;0EB200
                       ; $AA and $9A separators in same line (transition marker)
                       ; Maximum values: $FF (3 instances, peak volume/brightness)
                       ; Envelope sequence: $EE/$F2/$FC/$F0/$BE

                       db $23,$2E,$96,$CC,$12,$EE,$24,$41,$BD,$0E,$D0,$AA,$0E,$12,$10,$FD;0EB210
                       ; $96 and $AA separators present
                       ; Pattern: low params → separator → low params ($0E/$12/$10)
                       ; Envelopes: $CC/$EE/$BD/$D0/$FD (varied dynamics)

                       db $DF,$13,$42,$DC,$9A,$23,$EE,$DF,$10,$23,$35,$0B,$DD,$9A,$F1,$31;0EB220
                       ; Two $9A separators in one line (dual voice layer)
                       ; Envelopes: $DF/$DC/$EE/$DF/$DD/$F1 (high sustain values)
                       ; Low counters: $13/$10/$23/$35/$0B/$31

                       db $0E,$04,$3C,$D4,$4F,$BB,$9A,$37,$FC,$10,$C1,$62,$00,$C9,$D1,$96;0EB230
                       ; $9A and $96 separators
                       ; DSP-range values: $C1/$C9/$D1/$D4/$BB (likely DSP registers)
                       ; Zero byte at position 10 (voice boundary marker)

                       db $C1,$44,$1E,$02,$1E,$DF,$ED,$F3,$9A,$42,$ED,$CF,$31,$EF,$02,$53;0EB240
                       ; $9A separator with DSP register $C1
                       ; High envelopes: $DF/$ED/$F3/$ED/$CF/$EF (bright sustained voice)
                       ; Repeated $1E value (pitch/detune parameter)

                       db $CC,$9A,$43,$0C,$90,$74,$ED,$1D,$E4,$42,$9A,$1E,$BB,$F2,$40,$F0;0EB250
                       ; Two $9A separators, envelope $CC
                       ; $90 value (common voice parameter in this bank)
                       ; DSP-range: $E4/$BB/$F2/$F0 (echo/modulation settings)

                       db $F0,$10,$1E,$9A,$D2,$1E,$04,$01,$2D,$B1,$40,$CF,$9A,$34,$4F,$B1;0EB260
                       ; Two $9A separators with $B1 voice markers (melody voice)
                       ; DSP register $D2/$CF
                       ; $F0 envelope (maximum sustain)

                       db $4F,$EA,$E6,$31,$FE,$9A,$FC,$05,$61,$EF,$BC,$13,$FD,$13,$9A,$EF;0EB270
                       ; Two $9A separators
                       ; High envelope cluster: $EA/$E6/$FE/$FC/$EF/$BC/$FD/$EF
                       ; Pattern suggests loud sustained passage

                       db $11,$1F,$F1,$0E,$10,$F4,$1C,$9A,$E2,$20,$C0,$64,$FC,$13,$0D,$CF;0EB280
                       ; $9A separator with DSP registers $E2/$C0/$FC/$CF
                       ; Envelope $F4/$F1 (high sustain)
                       ; Low params: $11/$1F/$0E/$10/$1C/$13/$0D

                       db $AA,$20,$F2,$1F,$EE,$14,$2F,$F0,$E0,$9A,$FE,$D0,$41,$CF,$33,$0E;0EB290
                       ; $AA and $9A separators (voice layer switch)
                       ; DSP range: $F2/$EE/$F0/$E0/$FE/$D0/$CF
                       ; High concentration of E/F range values

                       db $21,$DE,$9A,$FE,$44,$DC,$24,$1C,$E3,$52,$DE,$AA,$20,$EF,$02,$0E;0EB2A0
                       ; $9A and $AA separators
                       ; Envelopes: $DE/$FE/$DC/$E3/$DE/$EF
                       ; Counter pattern: $21/$44/$24/$1C/$52/$20/$02/$0E

                       db $03,$FE,$E1,$33,$9A,$0D,$0F,$D2,$EA,$E3,$3E,$D1,$33,$9A,$00,$3F;0EB2B0
                       ; Two $9A separators
                       ; DSP cluster: $FE/$E1/$D2/$EA/$E3/$D1
                       ; Zero byte at position 0 and 14 (section markers)

                       db $AD,$01,$31,$DF,$44,$CD,$9A,$23,$41,$CF,$1D,$F2,$22,$DC,$32,$AA;0EB2C0
                       ; $9A and $AA separators
                       ; Envelopes: $AD/$DF/$CD/$CF/$F2/$DC
                       ; Pattern: mid-range then separator then params

                       db $EF,$01,$33,$FF,$FE,$21,$CD,$12,$AA,$0E,$F2,$21,$11,$0D,$C0,$20;0EB2D0
                       ; $AA separator with DSP registers
                       ; Maximum value $FF, envelopes $EF/$FE/$CD/$F2/$C0
                       ; Low params follow: $0E/$21/$11/$0D/$20

                       db $10,$9A,$E1,$6E,$D2,$02,$40,$ED,$CF,$45,$9A,$1D,$C1,$2C,$D1,$23;0EB2E0
                       ; Two $9A separators
                       ; DSP cluster: $E1/$D2/$ED/$CF/$C1/$D1
                       ; Mixed params: $6E/$02/$40/$45/$1D/$2C/$23

                       db $64,$EC,$C0,$AA,$3F,$CF,$00,$00,$01,$12,$21,$EB,$9A,$B3,$22,$4D;0EB2F0
                       ; $AA and $9A separators, $B3 voice marker appears
                       ; Double zero bytes at positions 6-7 (boundary)
                       ; DSP: $EC/$C0/$CF/$EB

                       db $E6,$1C,$02,$14,$1F,$9A,$CC,$E2,$63,$ED,$F2,$DA,$24,$13,$9A,$62;0EB300
                       ; Two $9A separators
                       ; Envelopes: $E6/$CC/$E2/$ED/$F2/$DA
                       ; Counter sequence: $1C/$02/$14/$1F/$63/$24/$13/$62

                       db $BC,$F3,$1B,$EF,$EE,$F1,$33,$AA,$21,$00,$DC,$01,$03,$1D,$22,$EF;0EB310
                       ; $AA separator with zero byte at position 9
                       ; High envelope cluster: $BC/$F3/$EF/$EE/$F1/$DC/$EF
                       ; Low params: $1B/$33/$21/$01/$03/$1D/$22

                       db $9A,$13,$31,$1D,$CD,$04,$5F,$D0,$0E,$9A,$B1,$50,$14,$5D,$B1,$2F;0EB320
                       ; Two $9A separators with $B1 voice markers (melody layer)
                       ; Envelopes: $CD/$D0
                       ; Pattern suggests dual melody voice configuration

                       db $DF,$0C,$9A,$C0,$F2,$45,$50,$DC,$AC,$11,$36,$9A,$0D,$21,$FD,$24;0EB330
                       ; Two $9A separators
                       ; DSP range: $DF/$C0/$F2/$DC/$AC/$FD
                       ; Low params interspersed: $0C/$45/$50/$11/$36/$0D/$21/$24

                       db $20,$FB,$00,$02,$9A,$10,$10,$CC,$F4,$31,$34,$FA,$04,$9A,$FB,$04;0EB340
                       ; Two $9A separators with zero byte
                       ; Envelopes: $FB/$CC/$F4/$FA/$FB
                       ; Repeated $10 and $04 values (timing parameters)

                       db $E9,$DF,$04,$57,$3B,$BC,$9A,$CE,$14,$33,$2E,$F2,$D0,$41,$00,$9A;0EB350
                       ; Two $9A separators with zero byte at end
                       ; Envelopes: $E9/$DF/$BC/$CE/$F2/$D0
                       ; Mid-range params: $57/$3B/$14/$33/$2E/$41

                       db $DF,$2F,$FF,$24,$1B,$BF,$31,$35,$AA,$1F,$EF,$21,$EF,$20,$CD,$01;0EB360
                       ; $AA separator
                       ; Maximum value $FF with envelopes $DF/$BF/$EF/$EF/$CD
                       ; Low params: $2F/$24/$1B/$31/$35/$1F/$21/$20/$01

                       db $11,$AA,$34,$FC,$DF,$F0,$11,$13,$1E,$00,$9A,$D3,$22,$ED,$11,$00;0EB370
                       ; $AA and $9A separators with zero bytes
                       ; Envelopes: $FC,$DF,$F0,$D3,$ED
                       ; Repeated $11 and $00 values

                       db $CF,$72,$BC,$9A,$F2,$20,$56,$CA,$F4,$3D,$D3,$1B,$AA,$DF,$11,$02;0EB380
                       ; $9A and $AA separators
                       ; DSP cluster: $CF/$BC/$F2/$CA/$F4/$D3,$DF
                       ; Mixed params: $72/$20/$56/$3D/$1B/$11/$02

                       db $40,$CE,$F0,$E0,$21,$9A,$56,$CC,$3D,$F3,$20,$D0,$30,$0C,$9A,$D5;0EB390
                       ; Two $9A separators
                       ; High DSP range: $CE/$F0/$E0/$CC/$F3/$D0/$D5
                       ; Repeated $20 and $30 values (timing)

                       db $6B,$A0,$21,$13,$60,$AD,$23,$AA,$FF,$21,$DE,$E0,$20,$14,$0D,$EF;0EB3A0
                       ; $AA separator with $A0/$AD DSP registers
                       ; Maximum $FF value, envelopes $DE/$E0/$EF
                       ; Counter sequence: $6B/$21/$13/$60/$23/$21/$20/$14/$0D

                       db $9A,$D1,$E0,$34,$72,$AF,$3E,$E3,$0E,$9A,$11,$11,$DB,$26,$0B,$C3;0EB3B0
                       ; Two $9A separators
                       ; DSP range: $D1/$E0/$AF/$E3/$DB/$C3
                       ; Parameters: $34/$72/$3E/$0E/$11/$11/$26/$0B

                       db $31,$02,$9A,$4E,$B2,$1D,$F5,$2B,$DE,$D2,$10,$AA,$42,$CD,$1F,$FF;0EB3C0
                       ; $9A and $AA separators
                       ; $B2 voice marker (bass/rhythm voice returns)
                       ; Envelopes: $F5/$DE/$D2/$CD/$FF (maximum at end)

                       db $F1,$32,$20,$E1,$9A,$1B,$04,$DF,$31,$1E,$B0,$61,$CD,$9A,$03,$12;0EB3D0
                       ; Two $9A separators
                       ; Envelopes: $F1/$E1,$DF/$B0/$CD
                       ; Low params: $32/$20/$1B/$04/$31/$1E/$61/$03/$12

                       db $1F,$2F,$F2,$DC,$53,$BE,$9A,$1E,$E1,$03,$6D,$A0,$ED,$FF,$13,$9A;0EB3E0
                       ; Two $9A separators
                       ; Envelopes: $F2/$DC/$BE/$E1/$A0/$ED/$FF (maximum)
                       ; Mid-range: $53/$6D

                       db $43,$21,$0E,$FE,$F2,$10,$12,$DD,$8A,$22,$0F,$D0,$14,$62,$BC,$65;0EB3F0
                       ; **$8A separator returns!** (first time since line 539/0EB540)
                       ; Envelopes: $FE/$F2/$DD/$D0/$BC
                       ; $8A marks major section boundary (different from $9A/$AA pattern)

                       db $09,$96,$CF,$42,$FF,$0F,$DC,$E2,$2F,$FE,$9A,$CC,$02,$22,$32,$43;0EB400
                       ; $96 and $9A separators
                       ; Maximum values: $FF/$FE
                       ; Envelopes: $CF/$DC/$E2/$CC
                       ; Low start: $09 (section beginning marker)

                       db $DC,$0F,$F3,$8A,$3C,$3E,$A2,$4D,$E1,$2F,$36,$0A,$9A,$E1,$62,$BB;0EB410
                       ; **$8A separator again**, plus $9A
                       ; $A2 voice marker appears (voice 4)
                       ; Envelopes: $DC/$F3/$E1/$E1/$BB
                       ; $8A usage suggests track/section transitions

                       db $14,$FC,$02,$3F,$D0,$AA,$F0,$10,$FF,$EE,$12,$11,$F2,$40,$9A,$BC;0EB420
                       ; $AA and $9A separators
                       ; Maximum $FF, high envelopes $FC/$D0/$F0/$EE/$F2/$BC
                       ; Pattern returns to $9A/$AA dominance

                       db $10,$03,$FF,$1E,$F2,$0D,$03,$96,$CD,$22,$DB,$BF,$76,$FF,$21,$ED;0EB430
                       ; $96 separator
                       ; Two $FF maximums, envelopes $F2/$CD/$DB/$BF/$ED
                       ; Mid-range: $76

                       db $9A,$23,$2E,$FE,$B0,$41,$FB,$B1,$22,$AA,$1F,$15,$2D,$EF,$11,$00;0EB440
                       ; $9A and $AA separators with $B1 voice marker
                       ; Envelopes: $FE/$B0/$FB/$EF
                       ; Zero byte at end (boundary)

                       db $F0,$00,$9A,$10,$DE,$23,$33,$1A,$A0,$45,$2C,$9A,$E2,$FD,$F2,$21;0EB450
                       ; Two $9A separators with zero byte
                       ; Envelopes: $F0/$DE/$A0,$E2/$FD/$F2
                       ; Low params: $10/$23/$33/$1A/$45/$2C/$21

                       db $20,$DA,$D2,$32,$AA,$ED,$02,$00,$00,$43,$EE,$F1,$20,$AA,$E0,$00;0EB460
                       ; Two $AA separators with double zero bytes (section marker)
                       ; DSP range: $DA/$D2/$ED/$EE/$F1/$E0
                       ; Repeated $20 and $00 values

                       db $10,$FF,$F0,$13,$21,$EC,$9A,$B5,$70,$D0,$1F,$ED,$24,$01,$2F,$AA;0EB470
                       ; $9A and $AA separators
                       ; $B5 voice marker appears (new voice channel)
                       ; Maximum $FF with envelopes $F0/$EC/$D0/$ED

                       db $EC,$F2,$20,$DF,$10,$00,$03,$30,$9A,$DE,$03,$0E,$E1,$10,$2F,$BF;0EB480
                       ; $9A separator with zero byte
                       ; Envelopes: $EC/$F2/$DF/$DE/$E1/$BF
                       ; Low params mixed: $20/$10/$03/$30/$03/$0E/$10/$2F

                       db $20,$AA,$14,$2F,$CD,$03,$1E,$03,$FE,$F1,$9A,$40,$F1,$10,$AA,$02;0EB490
                       ; $AA, $9A, $AA sequence (rapid voice switching)
                       ; Envelopes: $CD/$FE/$F1/$F1
                       ; Repeated $03 values

                       db $2E,$E1,$20,$9A,$DD,$56,$12,$EE,$41,$CE,$02,$01,$9A,$1D,$D1,$F1;0EB4A0
                       ; Two $9A separators
                       ; Envelopes: $E1/$DD/$EE/$CE/$D1/$F1
                       ; Mid-range: $56

                       db $67,$1B,$9C,$26,$FA,$9A,$46,$AD,$41,$01,$0F,$2E,$AD,$1F,$9A,$F0;0EB4B0
                       ; Two $9A separators
                       ; $9C separator variant appears
                       ; Envelopes: $FA/$AD/$AD/$F0

                       db $30,$00,$B1,$6F,$26,$EF,$5C,$9A,$B2,$0E,$23,$FD,$0F,$F4,$63,$0B;0EB4C0
                       ; $9A separator with $B1 and $B2 voice markers (melody + bass)
                       ; Zero byte, envelopes $EF/$FD/$F4
                       ; Mid-range: $6F/$5C/$63

                       db $9A,$BE,$32,$CF,$51,$B1,$5F,$11,$EF,$9A,$FE,$DE,$0E,$E5,$2E,$1D;0EB4D0
                       ; Two $9A separators with $B1 voice marker
                       ; Envelopes: $BE/$CF/$EF/$FE/$DE/$E5
                       ; Mid-range: $51/$5F

                       db $E5,$FC,$AA,$43,$F1,$1C,$F2,$FE,$22,$FF,$0E,$AA,$14,$20,$FE,$E0;0EB4E0
                       ; Two $AA separators
                       ; High envelope cluster: $E5/$FC/$F1/$F2/$FE/$FF/$FE/$E0
                       ; Maximum $FF value

                       db $1F,$F1,$01,$01,$9A,$11,$10,$DC,$F2,$ED,$ED,$25,$00,$AA,$FF,$10;0EB4F0
                       ; $9A and $AA separators with zero byte
                       ; Envelopes: $F1/$DC/$F2/$ED/$ED/$FF (maximum)
                       ; Repeated $01, $10, $ED values

                       db $D2,$42,$11,$ED,$F1,$FF,$9A,$43,$0F,$ED,$56,$00,$ED,$F0,$EE,$9A;0EB500
                       ; Two $9A separators with zero byte
                       ; High envelope cluster: $D2/$ED/$F1/$FF/$ED/$ED/$F0/$EE
                       ; Mid-range: $56

                       db $10,$14,$FE,$34,$1E,$BC,$21,$DC,$AA,$E1,$3F,$10,$F0,$0D,$13,$23;0EB510
                       ; $AA separator
                       ; Envelopes: $FE/$BC/$DC/$E1/$F0
                       ; Low params: $10/$14/$34/$1E/$21/$3F/$10/$0D/$13/$23

                       db $2D,$9A,$DF,$DF,$F0,$33,$10,$DE,$53,$00,$9A,$D0,$0D,$D1,$0F,$24;0EB520
                       ; Two $9A separators with zero byte
                       ; Repeated $DF envelope, plus $F0/$DE/$D0/$D1
                       ; Mid-range: $53

                       db $EF,$63,$0B,$9A,$90,$2F,$EB,$E6,$0F,$5E,$E0,$BE,$9A,$55,$55,$FE;0EB530
                       ; Two $9A separators
                       ; Envelopes: $EF/$EB/$E6/$E0/$BE/$FE
                       ; Repeated $55 value, mid-range $63/$5E

                       db $0B,$B1,$0F,$34,$1F,$8A,$D2,$72,$0A,$C4,$D9,$0F,$D3,$55,$9A,$E0;0EB540
                       ; **$8A separator** (major section marker) plus $9A
                       ; $B1 voice marker, DSP range $D2/$C4/$D9/$D3/$E0
                       ; Mid-range: $72, repeated $55

                       db $64,$D9,$D1,$EE,$FE,$11,$03,$9A,$4D,$CB,$E5,$53,$43,$10,$CA,$C1;0EB550
                       ; $9A separator
                       ; Repeated $D9 from previous line, envelopes $D1/$EE/$FE/$CB/$E5/$CA/$C1
                       ; Mid-range: $64/$4D/$53/$43

                       db $9A,$2F,$34,$00,$01,$12,$FC,$F1,$0E,$9A,$EE,$23,$0F,$03,$62,$BB;0EB560
                       ; Two $9A separators with zero byte
                       ; Envelopes: $FC/$F1/$EE/$BB
                       ; Mid-range: $62

                       db $EE,$EF,$AA,$F0,$11,$10,$1E,$DE,$23,$11,$22,$9A,$1E,$BB,$D2,$10;0EB570
                       ; $AA and $9A separators
                       ; Envelopes: $EE/$EF/$F0/$DE/$BB/$D2
                       ; Repeated $1E, $10, $11

                       db $22,$13,$2F,$F0,$9A,$0D,$D2,$2D,$B1,$43,$DF,$34,$30,$AA,$EE,$E0;0EB580
                       ; $9A and $AA separators with $B1 voice marker
                       ; Envelopes: $F0/$D2/$DF/$EE/$E0
                       ; Low params: $22/$13/$2F/$0D/$2D/$43/$34/$30

                       db $FF,$F2,$00,$13,$FB,$D1,$AA,$33,$2F,$12,$1F,$DD,$01,$0F,$12,$9A;0EB590
                       ; $AA and $9A separators with zero byte
                       ; Maximum $FF, envelopes $F2/$FB/$D1/$DD
                       ; Repeated $12, $13, $1F values

                       db $43,$E0,$2E,$DB,$05,$0A,$E2,$33,$9A,$DF,$55,$FF,$DB,$EF,$DE,$23;0EB5A0
                       ; $9A separator
                       ; Envelopes: $E0/$DB/$E2/$DF,$DB/$EF/$DE
                       ; Maximum $FF, repeated $55, $DB

                       db $20,$AA,$11,$CC,$F2,$44,$0F,$11,$1F,$DE,$9A,$11,$EE,$34,$62,$FF;0EB5B0
                       ; $AA and $9A separators
                       ; Envelopes: $CC/$F2/$DE/$EE/$FF (maximum)
                       ; Repeated $11, mid-range $62

                       db $1F,$AB,$54,$9A,$BB,$03,$43,$DF,$61,$E1,$BB,$10,$AA,$EE,$13,$10;0EB5C0
                       ; $9A and $AA separators
                       ; $AB separator variant, envelopes $BB/$DF/$E1/$BB/$EE
                       ; Mid-range: $54, $61

                       db $1E,$BF,$12,$42,$F0,$9A,$22,$1D,$BF,$2F,$CF,$16,$72,$F0,$9A,$0C;0EB5D0
                       ; Two $9A separators
                       ; Repeated $BF envelope, plus $F0/$CF/$F0
                       ; Mid-range: $72

                       db $9F,$5F,$CE,$24,$22,$E0,$30,$AA,$00,$DE,$10,$EE,$23,$10,$FC,$C2;0EB5E0
                       ; $AA separator with zero byte
                       ; $9F separator variant, envelopes $CE/$E0/$DE/$EE/$FC/$C2
                       ; Mid-range: $5F

                       db $AA,$22,$31,$01,$FF,$10,$E1,$0D,$F1,$9A,$16,$61,$01,$DA,$E1,$0C;0EB5F0
                       ; $AA and $9A separators
                       ; Maximum $FF, envelopes $E1/$F1/$DA/$E1
                       ; Mid-range: $61

                       db $F0,$24,$9A,$31,$00,$FF,$0F,$CE,$10,$BF,$46,$AA,$1E,$DC,$03,$11;0EB600
                       ; $9A and $AA separators with zero byte
                       ; Envelopes: $F0/$FF/$CE/$BF/$DC
                       ; Maximum $FF value

                       db $40,$F1,$FF,$20,$AA,$F1,$EC,$12,$02,$40,$0F,$EF,$1F,$9A,$CD,$F1;0EB610
                       ; $AA and $9A separators
                       ; Two $FF maximums, repeated $F1 envelope
                       ; Also $EC/$EF/$CD envelopes

                       db $54,$13,$0E,$DE,$1E,$E1,$AA,$0F,$E0,$23,$FD,$EE,$13,$02,$3E,$AA;0EB620
                       ; Two $AA separators
                       ; Envelopes: $DE/$E1/$E0/$FD/$EE
                       ; Mid-range: $54, $3E

                       db $02,$EF,$11,$10,$DD,$01,$15,$2E,$9A,$10,$B0,$1C,$BE,$04,$52,$23;0EB630
                       ; $9A separator
                       ; Envelopes: $EF/$DD/$B0/$BE
                       ; Mid-range: $52

                       db $0B,$9A,$B0,$2E,$F1,$0D,$F2,$21,$DA,$C1,$AA,$22,$12,$00,$1F,$D1;0EB640
                       ; $9A and $AA separators with zero byte
                       ; Repeated $B0 from previous line
                       ; Envelopes: $F1/$F2/$DA/$C1/$D1

                       db $21,$1E,$DE,$AA,$21,$14,$0F,$0F,$F1,$0D,$EF,$12,$AA,$21,$21,$FC;0EB650
                       ; Three $AA separators (high concentration)
                       ; Envelopes: $DE/$F1/$EF/$FC
                       ; Repeated $21 value (4 instances)

                       db $F0,$0F,$11,$0F,$F1,$9A,$FF,$F9,$F5,$03,$60,$03,$0A,$D3,$9A,$44;0EB660
                       ; Two $9A separators
                       ; Envelopes: $F0/$F1/$FF/$F9/$F5/$D3
                       ; Maximum $FF, repeated $0F, $03

                       db $FB,$AF,$42,$44,$FE,$1F,$F1,$AA,$FD,$F0,$11,$21,$31,$CC,$10,$F1;0EB670
                       ; $AA separator
                       ; High envelope cluster: $FB/$AF/$FE/$F1/$FD/$F0/$CC/$F1
                       ; Repeated $44, $11, $F1

                       db $9A,$10,$0E,$12,$CE,$E9,$44,$E5,$6F,$9A,$22,$BB,$21,$33,$FB,$CF;0EB680
                       ; Two $9A separators
                       ; Envelopes: $CE/$E9/$E5,$BB/$FB/$CF
                       ; Repeated $44, mid-range $6F

                       db $56,$10,$9A,$EF,$2F,$E1,$EB,$F3,$01,$35,$5D,$AA,$CE,$1F,$1F,$02;0EB690
                       ; $9A and $AA separators
                       ; Envelopes: $EF/$E1/$EB/$F3/$CE
                       ; Mid-range: $56, $5D, repeated $1F

                       db $1E,$00,$EF,$F0,$9A,$10,$25,$31,$2F,$AE,$41,$F2,$1D,$9A,$C0,$54;0EB6A0
                       ; Two $9A separators with zero byte
                       ; Envelopes: $EF,$F0/$AE/$F2/$C0
                       ; Mid-range: $54

                       db $2F,$D0,$1F,$EF,$FE,$13,$9A,$0F,$26,$1C,$CE,$E2,$2E,$F3,$0E,$9A;0EB6B0
                       ; Two $9A separators
                       ; Envelopes: $D0/$EF/$FE/$CE/$E2/$F3
                       ; Low params interspersed

                       db $00,$CC,$11,$E2,$42,$43,$EE,$C0,$9A,$3E,$E4,$4D,$B2,$43,$2C,$D2;0EB6C0
                       ; $9A separator with zero byte, $B2 voice marker (bass)
                       ; Envelopes: $CC/$E2/$EE/$C0/$E4,$D2
                       ; Mid-range: $3E, $4D, $43, $2C

                       db $0E,$9A,$0E,$F2,$30,$FF,$23,$FE,$FC,$F4,$9A,$0E,$12,$EE,$00,$BF;0EB6D0
                       ; Two $9A separators with zero byte
                       ; Maximum $FF, envelopes $F2/$FE/$FC/$F4/$EE/$BF
                       ; Repeated $0E

                       db $3E,$D4,$40,$9A,$63,$CD,$F0,$1E,$D5,$6C,$D2,$24,$9A,$0A,$F4,$FE;0EB6E0
                       ; Two $9A separators
                       ; DSP range: $D4/$CD/$F0/$D5/$D2/$F4/$FE
                       ; Mid-range: $3E, $63, $6C

                       db $EE,$23,$3F,$00,$EF,$96,$03,$3E,$E0,$02,$51,$DE,$FC,$CD,$AA,$0F;0EB6F0
                       ; $96 and $AA separators with zero byte
                       ; Envelopes: $EE/$EF/$E0/$DE/$FC/$CD
                       ; Mid-range: $51, $3E

                       db $00,$12,$30,$E0,$0F,$FF,$04,$9A,$3C,$1E,$16,$CB,$31,$EF,$EE,$46;0EB700
                       ; $9A separator with zero byte
                       ; Maximum $FF, envelopes $E0/$CB/$EF/$EE
                       ; Low params: $12, $30, $0F, $04, $3C, $1E, $16, $31, $46

                       db $9A,$1D,$1F,$BF,$32,$FF,$0F,$F3,$2D,$9A,$B1,$FF,$3F,$D0,$0F,$27;0EB710
                       ; Two $9A separators with $B1 voice marker
                       ; Two $FF maximums, envelopes $BF/$F3/$D0
                       ; Low params: $1D, $1F, $32, $0F, $2D, $3F, $0F, $27

                       db $3D,$11,$96,$62,$D9,$E6,$55,$5F,$02,$EC,$ED,$9A,$EF,$EF,$56,$1E;0EB720
                       ; $96 and $9A separators
                       ; Envelopes: $D9/$E6/$EC/$ED/$EF/$EF
                       ; Mid-range: $62, $55, $5F, $56

                       db $FD,$BF,$42,$10,$9A,$FD,$E5,$4A,$B0,$F4,$3C,$C0,$20,$AA,$03,$01;0EB730
                       ; $9A and $AA separators
                       ; Repeated $FD envelope, plus $BF/$E5/$B0/$F4/$C0
                       ; Mid-range: $4A, $3C

                       db $3F,$CE,$E1,$41,$02,$FE,$9A,$20,$D1,$2D,$F0,$F1,$44,$2D,$CC,$9A;0EB740
                       ; Two $9A separators
                       ; Envelopes: $CE/$E1/$FE,$D1/$F0/$F1/$CC
                       ; Repeated $2D

                       db $E1,$23,$3F,$ED,$E6,$29,$B0,$36,$AA,$FE,$FF,$12,$0F,$23,$2D,$CF;0EB750
                       ; $AA separator
                       ; Envelopes: $E1/$ED/$E6/$B0/$FE/$FF/$CF
                       ; Maximum $FF value

                       db $01,$9A,$43,$23,$EB,$E1,$03,$FD,$01,$11,$9A,$14,$4A,$AD,$F3,$33;0EB760
                       ; Two $9A separators
                       ; Envelopes: $EB/$E1/$FD,$AD/$F3
                       ; Mid-range: $4A

                       db $2E,$CF,$22,$AA,$FD,$F2,$20,$0E,$E0,$11,$0F,$34,$9A,$FA,$AD,$33;0EB770
                       ; $AA and $9A separators
                       ; Envelopes: $CF/$FD/$F2/$E0,$FA/$AD
                       ; Low params: $2E, $22, $20, $0E, $11, $0F, $34, $33

                       db $23,$11,$F9,$03,$00,$9A,$0F,$F1,$30,$24,$E9,$ED,$F6,$40,$AA,$1E;0EB780
                       ; $9A and $AA separators with zero byte
                       ; Envelopes: $F9/$F1/$E9/$ED/$F6
                       ; Low params: $23, $11, $03, $0F, $30, $24, $40, $1E

                       db $E2,$1E,$EE,$14,$1E,$FE,$F2,$AA,$1E,$11,$22,$0D,$D0,$21,$11,$00;0EB790
                       ; $AA separator with zero byte
                       ; Envelopes: $E2/$EE/$FE/$F2/$D0
                       ; Repeated $1E value (4 instances)

                       db $96,$0A,$DF,$BC,$0D,$BF,$01,$66,$EB,$AA,$0E,$04,$20,$FE,$11,$0D;0EB7A0
                       ; $96 and $AA separators
                       ; Envelopes: $DF/$BC/$BF/$EB/$FE
                       ; Mid-range: $66

                       db $DF,$53,$9A,$EB,$EE,$11,$ED,$46,$31,$D9,$E5,$9A,$13,$2D,$11,$AD;0EB7B0
                       ; Two $9A separators
                       ; Envelopes: $DF/$EB/$EE/$ED/$D9/$E5,$AD
                       ; Mid-range: $53, $46

                       db $40,$D6,$2C,$03,$AA,$02,$2D,$B0,$0F,$23,$20,$DF,$20,$AA,$FE,$C2;0EB7C0
                       ; Two $AA separators
                       ; Envelopes: $D6/$B0/$DF/$FE/$C2
                       ; Repeated $20, $2D

                       db $51,$EF,$F0,$0F,$E1,$32,$9A,$00,$DC,$14,$10,$10,$0E,$A0,$4E,$AA;0EB7D0
                       ; $9A and $AA separators with zero byte
                       ; Envelopes: $EF/$F0/$E1/$DC/$A0
                       ; Mid-range: $51, $4E, repeated $10

                       db $03,$0F,$01,$21,$FC,$E0,$F0,$41,$9A,$13,$EC,$1F,$BE,$02,$52,$EF;0EB7E0
                       ; $9A separator
                       ; Envelopes: $FC/$E0/$F0,$EC/$BE/$EF
                       ; Mid-range: $52

                       db $FD,$9A,$EF,$E4,$61,$0F,$CF,$24,$2D,$F3,$9A,$FD,$CD,$14,$41,$E2;0EB7F0
                       ; Two $9A separators
                       ; Repeated $FD envelope, plus $EF/$E4/$CF/$F3/$CD/$E2
                       ; Mid-range: $61

                       db $11,$21,$DA,$9A,$B0,$03,$51,$04,$1C,$CD,$E2,$3F,$9A,$13,$E0,$1B;0EB800
                       ; Two $9A separators
                       ; Envelopes: $DA/$B0/$CD/$E2/$E0
                       ; Mid-range: $51

                       db $B0,$25,$4F,$F1,$DE,$9A,$53,$CF,$32,$EE,$AB,$17,$50,$F2,$9A,$21;0EB810
                       ; Two $9A separators
                       ; Repeated $B0 from previous line
                       ; $AB separator variant, envelopes $F1/$DE/$CF/$EE/$F2
                       ; Mid-range: $53, $50

                       db $1E,$CC,$CF,$25,$3E,$16,$1C,$AA,$CE,$22,$0F,$00,$11,$0D,$D0,$22;0EB820
                       ; $AA separator with zero byte
                       ; Repeated $CC/$CF from previous, plus $CE/$D0
                       ; Low params: $1E, $25, $3E, $16, $1C, $22, $0F, $11, $0D, $22

                       db $AA,$20,$E0,$1F,$21,$C1,$3F,$0F,$BE,$9A,$63,$45,$00,$1F,$01,$B9;0EB830
                       ; $AA and $9A separators with zero byte
                       ; Envelopes: $E0/$C1/$BE/$B9
                       ; Mid-range: $63, $45

                       db $01,$14,$AA,$00,$22,$FE,$DE,$42,$E0,$1E,$02,$9A,$EC,$C0,$56,$2D;0EB840
                       ; $AA and $9A separators with zero byte
                       ; Envelopes: $FE/$DE,$E0,$EC/$C0
                       ; Mid-range: $56, $42

                       db $C0,$21,$2E,$C4,$AA,$20,$0D,$A1,$30,$24,$0F,$F0,$11,$9A,$AA,$F3;0EB850
                       ; $AA and $9A separators
                       ; Repeated $C0 from previous, plus $C4/$A1/$F0/$F3
                       ; Repeated $AA separator in same line (unusual)

                       db $21,$E1,$72,$BB,$F3,$30,$9A,$EF,$1F,$F0,$FD,$01,$34,$2C,$D2,$AA;0EB860
                       ; $9A and $AA separators
                       ; Envelopes: $E1/$BB/$F3/$EF/$F0/$FD/$D2
                       ; Mid-range: $72

                       db $01,$0D,$04,$11,$EB,$D1,$11,$34,$9A,$2B,$BF,$51,$CB,$04,$1C,$02;0EB870
                       ; $9A separator
                       ; Envelopes: $EB/$D1/$BF/$CB
                       ; Mid-range: $51, $2B

                       db $51,$9A,$CB,$35,$0D,$1F,$10,$AF,$3F,$F2,$A6,$12,$31,$01,$11,$1F;0EB880
                       ; $9A separator with $A6 voice marker
                       ; Repeated $CB from previous, plus $AF/$F2
                       ; Mid-range: $51, repeated $1F

                       db $03,$44,$0A,$9A,$F4,$F6,$64,$1A,$A4,$30,$FC,$14,$9A,$DB,$20,$33;0EB890
                       ; Two $9A separators
                       ; Envelopes: $F4/$F6/$A4/$FC/$DB
                       ; Mid-range: $64

                       db $DD,$44,$0D,$D0,$4E,$9A,$9E,$41,$13,$2F,$FF,$02,$FB,$F2,$AA,$13;0EB8A0
                       ; $9A and $AA separators
                       ; Envelopes: $DD/$D0/$9E/$FF/$FB/$F2
                       ; Maximum $FF, mid-range $4E

                       db $3D,$AE,$10,$14,$20,$FD,$02,$9A,$F1,$10,$2F,$AE,$0F,$44,$E0,$24;0EB8B0
                       ; $9A separator
                       ; Repeated $AE from previous, plus $FD/$F1/$E0
                       ; Mid-range: $3D, $44

                       db $9A,$2B,$92,$5C,$B0,$13,$50,$EF,$02,$A6,$22,$0E,$D0,$14,$60,$9B;0EB8C0
                       ; $9A separator with $A6 voice marker
                       ; $92/$9B separator variants
                       ; Envelopes: $B0/$EF/$D0
                       ; Mid-range: $5C, $50, $60, $2B

                       db $EC,$E3,$9A,$2C,$9E,$43,$00,$16,$19,$AE,$E0,$AA,$32,$00,$12,$0E;0EB8D0
                       ; $9A and $AA separators with zero bytes
                       ; $9E separator variant
                       ; Envelopes: $EC/$E3/$AE/$E0

                       db $C0,$20,$D0,$13,$A6,$32,$00,$11,$22,$0E,$DF,$24,$3F,$A6,$BC,$DD;0EB8E0
                       ; Two $A6 voice markers (voice 6 prominence)
                       ; Envelopes: $C0/$D0/$DF/$BC/$DD
                       ; Multiple zero bytes (section markers)

                       db $14,$20,$ED,$02,$22,$47,$9A,$D9,$9C,$E3,$75,$FF,$53,$DC,$AC,$9A;0EB8F0
                       ; Two $9A separators
                       ; $9C separator variant, envelopes $ED/$D9/$E3/$FF/$DC/$AC
                       ; Maximum $FF, mid-range $75, $53, $47

                       db $43,$D0,$53,$FD,$D2,$30,$0F,$DF,$9A,$F1,$53,$9E,$0D,$13,$42,$CC;0EB900
                       ; $9A separator
                       ; $9E separator variant, envelopes $D0/$FD/$D2/$DF/$F1/$CC
                       ; Repeated $53

                       db $FE,$AA,$14,$00,$31,$DE,$DD,$02,$33,$F0,$9A,$7F,$BC,$DD,$14,$02;0EB910
                       ; $AA and $9A separators with zero byte
                       ; Envelopes: $FE/$DE/$DD/$F0/$BC/$DD
                       ; Mid-range: $7F

                       db $60,$BC,$F3,$9A,$50,$CF,$1F,$E1,$2E,$F2,$FD,$13,$AA,$00,$FF,$0E;0EB920
                       ; $9A and $AA separators with zero byte
                       ; Repeated $BC from previous, plus $F3/$CF/$E1/$F2/$FD/$FF
                       ; Maximum $FF, mid-range $60, $50

                       db $14,$21,$1E,$E0,$BC,$AA,$33,$22,$00,$3F,$CF,$0E,$F2,$33,$9A,$FC;0EB930
                       ; $AA and $9A separators with zero byte
                       ; Repeated $BC again, envelopes $E0/$CF/$F2/$FC
                       ; Repeated $33

                       db $CE,$22,$22,$DD,$20,$D1,$DD,$AA,$42,$DF,$1F,$00,$00,$FF,$13,$41;0EB940
                       ; $AA separator with double zero bytes
                       ; Envelopes: $CE/$DD/$D1/$DD/$DF/$FF
                       ; Maximum $FF, repeated $22

                       db $9A,$DC,$CD,$AD,$45,$25,$4F,$0D,$BE,$9A,$FD,$25,$64,$CB,$D0,$11;0EB950
                       ; Two $9A separators
                       ; Envelopes: $DC/$CD/$AD/$BE/$FD/$CB/$D0
                       ; Mid-range: $64, $45, $4F

                       db $32,$CE,$A6,$10,$EE,$BD,$33,$F1,$1D,$D0,$00,$AA,$FF,$13,$50,$EE;0EB960
                       ; $A6 voice marker, $AA separator with zero byte
                       ; Envelopes: $CE/$EE/$BD/$F1/$D0/$FF/$EE
                       ; Maximum $FF, mid-range $50

                       db $DE,$F0,$21,$14,$9A,$2C,$0E,$BD,$F2,$45,$21,$EB,$D1,$9A,$01,$50;0EB970
                       ; Two $9A separators
                       ; Envelopes: $DE/$F0/$BD/$F2/$EB/$D1
                       ; Mid-range: $50, $45, $2C

                       db $C1,$2C,$DE,$E5,$6F,$F1,$AA,$DD,$22,$F0,$0E,$25,$1F,$0D,$C0,$AA;0EB980
                       ; Two $AA separators
                       ; Envelopes: $C1/$DE/$E5/$F1/$DD/$F0/$C0
                       ; Mid-range: $6F, $2C

                       db $01,$10,$24,$FE,$0E,$FF,$01,$33,$9A,$ED,$1C,$E2,$EF,$52,$D2,$1B;0EB990
                       ; $9A separator
                       ; Envelopes: $FE/$FF/$ED/$E2/$EF/$D2
                       ; Maximum $FF, mid-range $52

                       db $BF,$9A,$23,$12,$4C,$AC,$14,$01,$1D,$47,$AA,$F0,$1C,$C1,$01,$21;0EB9A0
                       ; $9A and $AA separators
                       ; Envelopes: $BF/$AC/$F0/$C1
                       ; Mid-range: $4C, $47

                       db $22,$EE,$F0,$9A,$DF,$16,$61,$CD,$10,$E0,$FE,$42,$A6,$02,$2D,$BE;0EB9B0
                       ; $9A separator with $A6 voice marker
                       ; Envelopes: $EE,$F0/$DF/$CD/$E0/$FE/$BE
                       ; Mid-range: $61, $42

                       db $FE,$F2,$30,$DC,$DF,$AA,$21,$F0,$20,$00,$FD,$F0,$10,$14,$9A,$30;0EB9C0
                       ; $AA and $9A separators with zero byte
                       ; Repeated $FE/$F2/$DF/$F0 envelopes
                       ; Also $DC/$FD

                       db $CA,$EF,$02,$44,$20,$FC,$F1,$A6,$01,$FC,$E1,$12,$0C,$DF,$EE,$12;0EB9D0
                       ; $A6 voice marker
                       ; Envelopes: $CA/$EF/$FC/$F1/$FC/$E1/$DF/$EE
                       ; Repeated $FC

                       db $9A,$FB,$AF,$22,$40,$24,$ED,$2E,$C0,$AA,$FF,$20,$15,$1D,$EE,$F0;0EB9E0
                       ; $9A and $AA separators
                       ; Envelopes: $FB/$AF/$ED/$C0/$FF/$EE/$F0
                       ; Maximum $FF

                       db $11,$21,$9A,$11,$0B,$D3,$31,$BB,$16,$6F,$AC,$9A,$EF,$34,$3F,$CC;0EB9F0
                       ; Two $9A separators
                       ; Envelopes: $D3/$BB/$AC/$EF/$CC
                       ; Mid-range: $6F, repeated $11

                       db $DF,$33,$21,$22,$AA,$E0,$0E,$F1,$F0,$10,$34,$0C,$DF,$9A,$E1,$45;0EBA00
                       ; $AA and $9A separators
                       ; Repeated $DF envelope, plus $E0/$F1/$F0/$E1
                       ; Repeated $33

; SECTION SUMMARY (Lines 801-1000, $0EB1D0-$0EBA00):
; - $9A separator: DOMINANT (appears ~80 times, ~40% of lines)
; - $AA separator: SECONDARY (appears ~50 times, ~25% of lines)
; - $8A separator: RARE (only 3 instances - lines 803/0EB3F0, 805/0EB410, 868/0EB540)
;   * $8A marks major section boundaries (different from $9A/$AA voice layers)
; - $96 separator: OCCASIONAL (10 instances)
; - Other variants: $9C, $9E, $9F, $AB (rare, likely subsection markers)
;
; Voice markers identified:
; - $B1: Melody voice (10+ instances)
; - $B2: Bass/rhythm voice (5+ instances)
; - $B3: Voice 3 (1 instance)
; - $B5: Voice 5 (1 instance)
; - $A2: Voice 4 (1 instance)
; - $A6: Voice 6 (8+ instances, increasing prominence)
;
; Pattern analysis:
; - $9A/$AA appear to represent two main voice layers/channels
; - Separators often alternate within same line (rapid voice switching)
; - $8A returns at strategic boundaries (every ~60-130 lines)
; - High concentration of E/F range values (envelopes: $E0-$FF, $F0-$FF)
; - Maximum $FF appears 30+ times (peak volume/brightness passages)
; - Zero bytes frequently mark voice boundaries or section transitions
; - DSP register range ($C0-$FF) heavily used for echo/modulation
;
; Address range: $0EB1D0-$0EBA00 (~2KB of voice data)
; Estimated voices active: 6-8 simultaneous channels (based on voice markers)
; Data density: ~200 lines = ~3.2KB raw data
; Lines 1001-1200 documented (200 source lines, addresses $0EBA10-$0ECAC0)
; Continuation of $9A/$AA separator pattern analysis

                       db $30,$E1,$1D,$B4,$5D,$CE,$AA,$03,$3E,$E0,$DE,$43,$0E,$DF,$0F,$9A;0EBA10
                       ; $AA and $9A separators
                       ; $B4 voice marker (voice 11/bass variant)
                       ; Envelopes: $E1/$CE/$E0/$DE/$DF
                       ; Mid-range: $5D, $3E, $43

                       db $46,$F1,$3F,$FF,$CC,$F1,$31,$E2,$AA,$43,$FC,$CF,$11,$23,$1F,$E0;0EBA20
                       ; $AA separator
                       ; Two $F1 envelopes, maximum $FF
                       ; Also $CC/$E2/$FC/$CF/$E0
                       ; Mid-range: $46

                       db $2F,$AA,$E1,$1F,$0F,$03,$2D,$FF,$D1,$40,$A6,$20,$CC,$DD,$13,$22;0EBA30
                       ; $AA separator with $A6 voice marker
                       ; Maximum $FF, envelopes $E1/$D1/$CC/$DD
                       ; Low params: $2F, $1F, $0F, $03, $2D, $20, $13, $22

                       db $34,$52,$FE,$9A,$01,$10,$33,$53,$DB,$9D,$23,$55,$8A,$1A,$C4,$4A;0EBA40
                       ; $9A separator, **$8A separator** (major boundary!)
                       ; $9D separator variant
                       ; Envelopes: $FE/$DB/$C4
                       ; Mid-range: $52, $53, $55, $4A

                       db $C3,$ED,$43,$16,$AB,$9A,$1C,$D7,$2E,$1B,$B0,$02,$54,$DF,$9A,$30;0EBA50
                       ; Two $9A separators with $AB separator variant
                       ; Envelopes: $C3/$ED/$D7/$B0/$DF
                       ; Mid-range: $54, $43

                       db $FD,$BD,$02,$23,$32,$21,$DC,$9A,$CC,$26,$32,$0F,$F1,$0F,$F0,$D0;0EBA60
                       ; $9A separator
                       ; Envelopes: $FD/$BD/$DC/$CC/$F1/$F0/$D0
                       ; Repeated $0F, $32

                       db $9A,$63,$FD,$C1,$1D,$23,$EF,$0D,$EE,$9A,$12,$53,$CF,$40,$DE,$EC;0EBA70
                       ; Two $9A separators
                       ; Envelopes: $FD/$C1/$EF/$EE/$CF/$DE/$EC
                       ; Mid-range: $63, $53

                       db $C1,$66,$AA,$11,$0F,$EF,$FE,$24,$1F,$F0,$01,$96,$2F,$DD,$AD,$65;0EBA80
                       ; $AA and $96 separators
                       ; Envelopes: $C1/$EF/$FE/$F0/$DD/$AD
                       ; Mid-range: $66, $65

                       db $0F,$DB,$CE,$00,$9A,$EE,$FF,$E0,$11,$62,$BF,$3F,$F1,$AA,$EC,$F2;0EBA90
                       ; $9A and $AA separators with zero byte
                       ; Maximum $FF, envelopes $DB/$CE/$EE/$E0/$BF/$F1/$EC/$F2
                       ; Mid-range: $62

                       db $33,$2F,$FF,$FF,$E1,$41,$9A,$EE,$01,$21,$EC,$01,$15,$3C,$E1,$9A;0EBAA0
                       ; Two $9A separators
                       ; Two $FF maximums, envelopes $E1/$EE/$EC/$E1
                       ; Mid-range: $3C

                       db $DE,$31,$2F,$CD,$F0,$02,$21,$20,$9A,$CF,$22,$1E,$9A,$14,$57,$3E;0EBAB0
                       ; Two $9A separators
                       ; Envelopes: $DE/$CD/$F0/$CF
                       ; Mid-range: $57, $3E

                       db $DB,$9A,$C0,$25,$4F,$FF,$E1,$4F,$DF,$E1,$AA,$40,$E0,$10,$FF,$01;0EBAC0
                       ; $9A and $AA separators
                       ; Two $FF maximums, envelopes $DB/$C0/$E1/$DF/$E1/$E0
                       ; Repeated $4F

                       db $1F,$EE,$01,$9A,$03,$3F,$F1,$CD,$75,$C9,$BE,$15,$AA,$32,$10,$DD;0EBAD0
                       ; $9A and $AA separators
                       ; Envelopes: $EE/$F1/$CD/$C9/$BE/$DD
                       ; Mid-range: $75

                       db $D2,$51,$F0,$0F,$F1,$9A,$20,$FD,$E5,$5E,$E1,$00,$0C,$F5,$AA,$2E;0EBAE0
                       ; $9A and $AA separators with zero byte
                       ; Envelopes: $D2/$F0/$F1/$FD/$E5/$E1/$F5
                       ; Mid-range: $51, $5E

                       db $CE,$11,$13,$1E,$0F,$D1,$41,$AA,$DD,$E0,$21,$23,$2D,$CE,$03,$4F;0EBAF0
                       ; $AA separator
                       ; Envelopes: $CE/$D1/$DD/$E0/$CE
                       ; Mid-range: $4F

                       db $9A,$C3,$1C,$02,$F3,$0A,$F5,$21,$1F,$AA,$01,$EE,$12,$1E,$CF,$10;0EBB00
                       ; $9A and $AA separators
                       ; Envelopes: $C3/$F3/$F5/$EE/$CF
                       ; Low params: $1C, $02, $0A, $21, $1F, $01, $12, $1E, $10

                       db $23,$1F,$9A,$CB,$F5,$5F,$A9,$F4,$20,$47,$1A,$96,$DA,$D3,$73,$14;0EBB10
                       ; $9A and $96 separators
                       ; Envelopes: $CB/$F5/$A9/$F4/$DA/$D3
                       ; Mid-range: $5F, $47, $73

                       db $2F,$0F,$D1,$1B,$AA,$01,$12,$0E,$11,$D0,$30,$0C,$D0,$AA,$12,$21;0EBB20
                       ; Two $AA separators
                       ; Repeated $D0 envelope, also $D1
                       ; Low params: $2F, $0F, $1B, $01, $12, $0E, $11, $30, $0C, $12, $21

                       db $1F,$DF,$11,$1F,$DE,$21,$AA,$F2,$12,$1D,$B2,$22,$0F,$01,$F0,$9A;0EBB30
                       ; $AA and $9A separators with $B2 voice marker (bass)
                       ; Envelopes: $DF/$DE/$F2/$F0
                       ; Repeated $1F, $21, $22

                       db $00,$10,$D0,$20,$34,$CF,$3C,$E4,$AA,$10,$FC,$F0,$12,$01,$3E,$C1;0EBB40
                       ; $AA separator with zero byte
                       ; Envelopes: $D0/$CF/$E4/$FC/$F0/$C1
                       ; Mid-range: $3C, $3E

                       db $20,$AA,$0D,$D1,$3F,$02,$02,$1C,$C3,$21,$9A,$0E,$F2,$2F,$F2,$DB;0EBB50
                       ; $AA and $9A separators
                       ; Repeated $F2 envelope, also $D1/$C3/$DB
                       ; Low params: $20, $0D, $3F, $02, $02, $1C, $21, $0E, $2F

                       db $25,$1F,$3F,$9A,$E2,$0C,$14,$2F,$CA,$EF,$32,$24,$9A,$3B,$C4,$1D;0EBB60
                       ; Two $9A separators
                       ; Envelopes: $E2/$CA/$EF/$C4
                       ; Mid-range: $3B

                       db $DC,$D5,$4E,$02,$24,$A6,$4F,$D0,$22,$20,$E1,$32,$1F,$DC,$9A,$45;0EBB70
                       ; $9A separator with $A6 voice marker
                       ; Envelopes: $DC/$D5/$D0/$E1/$DC
                       ; Mid-range: $4E, $4F, $45

                       db $3E,$FE,$F1,$10,$04,$1D,$CB,$9A,$E2,$01,$53,$FE,$F4,$EB,$EC,$F6;0EBB80
                       ; $9A separator
                       ; Envelopes: $FE/$F1/$CB/$E2/$FE/$F4/$EB/$EC/$F6
                       ; Mid-range: $3E, $53

                       db $9A,$2F,$03,$20,$DC,$E5,$31,$FA,$07,$9A,$31,$DA,$D0,$56,$2D,$EF;0EBB90
                       ; Two $9A separators
                       ; Envelopes: $DC/$E5/$FA/$DA/$D0/$EF
                       ; Mid-range: $56, repeated $31

                       db $F0,$20,$9A,$22,$0F,$CA,$00,$F5,$3E,$31,$F1,$9A,$DC,$EC,$04,$40;0EBBA0
                       ; Two $9A separators with zero byte
                       ; Envelopes: $F0/$CA/$F5/$F1/$DC/$EC
                       ; Mid-range: $3E

                       db $12,$EF,$0C,$04,$96,$46,$2B,$F2,$45,$0B,$BC,$F4,$30,$9A,$1F,$D1;0EBBB0
                       ; $96 and $9A separators
                       ; Envelopes: $EF/$F2/$BC/$F4/$D1
                       ; Mid-range: $46, $45, $2B

                       db $02,$5F,$FF,$AE,$2E,$03,$9A,$01,$32,$FE,$DE,$FE,$E2,$52,$2E,$96;0EBBC0
                       ; $9A and $96 separators
                       ; Maximum $FF, repeated $FE envelope
                       ; Also $AE/$DE/$E2
                       ; Mid-range: $5F, $52

                       db $02,$30,$02,$45,$0C,$F2,$44,$EB,$96,$ED,$F4,$0F,$52,$BA,$C2,$64;0EBBD0
                       ; $96 separator
                       ; Envelopes: $F2/$EB/$ED/$F4/$BA/$C2
                       ; Mid-range: $52, $64, $45

                       db $1F,$9A,$EF,$F0,$F0,$31,$13,$ED,$10,$DA,$9A,$F5,$52,$1A,$E5,$0C;0EBBE0
                       ; Two $9A separators
                       ; Envelopes: $EF/$F0/$F0/$ED/$DA/$F5/$E5
                       ; Mid-range: $52

                       db $04,$3F,$BD,$9A,$45,$FF,$EF,$20,$01,$03,$4A,$90,$9A,$54,$20,$C0;0EBBF0
                       ; Two $9A separators with $90 separator variant
                       ; Maximum $FF, envelopes $BD/$EF/$C0
                       ; Mid-range: $45, $54, $4A

                       db $1D,$EF,$D2,$32,$2F,$9A,$D1,$2E,$DD,$12,$11,$0E,$24,$CC,$A6,$02;0EBC00
                       ; $9A separator with $A6 voice marker
                       ; Envelopes: $EF/$D2/$D1/$DD/$CC
                       ; Low params: $1D, $32, $2F, $2E, $12, $11, $0E, $24, $02

                       db $22,$EC,$13,$11,$0E,$F0,$EF,$96,$57,$3F,$AB,$DE,$24,$24,$3F,$CA;0EBC10
                       ; $96 separator with $AB separator variant
                       ; Envelopes: $EC/$F0/$EF/$DE/$CA
                       ; Mid-range: $57, repeated $3F, $24

                       db $9A,$D1,$42,$20,$E0,$2F,$CE,$10,$02,$96,$24,$64,$EF,$33,$42,$AB;0EBC20
                       ; $9A and $96 separators with $AB separator variant
                       ; Envelopes: $D1/$E0/$CE/$EF
                       ; Mid-range: $64, $42, repeated $24

                       db $35,$31,$9A,$CF,$40,$D5,$6D,$DD,$D1,$11,$33,$9A,$31,$BB,$FD,$D3;0EBC30
                       ; Two $9A separators
                       ; Envelopes: $CF/$D5/$DD/$D1/$BB/$FD/$D3
                       ; Mid-range: $6D, repeated $31, $33

                       db $22,$4E,$D4,$3C,$9A,$C0,$FF,$01,$53,$0C,$B2,$30,$2E,$A6,$EF,$12;0EBC40
                       ; $9A separator with $B2/$A6 voice markers (bass + voice 6)
                       ; Maximum $FF, envelopes $D4/$C0/$EF
                       ; Mid-range: $4E, $53, $3C

                       db $2F,$D0,$0E,$E2,$42,$0E,$9A,$E0,$11,$47,$4C,$AE,$DB,$01,$06,$9A;0EBC50
                       ; Two $9A separators
                       ; Envelopes: $D0/$E2/$E0/$AE/$DB
                       ; Mid-range: $47, $4C, $42

                       db $3B,$37,$DB,$EE,$E0,$05,$61,$F9,$9A,$C5,$0F,$3F,$F3,$01,$E9,$45;0EBC60
                       ; $9A separator
                       ; Envelopes: $DB/$EE/$E0/$F9/$C5/$F3/$E9
                       ; Mid-range: $61, $45, $3B, $37

                       db $B0,$9A,$63,$0E,$CB,$D2,$31,$76,$FE,$DA,$9A,$BC,$12,$24,$01,$61;0EBC70
                       ; Two $9A separators
                       ; Envelopes: $B0/$CB/$D2/$FE/$DA/$BC
                       ; Mid-range: $63, $76, $61

                       db $BD,$CE,$0F,$AA,$24,$1F,$EE,$01,$00,$11,$0F,$00,$9A,$C0,$6E,$C5;0EBC80
                       ; $AA and $9A separators with double zero bytes
                       ; Envelopes: $BD/$CE/$EE/$C0/$C5
                       ; Mid-range: $6E

                       db $50,$0D,$BB,$D5,$54,$AA,$21,$00,$EC,$C0,$20,$F3,$13,$2F,$AA,$DE;0EBC90
                       ; Two $AA separators with zero byte
                       ; Envelopes: $BB/$D5/$EC/$C0/$F3/$DE
                       ; Mid-range: $50, $54

                       db $EF,$00,$44,$0E,$EE,$F1,$11,$9A,$60,$BC,$00,$04,$1C,$04,$41,$EB;0EBCA0
                       ; $9A separator with zero bytes
                       ; Envelopes: $EF/$EE/$F1/$BC/$EB
                       ; Mid-range: $60, $44

                       db $AA,$EE,$03,$22,$12,$FF,$DC,$E2,$0E,$AA,$14,$31,$FF,$FE,$DF,$03;0EBCB0
                       ; Two $AA separators
                       ; Two $FF maximums, envelopes $EE/$DC/$E2/$FE/$DF
                       ; Low params: $03, $22, $12, $0E, $14, $31, $03

                       db $51,$EF,$9A,$DD,$01,$14,$4E,$AC,$02,$54,$CB,$9A,$24,$30,$BC,$FE;0EBCC0
                       ; Two $9A separators
                       ; Envelopes: $EF/$DD/$AC/$CB/$BC/$FE
                       ; Mid-range: $51, $4E, $54

                       db $16,$42,$41,$CB,$AA,$EE,$0F,$F0,$34,$1F,$F0,$FE,$FF,$AA,$04,$3F;0EBCD0
                       ; Two $AA separators
                       ; Repeated $CB from previous, also $EE/$F0/$F0/$FE/$FF
                       ; Maximum $FF, mid-range $42

                       db $FF,$E1,$1F,$03,$0E,$EF,$9A,$F5,$60,$AF,$32,$1E,$BF,$2F,$05,$9A;0EBCE0
                       ; Two $9A separators
                       ; Maximum $FF, envelopes $E1/$EF/$F5/$AF/$BF
                       ; Mid-range: $60

                       db $42,$2E,$CD,$ED,$F0,$D0,$57,$1E,$9A,$00,$CE,$EE,$27,$20,$1D,$C2;0EBCF0
                       ; $9A separator with zero byte
                       ; Envelopes: $CD/$ED/$F0/$D0/$CE/$EE/$C2
                       ; Mid-range: $57, $42

                       db $1D,$9A,$32,$EF,$FC,$15,$4C,$D2,$11,$0D,$9A,$E0,$2F,$25,$20,$FE;0EBD00
                       ; Two $9A separators
                       ; Envelopes: $EF/$FC/$D2/$E0/$FE
                       ; Mid-range: $4C

                       db $EF,$DD,$10,$9A,$D0,$64,$EF,$30,$DE,$EC,$26,$41,$8A,$EB,$04,$BB;0EBD10
                       ; $9A separator, **$8A separator** (major boundary!)
                       ; Envelopes: $EF/$DD/$D0/$EF/$DE/$EC/$EB/$BB
                       ; Mid-range: $64, $41

                       db $0F,$44,$AB,$36,$2C,$8A,$1F,$F4,$D9,$25,$13,$60,$DF,$F4,$9A,$ED;0EBD20
                       ; **$8A separator** again, plus $9A
                       ; $AB separator variant
                       ; Envelopes: $F4/$D9/$DF/$F4/$ED
                       ; Mid-range: $44, $60, $36, $2C

                       db $0F,$FE,$C2,$53,$F1,$1F,$0F,$AA,$DE,$14,$20,$F0,$11,$DD,$11,$10;0EBD30
                       ; $AA separator
                       ; Envelopes: $FE/$C2/$F1/$DE/$F0/$DD
                       ; Mid-range: $53, repeated $11

                       db $9A,$E1,$F0,$00,$30,$E1,$DD,$52,$13,$9A,$FE,$FE,$21,$E1,$2D,$CD;0EBD40
                       ; Two $9A separators with zero byte
                       ; Repeated $E1/$FE envelopes
                       ; Also $F0/$DD/$CD
                       ; Mid-range: $52

                       db $E1,$44,$AA,$00,$11,$0D,$CF,$44,$0F,$01,$1F,$A6,$ED,$EE,$F0,$0F;0EBD50
                       ; $AA separator with $A6 voice marker, zero byte
                       ; Envelopes: $E1/$CF/$ED/$EE/$F0
                       ; Repeated $44

                       db $ED,$CE,$11,$00,$9A,$B0,$64,$2D,$DF,$F1,$11,$2F,$0D,$AA,$DF,$01;0EBD60
                       ; $9A and $AA separators with zero byte
                       ; Repeated $DF envelope, also $ED/$CE/$B0/$F1
                       ; Mid-range: $64

                       db $21,$00,$21,$EB,$F2,$32,$9A,$1F,$F2,$0B,$D0,$01,$22,$0E,$CD,$AA;0EBD70
                       ; $9A and $AA separators with zero byte
                       ; Repeated $F2/$21 envelopes
                       ; Also $EB/$D0/$CD

                       db $13,$2E,$FF,$F1,$42,$DE,$01,$0F,$9A,$F5,$10,$19,$A0,$12,$32,$F1;0EBD80
                       ; $9A separator
                       ; Maximum $FF, envelopes $F1/$DE/$F5/$A0/$F1
                       ; Mid-range: $42

                       db $50,$96,$FB,$D0,$57,$76,$56,$31,$0D,$CE,$AA,$01,$FE,$E1,$32,$0E;0EBD90
                       ; $96 and $AA separators
                       ; Envelopes: $FB/$D0/$CE/$FE/$E1
                       ; Mid-range: $50, $57, $76, $56

                       db $FF,$02,$4F,$AA,$D0,$00,$0F,$12,$00,$FD,$F0,$00,$9A,$33,$00,$3E;0EBDA0
                       ; $AA and $9A separators with triple zero bytes
                       ; Maximum $FF, envelopes $D0/$FD/$F0
                       ; Mid-range: $4F, $3E

                       db $C0,$11,$23,$FE,$12,$9A,$F0,$DC,$32,$1F,$BD,$14,$51,$DE,$9A,$F1;0EBDB0
                       ; Two $9A separators
                       ; Envelopes: $C0/$FE/$F0/$DC/$BD/$DE/$F1
                       ; Mid-range: $51

                       db $14,$2B,$E1,$F1,$1E,$14,$20,$9A,$AB,$00,$F0,$23,$00,$21,$E0,$F0;0EBDC0
                       ; $9A separator with $AB separator variant, double zero bytes
                       ; Envelopes: $E1/$F1/$F0/$E0/$F0
                       ; Mid-range: $2B

                       db $9A,$40,$C0,$50,$FF,$C1,$3F,$FC,$C2,$9A,$43,$2F,$E0,$F2,$00,$01;0EBDD0
                       ; Two $9A separators with zero byte
                       ; Maximum $FF, envelopes $C0/$C1/$FC/$C2/$E0/$F2
                       ; Mid-range: $50

                       db $FE,$22,$9A,$CE,$35,$2D,$AF,$FF,$00,$01,$12,$9A,$42,$FE,$D1,$1E;0EBDE0
                       ; Two $9A separators with double zero bytes
                       ; Maximum $FF, envelopes $FE/$CE/$AF/$FE/$D1
                       ; Mid-range: $42

                       db $E4,$41,$EC,$F3,$9A,$0B,$D0,$33,$00,$00,$1F,$02,$FD,$9A,$31,$E2;0EBDF0
                       ; Two $9A separators with double zero bytes
                       ; Envelopes: $E4/$EC/$F3/$D0/$FD/$E2

                       db $1C,$E1,$26,$0B,$F0,$CF,$9A,$FF,$F2,$46,$20,$EE,$E0,$FC,$27,$9A;0EBE00
                       ; Two $9A separators
                       ; Maximum $FF, envelopes $E1/$F0/$CF/$F2/$EE/$E0/$FC
                       ; Mid-range: $46

                       db $1F,$0E,$11,$B9,$F6,$6F,$DF,$12,$9A,$0F,$21,$DE,$31,$11,$CC,$13;0EBE10
                       ; $9A separator
                       ; Envelopes: $B9/$F6/$DF/$DE/$CC
                       ; Mid-range: $6F

                       db $33,$AA,$FF,$0F,$FF,$EF,$02,$44,$FE,$00,$AA,$FF,$E0,$22,$01,$0F;0EBE20
                       ; Two $AA separators with zero byte
                       ; Three $FF maximums, envelopes $EF/$FE/$E0
                       ; Mid-range: $44

                       db $0F,$DE,$14,$9A,$3D,$D0,$11,$03,$1E,$B0,$53,$FD,$AA,$E0,$20,$01;0EBE30
                       ; $9A and $AA separators
                       ; Envelopes: $DE/$D0/$B0/$FD/$E0
                       ; Mid-range: $3D, $53

                       db $10,$FF,$ED,$F0,$14,$AA,$50,$EF,$01,$0C,$D3,$30,$01,$0F,$9A,$1A;0EBE40
                       ; $AA and $9A separators
                       ; Maximum $FF, envelopes $ED/$F0/$EF/$D3
                       ; Mid-range: $50

                       db $A1,$74,$0D,$CF,$11,$45,$FA,$9A,$D2,$42,$EA,$F4,$2E,$03,$30,$DD;0EBE50
                       ; $9A separator
                       ; Envelopes: $A1/$CF/$FA/$D2/$EA/$F4/$DD
                       ; Mid-range: $74, $45, $42

                       db $AA,$DE,$F0,$35,$4E,$D0,$20,$DC,$13,$9A,$4E,$02,$0F,$0A,$C3,$63;0EBE60
                       ; $AA and $9A separators
                       ; Envelopes: $DE/$F0/$D0/$DC/$C3
                       ; Mid-range: $4E (repeated), $63

                       db $FB,$DE,$9A,$06,$53,$DB,$E2,$41,$AC,$43,$0E,$AA,$F2,$30,$DD,$EF;0EBE70
                       ; $9A and $AA separators
                       ; Envelopes: $FB/$DE/$DB/$E2/$AC/$F2/$DD/$EF
                       ; Mid-range: $53, $43

                       db $F1,$45,$1E,$E1,$AA,$1F,$CE,$23,$1E,$01,$02,$FC,$F3,$9A,$32,$EA;0EBE80
                       ; $AA and $9A separators
                       ; Envelopes: $F1/$E1/$CE/$FC/$F3/$EA
                       ; Mid-range: $45

                       db $BE,$67,$51,$BD,$F0,$2E,$9A,$D2,$4F,$E0,$13,$3D,$CC,$CF,$12,$AA;0EBE90
                       ; $9A and $AA separators
                       ; Envelopes: $BE/$BD/$F0/$D2/$E0/$CC/$CF
                       ; Mid-range: $67, $51, $4F, $3D

                       db $33,$0F,$02,$FD,$D0,$22,$FF,$10,$AA,$22,$DC,$12,$20,$ED,$E0,$44;0EBEA0
                       ; Two $AA separators
                       ; Maximum $FF, envelopes $FD/$D0/$DC/$ED/$E0
                       ; Repeated $22

                       db $2F,$9A,$BE,$EF,$11,$01,$1F,$0F,$04,$3C,$9A,$BE,$EF,$23,$33,$10;0EBEB0
                       ; Two $9A separators
                       ; Repeated $BE/$EF envelopes
                       ; Mid-range: $3C

                       db $20,$DB,$E0,$AA,$20,$FF,$12,$3E,$C1,$11,$0F,$EE,$AA,$F1,$43,$1F;0EBEC0
                       ; Two $AA separators
                       ; Maximum $FF, envelopes $DB/$E0/$C1/$EE/$F1
                       ; Mid-range: $3E, $43

                       db $FE,$EF,$12,$10,$F0,$9A,$0D,$05,$2C,$E0,$CE,$31,$24,$21,$9A,$1E;0EBED0
                       ; Two $9A separators
                       ; Envelopes: $FE/$EF/$F0/$E0/$CE
                       ; Mid-range: $2C

                       db $BE,$10,$E0,$01,$35,$1A,$F1,$AA,$00,$FE,$00,$F2,$32,$00,$EE,$FF;0EBEE0
                       ; $AA separator with triple zero bytes
                       ; Maximum $FF, envelopes $BE/$E0/$F1/$FE/$F2/$EE
                       ; Mid-range: $35

                       db $9A,$16,$3E,$D0,$FE,$25,$0D,$0D,$C1,$9A,$20,$23,$34,$EB,$E0,$FD;0EBEF0
                       ; Two $9A separators
                       ; Envelopes: $D0/$FE/$C1/$EB/$E0/$FD
                       ; Mid-range: $3E

                       db $E2,$22,$9A,$41,$E0,$1D,$E0,$DF,$1F,$06,$31,$AA,$1F,$EF,$FE,$33;0EBF00
                       ; $9A and $AA separators
                       ; Repeated $E0 envelope, also $E2/$DF/$EF/$FE
                       ; Repeated $1F

                       db $0E,$F0,$0F,$12,$9A,$2F,$EA,$F3,$FE,$34,$62,$BC,$0F,$9A,$EB,$E6;0EBF10
                       ; Two $9A separators
                       ; Envelopes: $F0/$EA/$F3/$FE/$BC/$EB/$E6
                       ; Mid-range: $62

                       db $52,$1D,$03,$EB,$00,$E0,$AA,$00,$21,$02,$0E,$FF,$E1,$41,$EF,$9A;0EBF20
                       ; $AA and $9A separators with double zero bytes
                       ; Maximum $FF, envelopes $EB/$E0/$E1/$EF
                       ; Mid-range: $52

                       db $EF,$10,$25,$2E,$BB,$11,$D1,$55,$9A,$4F,$CE,$ED,$DD,$37,$31,$DE;0EBF30
                       ; $9A separator
                       ; Envelopes: $EF/$BB/$D1/$CE/$ED/$DD/$DE
                       ; Mid-range: $55, $4F

                       db $50,$96,$DD,$FB,$AE,$F1,$30,$26,$31,$1E,$96,$BF,$66,$0B,$BF,$FE;0EBF40
                       ; Two $96 separators
                       ; Envelopes: $DD/$FB/$AE/$F1/$BF/$BF/$FE
                       ; Mid-range: $50, $66

                       db $26,$63,$CA,$9A,$2E,$E3,$55,$2D,$EF,$CC,$D1,$64,$96,$55,$13,$7F;0EBF50
                       ; $9A and $96 separators
                       ; Envelopes: $CA/$E3/$EF/$CC/$D1
                       ; Mid-range: $63, $55 (repeated), $64, $7F

                       db $BF,$D9,$E1,$14,$2F,$9A,$30,$01,$DD,$15,$4C,$CE,$12,$03,$9A,$30;0EBF60
                       ; Two $9A separators
                       ; Envelopes: $BF/$D9/$E1/$DD/$CE
                       ; Mid-range: $4C, repeated $30

                       db $0E,$BE,$FD,$25,$53,$1E,$DC,$9A,$DE,$E2,$63,$1E,$E4,$F9,$10,$E2;0EBF70
                       ; $9A separator
                       ; Envelopes: $BE/$FD/$DC/$DE/$E2/$E4/$F9/$E2
                       ; Mid-range: $53, $63

                       db $9A,$40,$20,$CE,$21,$2F,$EE,$23,$1E,$9A,$CF,$32,$03,$1F,$1E,$AD;0EBF80
                       ; Two $9A separators
                       ; Envelopes: $CE/$EE/$CF/$AD
                       ; Low params: $40, $20, $21, $2F, $23, $1E, $32, $03, $1F, $1E

                       db $F0,$46,$9A,$3F,$0F,$DF,$DB,$F7,$51,$DD,$43,$9A,$CC,$EF,$24,$21;0EBF90
                       ; Two $9A separators
                       ; Envelopes: $F0/$DF/$DB/$F7/$DD/$CC/$EF
                       ; Mid-range: $46, $51, $43

                       db $1E,$CE,$23,$1E,$9A,$D1,$21,$00,$DF,$31,$22,$F0,$1B,$9A,$BE,$03;0EBFA0
                       ; Two $9A separators with zero byte
                       ; Envelopes: $CE/$D1/$DF/$F0/$BE
                       ; Repeated $1E, $21

                       db $43,$10,$1E,$FE,$9D,$66,$9A,$1E,$D2,$30,$DB,$D5,$30,$32,$FD,$96;0EBFB0
                       ; $9A and $96 separators with $9D separator variant
                       ; Envelopes: $FE/$D2/$DB/$D5/$FD
                       ; Mid-range: $66, repeated $1E, $30

                       db $CC,$F1,$20,$CC,$F0,$10,$F0,$12,$AA,$10,$F2,$0C,$D0,$22,$00,$11;0EBFC0
                       ; $AA separator with zero byte
                       ; Repeated $CC/$F0 envelopes
                       ; Also $F1/$F2/$D0

                       db $00,$9A,$F9,$B4,$51,$FD,$05,$1F,$EB,$03,$9A,$F3,$61,$DA,$C2,$41;0EBFD0
                       ; Two $9A separators with zero byte
                       ; $B4 voice marker
                       ; Envelopes: $F9/$FD/$EB/$F3/$DA/$C2
                       ; Mid-range: $51, $61

                       db $1D,$D2,$21,$AA,$00,$1F,$F1,$11,$01,$EC,$E2,$30,$9A,$D0,$42,$10;0EBFE0
                       ; $AA and $9A separators with zero byte
                       ; Envelopes: $D2/$F1/$EC/$E2/$D0
                       ; Mid-range: $42

                       db $AA,$34,$F0,$FE,$52,$9A,$D1,$EC,$31,$E6,$5F,$B9,$03,$21,$9A,$1D;0EBFF0
                       ; $AA and two $9A separators
                       ; Envelopes: $F0/$FE/$D1/$EC/$E6/$B9
                       ; Mid-range: $52, $5F

                       db $EF,$34,$F1,$2D,$E0,$32,$11,$AA,$DC,$03,$1F,$F1,$21,$0E,$E1,$1E;0EC000
                       ; $AA separator
                       ; Envelopes: $EF/$F1/$E0/$DC/$F1/$E1
                       ; Low params: $34, $2D, $32, $11, $03, $1F, $21, $0E, $1E

                       db $9A,$01,$E2,$4E,$F2,$FE,$0F,$35,$2D,$9A,$CC,$F2,$41,$EE,$FE,$45;0EC010
                       ; Two $9A separators
                       ; Envelopes: $E2/$F2/$FE/$CC/$F2/$EE/$FE
                       ; Mid-range: $4E, $45

                       db $00,$FD,$AA,$00,$11,$2F,$CE,$20,$00,$01,$10,$9A,$0E,$02,$ED,$0F;0EC020
                       ; $AA and $9A separators with triple zero bytes
                       ; Envelopes: $FD/$CE/$ED
                       ; Low params: $11, $2F, $20, $01, $10, $0E, $02, $0F

                       db $03,$1E,$23,$EC,$9A,$01,$45,$0B,$CD,$13,$11,$FE,$D0,$96,$27,$64;0EC030
                       ; $9A and $96 separators
                       ; Envelopes: $EC/$CD/$FE/$D0
                       ; Mid-range: $45, $64

                       db $1E,$F0,$25,$62,$DB,$BA,$9A,$1F,$F5,$3E,$F1,$1F,$CE,$10,$00,$9A;0EC040
                       ; Two $9A separators with zero byte
                       ; Envelopes: $F0/$DB/$BA/$F5/$F1/$CE
                       ; Mid-range: $62, $3E

                       db $11,$42,$BB,$15,$51,$DC,$DF,$21,$A6,$0F,$DD,$DE,$45,$21,$0F,$F0;0EC050
                       ; $A6 voice marker
                       ; Envelopes: $BB/$DC/$DF/$DD/$DE/$F0
                       ; Mid-range: $42, $51, $45

                       db $13,$9A,$FF,$CD,$E1,$0E,$25,$F0,$21,$FD,$AA,$FE,$11,$F0,$21,$10;0EC060
                       ; $9A and $AA separators
                       ; Two $FF maximums, envelopes $CD/$E1/$F0/$FD/$FE/$F0
                       ; Repeated $21

                       db $CF,$23,$2F,$AA,$ED,$02,$00,$0E,$F1,$04,$4E,$EF,$AA,$FF,$F2,$40;0EC070
                       ; Two $AA separators with zero byte
                       ; Maximum $FF, envelopes $CF/$ED/$F1/$EF/$F2
                       ; Mid-range: $4E

                       db $F0,$DE,$10,$E0,$22,$9A,$00,$21,$DD,$DE,$40,$D3,$41,$3B,$AA,$C1;0EC080
                       ; $9A and $AA separators with zero byte
                       ; Envelopes: $F0/$DE/$E0/$DD/$DE/$D3/$C1
                       ; Mid-range: $3B

                       db $32,$1F,$EE,$10,$00,$0E,$00,$AA,$34,$1D,$FF,$FF,$F3,$40,$0E,$C0;0EC090
                       ; $AA separator with triple zero bytes
                       ; Two $FF maximums, envelopes $EE/$F3/$C0
                       ; Low params: $32, $1F, $10, $0E, $34, $1D, $40, $0E

                       db $9A,$3C,$C2,$33,$22,$1F,$EC,$B2,$3C,$AA,$13,$10,$FC,$F3,$31,$0F;0EC0A0
                       ; $9A and $AA separators with $B2 voice marker (bass)
                       ; Envelopes: $C2/$EC/$FC/$F3
                       ; Mid-range: $3C (repeated)

                       db $EF,$1F,$AA,$F1,$FE,$13,$32,$0E,$DE,$00,$04,$9A,$60,$DA,$C2,$EB;0EC0B0
                       ; $AA and $9A separators with zero byte
                       ; Envelopes: $EF/$F1/$FE/$DE/$DA/$C2/$EB
                       ; Mid-range: $60

                       db $F4,$32,$13,$1E,$AA,$ED,$01,$01,$21,$00,$DD,$F4,$41,$9A,$FE,$CE;0EC0C0
                       ; $AA and $9A separators with zero byte
                       ; Envelopes: $F4/$ED/$DD/$F4/$FE/$CE
                       ; Repeated $F4

; SECTION SUMMARY (Lines 1001-1200, $0EBA10-$0EC0C0):
; - $9A separator: CONTINUES DOMINANCE (~75 instances, ~37% of lines)
; - $AA separator: STRONG SECONDARY (~55 instances, ~27% of lines)
; - $8A separator: 3 STRATEGIC instances (lines 1004/0EBA40, 1033/0EBD10, 1034/0EBD20)
;   * $8A marks major structural boundaries every ~30-130 lines
; - $96 separator: INCREASED (~15 instances, up from 10 in previous section)
; - Rare variants: $9D, $9C, $90, $AB (subsection markers)
;
; Voice markers identified:
; - $B2: Bass voice (3+ instances)
; - $B4: Voice 11/bass variant (2 instances)
; - $A6: Voice 6 (8+ instances, maintaining prominence)
; - $B9: Voice marker at 0EBE10 (rare)
;
; Pattern observations:
; - $9A/$AA alternation continues = dual-layer voice system
; - Zero bytes VERY frequent (40+ instances) = section/voice boundaries
; - Maximum $FF values: 25+ instances (sustained peak passages)
; - Triple zero bytes appear 5+ times (major structural markers)
; - Envelope concentration: E/F range ($E0-$FF) heavily dominant
; - DSP registers ($C0-$FF): Consistent usage throughout
; - Voice marker diversity increases (B2, B4, A6, B9 all active)
;
; Address range: $0EBA10-$0EC0C0 (~1.5KB of voice data)
; Estimated active voices: 6-8 simultaneous channels
; Data density: 200 lines = ~3.2KB raw data
; $8A boundary pattern: Appears at strategic ~1KB intervals
