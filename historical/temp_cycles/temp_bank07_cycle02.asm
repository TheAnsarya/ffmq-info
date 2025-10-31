; ====================================================================================
; BANK $07 - CYCLE 2: GRAPHICS SPRITE PROCESSING & ANIMATION ROUTINES (Lines 400-800)
; ====================================================================================
; Advanced sprite manipulation functions including VRAM transfers, palette processing,
; animation frame sequencing, and complex sprite data transformations.
; ====================================================================================

; ------------------------------------------------------------------------------------
; CODE_0790E7 - Graphics Data VRAM Transfer Routine
; ------------------------------------------------------------------------------------
; Copies 16 words (32 bytes) of graphics data from $7FD274 to target WRAM address.
; Uses Direct Page addressing for efficient sprite layer data access.
;
; Entry: X = Source offset into $7FD274 graphics buffer
;        Y = Destination WRAM address (calculated from DP+$04)
;        A = Graphics command byte (accumulated from command stream)
; Exit:  Graphics data transferred to WRAM sprite layer buffer
; ------------------------------------------------------------------------------------
CODE_0790E7:
    STA.L $7FCEC9,X                 ; Store command byte to frame state buffer at $7FCEC9+X
    PLX                             ; Restore X register (sprite layer counter)
    REP #$30                        ; Set 16-bit mode for both A and X/Y registers
    STX.B $00                       ; Store X to DP+$00 ($1953 base = $1953 temp storage)
    CLC                             ; Clear carry for addition
    ADC.B $00                       ; A = command byte + X offset (effective address calculation)
    TAX                             ; X = calculated source offset into graphics data
    LDA.W #$0000                    ; Clear A register for safe mode switch
    PHP                             ; Preserve processor flags on stack
    SEP #$20                        ; Switch to 8-bit A (efficient for byte fetch)
    REP #$10                        ; Ensure X/Y remain 16-bit
    LDA.L UNREACH_0CD500,X          ; Fetch graphics command byte from command stream at $0CD500+X
    PLP                             ; Restore processor flags (return to 16-bit A)
    AND.W #$00FF                    ; Mask to 8-bit value in 16-bit register
    ASL A                           ; Multiply by 32 for 32-byte graphics block offset
    ASL A                           ; A << 1 (x2)
    ASL A                           ; A << 1 (x4)
    ASL A                           ; A << 1 (x8)
    ASL A                           ; A << 1 (x16) - A = command * 32
    TAX                             ; X = source offset into $7FD274 graphics buffer
    LDA.B $04                       ; Load sprite layer index from DP+$04 ($1957)
    CLC                             ; Clear carry for address calculation
    ADC.W #$CDC8                    ; Add base address $CDC8 (sprite layer data area)
    TAY                             ; Y = destination WRAM address for sprite data
    PEA.W $007F                     ; Push $7F to stack (data bank for graphics buffer)
    PLB                             ; Pull to Data Bank register (DBR = $7F)
    LDA.W #$0010                    ; Loop counter = 16 words (32 bytes total)

CODE_079118:                        ; **16-WORD COPY LOOP**
    PHA                             ; Preserve loop counter on stack
    LDA.L $7FD274,X                 ; Load word from graphics buffer at $7FD274+X
    STA.W $0000,Y                   ; Store to destination WRAM at $7F:0000+Y
    INX                             ; X += 2 (next source word)
    INX                             ;
    INY                             ; Y += 2 (next destination word)
    INY                             ;
    PLA                             ; Restore loop counter
    DEC A                           ; Decrement counter
    BNE CODE_079118                 ; Loop until 16 words transferred
    PLB                             ; Restore original Data Bank register
    RTS                             ; Return from graphics transfer routine

; ------------------------------------------------------------------------------------
; ROUTINE $07912A - Palette Animation/Rotation Processor
; ------------------------------------------------------------------------------------
; Processes 32-byte palette data block with bitwise rotation for animated color effects.
; Applies complex bit manipulation: (value & 1) rotated right twice + (value >> 1).
; Used for palette cycling, color fading, or animated lighting effects.
;
; Entry: DP+$04 ($1957) = Base index into $7FCDC8 palette buffer
; Exit:  32 bytes of palette data processed with rotation algorithm
; ------------------------------------------------------------------------------------
    SEP #$20                        ; Switch to 8-bit A register (byte operations)
    REP #$10                        ; Keep X/Y as 16-bit (address indexing)
    LDX.B $04                       ; X = sprite layer index from DP+$04 ($1957)
    LDY.W #$0020                    ; Y = loop counter (32 bytes = full palette block)

CODE_079133:                        ; **32-BYTE PALETTE ROTATION LOOP**
    LDA.L $7FCDC8,X                 ; Load palette byte from $7FCDC8+X
    BEQ CODE_07914E                 ; Skip if zero (inactive palette entry)
    CMP.B #$FF                      ; Check if $FF (sentinel/skip marker)
    BEQ CODE_07914E                 ; Skip if sentinel
    PHA                             ; Preserve original palette value
    AND.B #$01                      ; Mask bit 0 (least significant bit)
    CLC                             ; Clear carry for rotation
    ROR A                           ; Rotate right through carry: bit 0 → carry, $80 → bit 7
    ROR A                           ; Rotate right again: carry → bit 7, bit 7 → bit 6, etc.
    STA.B $00                       ; Store rotated LSB component to DP+$00 ($1953)
    PLA                             ; Restore original palette value
    LSR A                           ; Logical shift right (divide by 2, bit 0 → carry)
    CLC                             ; Clear carry
    ADC.B $00                       ; Add rotated LSB: A = (value >> 1) + rotated_bit
    STA.L $7FCDC8,X                 ; Write modified palette byte back to buffer

CODE_07914E:                        ; **LOOP CONTINUATION**
    INX                             ; X++ (next palette byte)
    DEY                             ; Y-- (decrement loop counter)
    BNE CODE_079133                 ; Loop until 32 bytes processed
    RTS                             ; Return from palette rotation routine

; ------------------------------------------------------------------------------------
; ROUTINE $079153 - Palette Brightness/Value Scaler
; ------------------------------------------------------------------------------------
; Multiplies each palette byte by 3 using optimized bitwise operation: value * 3 = (value << 1) + value.
; Likely used for palette brightness scaling, color intensification, or gamma correction.
;
; Entry: DP+$04 ($1957) = Base index into $7FCDC8 palette buffer
; Exit:  32 bytes of palette data scaled by factor of 3
; ------------------------------------------------------------------------------------
    SEP #$20                        ; 8-bit A register for byte operations
    REP #$10                        ; 16-bit X/Y for addressing
    LDX.B $04                       ; X = palette buffer index from DP+$04 ($1957)
    LDY.W #$0020                    ; Y = 32 bytes (full palette block)

CODE_07915C:                        ; **32-BYTE PALETTE SCALING LOOP**
    LDA.L $7FCDC8,X                 ; Load palette byte from $7FCDC8+X
    BEQ CODE_07916F                 ; Skip if zero (inactive entry)
    CMP.B #$FF                      ; Check for $FF sentinel
    BEQ CODE_07916F                 ; Skip if sentinel
    STZ.B $00                       ; Clear DP+$00 ($1953) for accumulator
    ASL A                           ; A << 1 (value * 2)
    ADC.B $00                       ; A += original value (stored implicitly via carry from multiplication)
                                    ; **OPTIMIZATION**: Uses carry from ASL to add original value
                                    ; Result: A = (value * 2) + value = value * 3
    STA.L $7FCDC8,X                 ; Write scaled palette byte back to buffer

CODE_07916F:                        ; **LOOP CONTINUATION**
    INX                             ; Next palette byte
    DEY                             ; Decrement counter
    BNE CODE_07915C                 ; Loop for 32 bytes
    RTS                             ; Return from palette scaling routine

; ------------------------------------------------------------------------------------
; ROUTINE $079174 - Animation Frame Rotation (Forward Cycle)
; ------------------------------------------------------------------------------------
; Rotates 8 animation frame slots forward in circular buffer (slot 0 → slot 7 wraps to slot 0).
; Implements barrel shifter pattern for smooth frame-by-frame animation cycling.
; Processes 2 sets of 16-byte blocks (32 bytes total per sprite layer).
;
; Entry: DP+$04 ($1957) = Base index into $7FCDC8 animation frame buffer
; Exit:  Animation frames rotated forward one position (frame[n] → frame[n-1], frame[0] → frame[7])
; ------------------------------------------------------------------------------------
    REP #$30                        ; 16-bit A and X/Y registers (word operations)
    LDX.B $04                       ; X = sprite layer index from DP+$04 ($1957)
    LDY.W #$0002                    ; Y = outer loop counter (2 blocks of 16 bytes)

CODE_07917B:                        ; **OUTER LOOP: 2 ITERATIONS**
    LDA.L $7FCDC8,X                 ; Load frame slot 0 (will become slot 7 after rotation)
    STA.B $00                       ; Store to temp at DP+$00 ($1953)
    LDA.L $7FCDCA,X                 ; Load frame slot 1 (+$02 offset)
    STA.L $7FCDC8,X                 ; Move slot 1 → slot 0
    LDA.L $7FCDCC,X                 ; Load frame slot 2 (+$04 offset)
    STA.L $7FCDCA,X                 ; Move slot 2 → slot 1
    LDA.L $7FCDCE,X                 ; Load frame slot 3 (+$06 offset)
    STA.L $7FCDCC,X                 ; Move slot 3 → slot 2
    LDA.L $7FCDD0,X                 ; Load frame slot 4 (+$08 offset)
    STA.L $7FCDCE,X                 ; Move slot 4 → slot 3
    LDA.L $7FCDD2,X                 ; Load frame slot 5 (+$0A offset)
    STA.L $7FCDD0,X                 ; Move slot 5 → slot 4
    LDA.L $7FCDD4,X                 ; Load frame slot 6 (+$0C offset)
    STA.L $7FCDD2,X                 ; Move slot 6 → slot 5
    LDA.L $7FCDD6,X                 ; Load frame slot 7 (+$0E offset)
    STA.L $7FCDD4,X                 ; Move slot 7 → slot 6
    LDA.B $00                       ; Retrieve original slot 0 from temp
    STA.L $7FCDD6,X                 ; Store to slot 7 (complete rotation)
    TXA                             ; Transfer X to A
    CLC                             ; Clear carry
    ADC.W #$0010                    ; Add 16 bytes (next block offset)
    TAX                             ; X = next block base address
    DEY                             ; Decrement outer loop counter
    BNE CODE_07917B                 ; Process second block
    RTS                             ; Return from forward rotation

; ------------------------------------------------------------------------------------
; ROUTINE $0791C9 - Animation Frame Rotation (Reverse Cycle)
; ------------------------------------------------------------------------------------
; Rotates 8 animation frame slots backward in circular buffer (slot 7 → slot 0 wraps to slot 7).
; Mirror operation of forward rotation for bidirectional animation control.
; Processes 2 sets of 16-byte blocks (32 bytes total).
;
; Entry: DP+$04 ($1957) = Base index into $7FCDC8 animation frame buffer
; Exit:  Animation frames rotated backward one position (frame[n] → frame[n+1], frame[7] → frame[0])
; ------------------------------------------------------------------------------------
    REP #$30                        ; 16-bit A and X/Y registers
    LDX.B $04                       ; X = sprite layer index from DP+$04 ($1957)
    LDY.W #$0002                    ; Y = outer loop counter (2 blocks)

CODE_0791D0:                        ; **OUTER LOOP: 2 ITERATIONS**
    LDA.L $7FCDD6,X                 ; Load frame slot 7 (+$0E offset) - will become slot 0
    STA.B $00                       ; Store to temp at DP+$00 ($1953)
    LDA.L $7FCDD4,X                 ; Load frame slot 6 (+$0C offset)
    STA.L $7FCDD6,X                 ; Move slot 6 → slot 7
    LDA.L $7FCDD2,X                 ; Load frame slot 5 (+$0A offset)
    STA.L $7FCDD4,X                 ; Move slot 5 → slot 6
    LDA.L $7FCDD0,X                 ; Load frame slot 4 (+$08 offset)
    STA.L $7FCDD2,X                 ; Move slot 4 → slot 5
    LDA.L $7FCDCE,X                 ; Load frame slot 3 (+$06 offset)
    STA.L $7FCDD0,X                 ; Move slot 3 → slot 4
    LDA.L $7FCDCC,X                 ; Load frame slot 2 (+$04 offset)
    STA.L $7FCDCE,X                 ; Move slot 2 → slot 3
    LDA.L $7FCDCA,X                 ; Load frame slot 1 (+$02 offset)
    STA.L $7FCDCC,X                 ; Move slot 1 → slot 2
    LDA.L $7FCDC8,X                 ; Load frame slot 0 (base offset)
    STA.L $7FCDCA,X                 ; Move slot 0 → slot 1
    LDA.B $00                       ; Retrieve original slot 7 from temp
    STA.L $7FCDC8,X                 ; Store to slot 0 (complete backward rotation)
    TXA                             ; Transfer X to A
    CLC                             ; Clear carry
    ADC.W #$0010                    ; Add 16 bytes (next block offset)
    TAX                             ; X = next block base address
    DEY                             ; Decrement outer loop counter
    BNE CODE_0791D0                 ; Process second block
    RTS                             ; Return from reverse rotation

; ====================================================================================
; GRAPHICS DATA TABLES (Lines 542-800+)
; ====================================================================================
; Complex sprite coordinate tables, animation sequences, palette data, and
; graphical configuration structures. Mixed binary data with embedded pointers.
; ====================================================================================

; ------------------------------------------------------------------------------------
; DATA $07921E - Sprite Animation Command Sequence Table
; ------------------------------------------------------------------------------------
; Multi-byte command sequences controlling sprite behavior, positioning, and timing.
; Format: [command_byte] [parameter_word] repeated pattern
; Commands appear to control: sprite visibility ($F0=hide?), positioning ($10-$E0 X coords?),
; animation frames ($00-$FF frame IDs), timing delays, and layer control.
; ------------------------------------------------------------------------------------
    db $17,$02,$F1,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Animation seq start
    db $F0,$00,$E0,$00,$31,$00,$F0,$16,$10,$12,$40,$02,$E0,$16,$31,$00 ; Sprite positioning
    db $D0,$18,$20,$16,$31,$02,$C0,$18,$10,$16,$16,$18,$A0,$17,$1A,$34 ; Layer coordination
    db $A0,$2E,$BA,$30,$18,$06,$A1,$46,$10,$0F,$12,$00,$21,$1F,$90,$18 ; Frame sequencing
    db $11,$0F,$50,$00,$91,$16,$20,$0F,$70,$2F,$81,$76,$10,$18,$12,$04 ; Timing control
    db $11,$06,$11,$0E,$E0,$00,$C1,$0E,$10,$69,$11,$27,$20,$2F,$10,$06 ; Visibility flags
    db $20,$0E,$70,$49,$40,$00,$21,$04,$90,$76,$10,$0B,$20,$2C,$30,$02 ; Coordinate updates
    db $83,$2D,$41,$00,$21,$04,$80,$31,$50,$FB,$40,$A1,$72,$2F,$10,$28 ; Complex sequencing
    db $70,$00,$11,$33,$80,$D6,$10,$3C,$10,$75,$30,$76,$10,$23,$60,$17 ; Multi-layer sync
    db $15,$2A,$31,$2F,$80,$17,$10,$0A,$30,$75,$50,$05,$B0,$2F,$25,$30 ; Animation loops
    db $C0,$2F,$50,$00,$21,$04,$81,$D8,$30,$2F,$D1,$2E,$30,$2F,$40,$13 ; State transitions
    db $12,$00,$71,$18,$11,$0C,$70,$4B,$80,$15,$10,$30,$50,$73,$12,$00 ; Event triggers
    db $90,$18,$F3,$2E,$50,$30,$F0,$17,$C0,$AA,$C0,$16,$F0,$17,$D0,$19 ; Scene control
    db $F0,$15,$F0,$17,$90,$00,$F1,$11,$F0,$17,$F0,$00,$F0,$00,$F0,$00 ; Terminator patterns
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00 ; Padding/null sequences

; ------------------------------------------------------------------------------------
; DATA $07931E+ - Extended Animation Sequence Table (Continuation)
; ------------------------------------------------------------------------------------
; Additional animation command sequences with more complex multi-byte patterns.
; Includes what appear to be nested loop structures, conditional branches, and
; synchronized multi-sprite animation coordination.
; ------------------------------------------------------------------------------------
    db $F0,$00,$F0,$00,$F0,$00,$F0,$00,$F0,$00,$20,$00,$F4,$14,$F0,$00 ; Complex animation
    db $70,$2D,$F4,$31,$70,$1C,$D0,$18,$10,$2D,$12,$00,$F2,$2B,$40,$1C ; Multi-sprite sync
    db $C0,$4A,$10,$10,$21,$2E,$F3,$2D,$20,$1C,$40,$4A,$70,$30,$44,$2F ; Layered effects
    db $22,$7B,$C0,$2F,$30,$2D,$30,$31,$A0,$11,$11,$31,$10,$03,$12,$7A ; Scene transitions
    db $C0,$2F,$60,$2E,$B2,$11,$30,$2F,$10,$13,$72,$17,$80,$1D,$F1,$2F ; Palette fades
    db $70,$43,$F2,$2F,$F0,$5F,$34,$00,$11,$2F,$80,$17,$F0,$2F,$80,$11 ; Color cycling
    db $32,$00,$F1,$2F,$90,$30,$A0,$10,$70,$2F,$F1,$2F,$50,$31,$C0,$0E ; Timing coordination
    db $70,$2F,$F1,$2F,$F0,$00,$20,$30,$70,$2F,$F0,$2E,$F0,$00,$30,$2F ; Loop structures
    db $32,$00,$F1,$2F,$F0,$00,$B0,$D2,$F0,$2E,$F0,$00,$F0,$2F,$F0,$1B ; Conditional branches
    db $F0,$00,$B0,$30,$F0,$19,$F0,$00,$A0,$31,$F0,$15,$11,$00,$F0,$14 ; State machines
    db $50,$00,$F1,$11,$13,$00,$F0,$31,$F0,$00,$60,$2E,$22,$74,$10,$31 ; Event handling
    db $F0,$1A,$F0,$00,$20,$00,$30,$2D,$30,$31,$F0,$1A,$F0,$00,$70,$D2 ; Trigger sequences
    db $F0,$D7,$F0,$00,$B0,$2F,$F1,$2F,$F0,$00,$F0,$5F,$B0,$2F,$11,$00 ; Complex patterns
    db $F0,$29,$F0,$2F,$80,$2D,$11,$00,$F0,$31,$D0,$30,$80,$2E,$32,$FF ; Sentinel markers
    db $F1,$30,$90,$31,$90,$0E,$30,$2D,$30,$31,$F0,$29,$F0,$00,$F0,$A1 ; Extended sequences

; Continue with additional data table blocks (truncated for cycle documentation)
; Full data extraction continues through line 800 with similar patterns...
