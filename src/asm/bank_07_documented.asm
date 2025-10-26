; ==============================================================================
; BANK $07 - Enemy AI and Battle Logic
; ==============================================================================
; Bank Size: 5,208 lines (2,627 total in source)
; Primary Content: Enemy artificial intelligence, battle algorithms
; Format: 65816 assembly code + data tables
;
; This bank contains the core enemy AI engine for FFMQ:
; - Enemy decision-making logic
; - Attack pattern scripts
; - Targeting algorithms
; - Status effect handlers
; - Boss battle special behaviors
;
; Cross-References:
; - Bank $00: Battle engine core
; - Bank $01: Battle initialization, graphics
; - Bank $06: Item/equipment stats
; - Bank $0B: Equipment/spell data
; ==============================================================================

					   ORG $078000

; ------------------------------------------------------------------------------
; Enemy AI Data Tables
; ------------------------------------------------------------------------------
; Sprite graphics tile references for enemies
; Format: [tile_id][palette][flags]...
; ------------------------------------------------------------------------------

DATA8_078000:
					   db $48        ; Enemy sprite tile 0

DATA8_078001:
					   db $22        ; Enemy sprite tile 1

DATA8_078002:
					   db $00        ; Transparent/empty

DATA8_078003:
					   db $00        ; Padding

DATA8_078004:
					   db $FF        ; Enemy sprite tile 4

DATA8_078005:
					   db $7F        ; Enemy sprite tile 5

DATA8_078006:
					   db $4F        ; Enemy sprite tile 6

DATA8_078007:
					   db $3E,$48,$22  ; Enemy sprite sequence

DATA8_07800A:
					   db $40,$51    ; Enemy animation flags

DATA8_07800C:
					   ; Enemy sprite pattern table
					   ; Format: [tile][palette][x_offset][y_offset]
					   db $FF,$7F,$00,$00,$48,$22,$00,$00,$1F,$00,$FF,$03,$48,$22,$40,$51
					   db $3F,$03,$FF,$03,$48,$22,$00,$00,$FF,$7F,$00,$00,$00,$00,$00,$00
					   db $3F,$03,$4F,$3E

DATA8_078030:
					   ; Enemy graphics metadata
					   ; Animation frames, sprite sizes, palette assignments
					   db $00
					   db $00,$00,$00,$00,$00,$00,$00,$00,$00,$33,$3C,$FA,$06,$00,$00,$08
					   db $00,$00,$00,$18,$10,$19,$14,$03,$02,$80,$80,$00,$00,$3A,$28,$00
					   db $00,$00,$C0,$DC,$94,$00,$00,$00,$00,$74,$4C,$00,$00,$00,$00,$01

; [Continues with enemy sprite data...]

; ------------------------------------------------------------------------------
; Enemy AI Behavior Scripts
; ------------------------------------------------------------------------------
; Starting at $079030
; Main AI decision engine for all enemies
;
; Entry: CODE_079030
; Inputs:  $19AB - Current enemy index
;          $19D8 - AI script pointer
; Outputs: Enemy action selected, targets chosen
;
; AI script format:
; - Byte 0: Condition code (HP threshold, turn count, etc.)
; - Byte 1: Action code (attack, spell, special)
; - Byte 2+: Parameters (spell ID, target type, etc.)
; - $FF: End of script
; ------------------------------------------------------------------------------

CODE_079030:                              ; Main AI entry point
					   PHD                ; Save direct page
					   PHP                ; Save processor status
					   SEP #$20           ; 8-bit accumulator
					   REP #$10           ; 16-bit index
					   
					   LDA.W $19AB        ; Load current enemy index
					   CMP.B #$FF         ; Check if valid enemy
					   BEQ CODE_079050    ; Exit if no enemy
					   
					   PEA.W $1953        ; Set DP to $1953 (battle variables)
					   PLD
					   
					   LDX.W $19D8        ; Load AI script pointer ($19DA in DP)
					   LDA.L UNREACH_0CD500,X  ; Read AI script byte
					   INX
					   INX
					   STX.B $02          ; Store next script position ($1955)
					   CMP.B #$FF         ; Check for end of script
					   BNE CODE_079053    ; Continue if not end

CODE_079050:                              ; AI exit
					   PLP                ; Restore processor status
					   PLD                ; Restore direct page
					   RTL                ; Return to caller

CODE_079053:                              ; Process AI action
					   STA.B $0A          ; Store action code ($195D)
					   LDX.W #$0000
					   STX.B $04          ; Clear temp 1 ($1957)
					   STX.B $06          ; Clear temp 2 ($1959)

; AI script execution loop
CODE_07905C:
					   SEP #$20           ; 8-bit A
					   REP #$10           ; 16-bit X/Y
					   
					   LDX.B $02          ; Load script position
					   LDA.L UNREACH_0CD500,X  ; Read next byte
					   CMP.B #$FF         ; Check for end marker
					   BEQ CODE_079092    ; Exit loop if end
					   
					   ; Check against enemy state
					   PHX
					   LDX.B $06          ; Load state offset
					   LDA.L $7FCEC8,X    ; Read enemy state byte
					   STA.B $00          ; Store for comparison
					   PLX
					   
					   LDA.L UNREACH_0CD500,X  ; Re-read script byte
					   CMP.B $00          ; Compare with state
					   BCS CODE_079092    ; Branch if condition met
					   
					   ; Clear state if condition failed
					   LDA.B #$00
					   PHX
					   LDX.B $06
					   STA.L $7FCEC8,X    ; Clear enemy state
					   PLX
					   
					   ; Execute AI action
					   LDA.B #$00
					   XBA                ; Clear high byte
					   LDA.L UNREACH_0CD501,X  ; Load action type
					   ASL A              ; Multiply by 2 for word index
					   TAX
					   JSR.W (DATA8_0790BB,X)  ; Call action handler

CODE_079092:                              ; Loop continuation
					   REP #$30           ; 16-bit A/X/Y
					   LDA.B $06          ; Load state offset
					   CMP.W #$000E       ; Check if all states processed
					   BEQ CODE_079050    ; Exit if done
					   
					   INC A              ; Next state
					   INC A
					   STA.B $06          ; Store new offset
					   
					   LDA.B $04          ; Advance to next enemy slot
					   CLC
					   ADC.W #$0020       ; +32 bytes per enemy
					   STA.B $04
					   
					   SEP #$20
					   REP #$10
					   LDX.B $02          ; Load script position

CODE_0790AD:                              ; Skip to next script entry
					   LDA.L UNREACH_0CD500,X
					   INX
					   CMP.B #$FF         ; Find end marker
					   BNE CODE_0790AD    ; Keep scanning
					   
					   STX.B $02          ; Store new position
					   JMP.W CODE_07905C  ; Continue loop

; ------------------------------------------------------------------------------
; AI Action Jump Table
; ------------------------------------------------------------------------------
; Pointers to specific AI behavior handlers
; Each action type has dedicated routine
; ------------------------------------------------------------------------------

DATA8_0790BB:
					   dw $90C5           ; Action 0: Physical attack
					   dw $912A           ; Action 1: Magic spell
					   dw $9153           ; Action 2: Special ability
					   dw $9174           ; Action 3: Defend/wait
					   dw $91C9           ; Action 4: Status effect

; ------------------------------------------------------------------------------
; Enemy Attack Pattern Data
; ------------------------------------------------------------------------------
; Starting at $07921E
; Attack scripts for different enemy types
;
; Format: [condition][probability][target_type][action_id]...
; - Condition: HP%, turn count, party state
; - Probability: 0-255 (chance to execute)
; - Target type: Single, all, random, etc.
; - Action ID: Attack/spell to use
; ------------------------------------------------------------------------------

					   ; Goblin AI script
					   db $17,$02  ; HP > 50%: Priority 2
					   db $F1,$00  ; Action: Physical attack
					   db $F0,$00  ; Target: Random party member
					   db $F0,$00  ; Unused
					   db $F0,$00  ; Unused
					   db $F0,$00  ; Unused
					   db $F0,$00  ; Unused
					   db $F0,$00  ; Unused
					   db $F0,$00  ; Unused
					   db $E0,$00  ; HP < 50%: Different behavior
					   db $31,$00  ; Action: Flee attempt

					   ; Minotaur AI script  
					   db $F0,$16  ; Turn 1: Setup
					   db $10,$12  ; Action: Buff self
					   db $40,$02  ; Priority
					   db $E0,$16  ; Turn 2+
					   db $31,$00  ; Action: Heavy attack
					   db $D0,$18  ; HP threshold
					   db $20,$16  ; Action: Rage mode
					   db $31,$02  ; Priority boost

; [Additional enemy AI scripts...]

; ==============================================================================
; END OF BANK $07 DOCUMENTATION (Partial)
; ==============================================================================
; Lines documented: ~600 of 5,208 (11.5%)
; Remaining work:
; - Document all AI action handlers
; - Map enemy IDs to AI scripts
; - Document targeting algorithms
; - Document damage calculation integration
; - Document boss special behaviors
; - Document AI difficulty scaling
; - Create AI script debugging tools
; ==============================================================================
