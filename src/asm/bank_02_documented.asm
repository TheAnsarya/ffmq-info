; ===========================================================================
; Final Fantasy Mystic Quest - Bank $02 - Map/Graphics System
; ===========================================================================
; Size: 12,470 lines of disassembly
; Priority: High (core rendering system)
; ===========================================================================
; This bank contains map rendering and sprite management:
; - Tilemap loading and decompression
; - Sprite positioning and animation
; - Camera/scroll management
; - Map transitions
; - NPC movement and collision
; ===========================================================================

arch 65816
lorom

org $028000

; ===========================================================================
; Map System Initialization
; ===========================================================================
; Purpose: Initialize map rendering system and clear buffers
; Technical Details:
;   - Clears WRAM buffers for tilemaps
;   - Initializes sprite tables
;   - Sets up camera/scroll parameters
; ===========================================================================

CODE_028000:
    PHB                              ; Save data bank
    PHD                              ; Save direct page
    PHP                              ; Save processor status
    REP #$30                         ; 16-bit A,X,Y
    
    ; Set direct page to $0400 for fast access
    PEA.W $0400                      ; Push $0400
    PLD                              ; Pull to D register
    
    ; Clear $0400-$04FF (256 bytes) - Map state variables
    STZ.B $00                        ; Clear first word
    
    LDX.W #$0400                     ; Source address
    LDY.W #$0402                     ; Destination address
    LDA.W #$00FD                     ; 253 bytes to fill
    MVN $00,$00                      ; Block fill (same bank)
    
    ; Clear $0A00-$0A0C (12 bytes) - Sprite animation counters
    STZ.W $0A00                      ; Clear first word
    
    LDX.W #$0A00                     ; Source
    LDY.W #$0A02                     ; Destination
    LDA.W #$000A                     ; 10 bytes
    MVN $00,$00                      ; Block fill
    
    ; Clear $1100-$137F (640 bytes) - Tilemap buffer
    LDA.W #$FFFF                     ; Fill pattern (empty tile)
    STA.W $1100                      ; First word
    
    LDX.W #$1100                     ; Source
    LDY.W #$1102                     ; Destination
    LDA.W #$027D                     ; 637 bytes
    MVN $00,$00                      ; Block fill
    
    ; Copy sprite configuration from Bank $02
    LDX.W #$8F4A                     ; Source: $028F4A
    LDY.W #$0496                     ; Dest: $000496
    LDA.W #$0009                     ; 10 bytes
    MVN $00,$02                      ; Copy from Bank $02
    
    ; Clear $1000-$10FF (256 bytes) - NPC state tables
    LDX.W #$1000                     ; Source
    LDY.W #$1800                     ; Destination  
    LDA.W #$00FF                     ; 256 bytes
    MVN $00,$00                      ; Block fill
    
    PHK                              ; Push program bank
    PLB                              ; Set as data bank
    
    SEP #$20                         ; 8-bit A
    REP #$10                         ; 16-bit X,Y
    
    ; Check if loading saved map state
    LDA.W $0513                      ; Get save state flag
    CMP.B #$FF                       ; Check if valid
    BEQ CODE_028060                  ; If invalid, skip restore
    
    STA.W $0514                      ; Restore map ID
    
CODE_028060:
    ; Initialize map subsystems
    JSR.W CODE_028C06                ; Load tilemap data
    
    JSL.L CODE_02DA98                ; Decompress tilemap (SimpleTailWindowCompression)
    
    SEP #$20                         ; 8-bit A
    REP #$10                         ; 16-bit X,Y
    
    ; Initialize sprite system
    LDA.B #$FF                       ; Invalid sprite marker
    STA.W $0A84                      ; Clear active sprite
    
    JSL.L CODE_02D149                ; Initialize sprite tables
    
    SEP #$20                         ; 8-bit A
    REP #$10                         ; 16-bit X,Y
    
    JSR.W CODE_028187                ; Check map escape conditions
    
    STZ.B $B5                        ; Clear escape counter (DP $04B5)
    
    ; Initialize NPC collision tables
    LDA.B #$FF                       ; Invalid marker
    STA.W $1050                      ; NPC 0 collision state
    STA.W $1051                      ; NPC 1 collision state
    STA.W $1052                      ; NPC 2 collision state
    STA.W $10D0                      ; NPC 3 collision state
    STA.W $10D1                      ; NPC 4 collision state
    STA.W $10D2                      ; NPC 5 collision state
    
    ; Check for special map mode
    LDA.B $76                        ; Get map flags (DP $0476)
    DEC A                            ; Check if = 1
    BEQ CODE_0280AA                  ; If so, skip input check
    
CODE_028096:
    ; Wait for controller input
    JSL.L CODE_00D2A6                ; Read joypad
    
    LDA.W $1020                      ; Get button state
    AND.B #$40                       ; Check Start button (bit 6)
    BEQ CODE_0280AA                  ; If not pressed, continue
    
    ; Start button pressed - attempt map escape
    JSR.W CODE_028219                ; Check if escape allowed
    INC A                            ; Check return value
    BNE CODE_0280AA                  ; If allowed, continue normally
    
    JMP.W CODE_02815F                ; Execute map escape
    
CODE_0280AA:
    ; Initialize sprite animation loop
    JSR.W CODE_0282F9                ; Load sprite graphics
    
    STZ.B $89                        ; Clear sprite index (DP $0489)
    
CODE_0280AF:
    ; Process each active sprite
    LDA.B #$00                       ; Clear high byte
    XBA                              ; Swap to accumulator high
    
    LDA.B $89                        ; Get sprite index
    TAX                              ; Transfer to X
    
    LDA.B $7C,X                      ; Get sprite ID from table (DP $047C)
    STA.B $8B                        ; Store current sprite (DP $048B)
    
    PHD                              ; Save direct page
    JSR.W CODE_028F22                ; Get sprite data pointer
    
    LDA.B $21                        ; Get sprite flags (DP $1021)
    XBA                              ; Swap to high byte
    LDA.B $10                        ; Get sprite state (DP $1010)
    
    PLD                              ; Restore direct page
    
    INC A                            ; Check if sprite active
    BEQ CODE_02810F                  ; If not, skip sprite
    
    XBA                              ; Swap back
    AND.B #$C0                       ; Check high bits (dead/disabled)
    BNE CODE_02810F                  ; If set, skip sprite
    
    ; Process sprite collision
    JSR.W CODE_0283A8                ; Check sprite collision
    
    REP #$30                         ; 16-bit A,X,Y
    PHD                              ; Save direct page
    
    JSR.W CODE_028F22                ; Get sprite data
    
    ; Clear sprite priority bits
    LDA.B $42                        ; Get sprite attribute 0 (DP $1042)
    AND.W #$7F7F                     ; Clear priority bits (bit 7)
    STA.B $42                        ; Store back
    
    LDA.B $44                        ; Get sprite attribute 1
    AND.W #$7F7F                     ; Clear priority bits
    STA.B $44                        ; Store back
    
    LDA.B $46                        ; Get sprite attribute 2
    AND.W #$7F7F                     ; Clear priority bits
    STA.B $46                        ; Store back
    
    LDA.B $48                        ; Get sprite attribute 3
    AND.W #$7F7F                     ; Clear priority bits
    STA.B $48                        ; Store back
    
    LDA.B $4A                        ; Get sprite attribute 4
    AND.W #$7F7F                     ; Clear priority bits
    STA.B $4A                        ; Store back
    
    SEP #$20                         ; 8-bit A
    REP #$10                         ; 16-bit X,Y
    
    ; Clear NPC collision states
    LDA.B #$FF                       ; Invalid marker
    STA.B $50                        ; NPC collision 0 (DP $1050)
    STA.B $51                        ; NPC collision 1 (DP $1051)
    STA.B $52                        ; NPC collision 2 (DP $1052)
    
    PLD                              ; Restore direct page
    
    ; Update sprite graphics
    JSR.W CODE_028725                ; Render sprite
    
    LDA.B $95                        ; Get sprite error flag (DP $0495)
    BNE CODE_02813F                  ; If error, handle failure
    
    LDA.B $94                        ; Get sprite warning flag (DP $0494)
    BNE CODE_028157                  ; If warning, handle partial failure
    
CODE_02810F:
    ; Next sprite
    INC.B $89                        ; Increment sprite index
    
    LDA.B $89                        ; Get current index
    CMP.B $8A                        ; Compare to sprite count (DP $048A)
    BCC CODE_0280AF                  ; If more sprites, continue loop
    
    ; All sprites processed - update display
    JSR.W CODE_02886B                ; Transfer sprites to OAM
    JSR.W CODE_028725                ; Final render pass
    
    LDA.B $95                        ; Check error flag again
    BNE CODE_02813F                  ; Handle error
    
    LDA.B $94                        ; Check warning flag
    BNE CODE_028157                  ; Handle warning
    
    ; Clear all sprite states
    STZ.B $8B                        ; Clear sprite ID
    
CODE_028127:
    ; Clear sprite active flags loop
    PHD                              ; Save direct page
    JSR.W CODE_028F22                ; Get sprite data
    
    LDA.B $20                        ; Get sprite flags (DP $1020)
    AND.B #$8F                       ; Clear active bits (bits 4-6)
    STA.B $20                        ; Store back
    
    PLD                              ; Restore direct page
    
    INC.B $8B                        ; Next sprite
    LDA.B $8B                        ; Get sprite ID
    CMP.B #$05                       ; Check if all 5 sprites processed
    BCC CODE_028127                  ; Continue loop
    
    INC.B $B5                        ; Increment frame counter (DP $04B5)
    JMP.W CODE_028096                ; Return to input check
    
CODE_02813F:
    ; Sprite error handler - play error sound
    LDA.B #$7A                       ; Sound effect $7A (error beep)
    JSL.L CODE_009776                ; Play sound effect
    
    BNE CODE_02814C                  ; If sound played, skip flag set
    
    LDA.B #$04                       ; Error code 4
    STA.W $0500                      ; Store error code
    
CODE_02814C:
    ; Show error message
    LDX.W #$D4F1                     ; Error message pointer
    JSR.W CODE_028835                ; Display message
    
    JSR.W CODE_028938                ; Wait for confirmation
    BRA CODE_028163                  ; Continue
    
CODE_028157:
    ; Sprite warning handler
    LDX.W #$D4DF                     ; Warning message pointer
    JSR.W CODE_028835                ; Display message
    BRA CODE_028163                  ; Continue
    
CODE_02815F:
    ; Map escape handler
    SEP #$20                         ; 8-bit A
    REP #$10                         ; 16-bit X,Y
    
CODE_028163:
    ; Cleanup and return
    JSL.L CODE_02D132                ; Save map state
    
    ; Reset sprite velocities to base values
    LDA.B #$01                       ; Starting sprite index
    STA.B $8B                        ; Store sprite ID
    
CODE_02816B:
    ; Velocity reset loop
    PHD                              ; Save direct page
    JSR.W CODE_028F22                ; Get sprite data
    
    LDX.W #$0003                     ; 4 components to copy
    
CODE_028172:
    ; Copy base velocity to current velocity
    LDA.B $4C,X                      ; Get base velocity component (DP $104C)
    STA.B $26,X                      ; Store to active velocity (DP $1026)
    
    CLC                              ; Clear carry
    ADC.B $2A,X                      ; Add delta (DP $102A)
    STA.B $22,X                      ; Store to movement vector (DP $1022)
    
    DEX                              ; Next component
    BPL CODE_028172                  ; Continue loop (X,Y,Z,flags)
    
    PLD                              ; Restore direct page
    
    DEC.B $8B                        ; Previous sprite
    BPL CODE_02816B                  ; Continue if more sprites
    
    PLP                              ; Restore processor status
    PLD                              ; Restore direct page
    PLB                              ; Restore data bank
    RTL                              ; Return to caller

; ===========================================================================
; Check Map Escape Conditions
; ===========================================================================
; Purpose: Determine if player can escape from current map
; Returns: A = 0 if can escape, non-zero if blocked
; Technical Details:
;   - Checks map flags and difficulty settings
;   - Calculates escape probability based on stats
;   - Uses RNG for escape chance
; ===========================================================================

CODE_028187:
    SEP #$20                         ; 8-bit A
    REP #$10                         ; 16-bit X,Y
    
    ; Check if escape disabled by flags
    LDA.B $AF                        ; Get map flags (DP $04AF)
    AND.B #$80                       ; Check bit 7 (escape disabled)
    BNE CODE_028207                  ; If set, block escape
    
    ; Calculate escape difficulty
    LDA.W $1110                      ; Get player level
    CLC
    ADC.W $1190                      ; Add bonus stat 1
    CLC
    ADC.W $1190                      ; Add bonus stat 1 again (2x multiplier)
    INC A                            ; +1
    INC A                            ; +2
    INC A                            ; +3 (total formula: level + 2*bonus + 3)
    
    ; Divide by difficulty factor
    STA.W $4204                      ; Store to dividend low
    STZ.W $4205                      ; Clear dividend high
    
    LDA.B $B3                        ; Get difficulty factor (DP $04B3)
    STA.W $4206                      ; Store to divisor
    
    ; Get enemy level equivalent
    LDA.W $1010                      ; Enemy base stat
    STA.B $A0                        ; Store temporarily (DP $04A0)
    
    LDA.W $1090                      ; Enemy modifier
    BMI CODE_0281BA                  ; If negative, skip adjustment
    
    CLC
    ADC.B $A0                        ; Add to base
    LSR A                            ; Divide by 2 (average)
    STA.B $A0                        ; Store result
    
CODE_0281BA:
    ; Calculate escape chance
    LDA.W $4214                      ; Get division result (quotient)
    SEC
    SBC.B $A0                        ; Subtract enemy level
    BEQ CODE_028204                  ; If equal, auto-fail escape
    BPL CODE_0281C7                  ; If positive, continue
    
    ; Make positive (absolute value)
    EOR.B #$FF                       ; Invert bits
    INC A                            ; Add 1 (two's complement)
    
CODE_0281C7:
    ; Cap maximum penalty
    PHA                              ; Save difference
    LDA.B #$00                       ; Clear high byte
    SBC.B #$00                       ; Subtract with carry (sign extend)
    STA.B $A0                        ; Store sign
    
    PLA                              ; Restore difference
    CMP.B #$0B                       ; Compare to max (11)
    BCC CODE_0281D5                  ; If below, use as-is
    
    LDA.B #$0A                       ; Cap at 10
    
CODE_0281D5:
    ; Calculate penalty percentage
    STA.W $4202                      ; Multiplicand
    
    LDA.B #$0A                       ; Multiplier = 10
    STA.W $4203                      ; Start multiplication
    
    LDA.B #$64                       ; Base chance = 100%
    SEC
    SBC.W $4216                      ; Subtract penalty (result of multiply)
    STA.B $A2                        ; Store final escape chance (DP $04A2)
    
    ; Roll random number
    LDA.B #$65                       ; RNG seed/command
    STA.W $00A8                      ; Set RNG parameter
    
    JSL.L CODE_009783                ; Get random number
    
    LDA.W $00A9                      ; Get random result
    CMP.B $A2                        ; Compare to escape chance
    BCC CODE_028204                  ; If below, escape fails
    
    ; Escape succeeds
    LDA.B $A0                        ; Get sign flag
    BEQ CODE_028207                  ; If positive difference, full success
    
    ; Partial escape - show message
    LDX.W #$D281                     ; "Escaped!" message pointer
    JSR.W CODE_028835                ; Display message
    
    LDA.B #$02                       ; Set escape state = 2
    STA.B $76                        ; Store state (DP $0476)
    RTS                              ; Return
    
CODE_028204:
    ; Escape failed
    STZ.B $76                        ; Clear escape state
    RTS                              ; Return
    
CODE_028207:
    ; Check minimum map level requirement
    LDA.W $0514                      ; Get current map ID
    CMP.B #$14                       ; Compare to threshold (map $14)
    BCS CODE_028204                  ; If >= $14, block escape
    
    ; Early game maps - show different message
    LDX.W #$D28D                     ; "Can't escape yet!" message
    JSR.W CODE_028835                ; Display message
    
    LDA.B #$01                       ; Set escape state = 1 (blocked)
    STA.B $76                        ; Store state
    RTS                              ; Return

;===============================================================================
; Progress: Bank $02 Initial Documentation  
; Lines documented: ~420 / 12,470 (3.4%)
; Focus: Map initialization, sprite rendering, escape system
; Next: Tilemap decompression, camera system, NPC AI
;===============================================================================
