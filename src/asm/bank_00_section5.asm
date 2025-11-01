														; ===========================================================================
														; Continued Bank $00 Disassembly - Section 5
														; Lines 2400-3200 (Menu/UI/Math routines)
														; ===========================================================================

														; ===========================================================================
														; Menu System - Command Processing
														; ===========================================================================
														; Purpose: Process menu commands and handle UI interactions
														; Technical Details:
														;   - Uses direct page $0500 for fast menu state access
														;   - Implements command queueing system
														;   - Handles sound effect triggers
														; ===========================================================================

CODE_009264:
					   SEP					 #$30		; 8-bit A,X,Y

														; Check if menu command processing enabled
					   LDA.B				   #$20	  ; Bit 5 = menu active
					   AND.W				   $00D9	 ; Check display flags
					   BNE					 CODE_009270 ; If set, skip processing

					   JSR.W				   CODE_009273 ; Process menu command

CODE_009270:
					   REP					 #$30		; 16-bit A,X,Y
					   RTS							   ; Return

														; ===========================================================================
														; Process Menu Command Queue
														; ===========================================================================
														; Purpose: Execute queued menu commands with sound effects
														; Technical Details:
														;   - Uses $0500-$050F direct page for command queue
														;   - Commands are executed via Bank $0D JSL calls
														;   - Manages CLI/SEI for timing-critical operations
														; ===========================================================================

CODE_009273:
					   REP					 #$10		; 16-bit X,Y

														; Set menu processing flag
					   LDA.B				   #$20	  ; Bit 5
					   TSB.W				   $00D9	 ; Set in display flags

														; Set direct page to command queue area
					   PEA.W				   $0500	 ; Push $0500
					   PLD							   ; Pull to D register

					   CLI							   ; Enable interrupts (for sound)

														; Check if cutscene mode active
					   LDA.B				   #$04	  ; Bit 2
					   AND.W				   $00E2	 ; Check cutscene flags
					   BNE					 CODE_0092A3 ; If set, skip command 0

														; Process Command 0 (primary menu action)
					   LDA.B				   $00	   ; Get command 0 (DP $0500)
					   BMI					 CODE_0092A3 ; If negative, skip (no command)

					   STA.W				   $0601	 ; Store to command execution register

					   LDX.B				   $01	   ; Get command parameter (DP $0501)
					   STX.W				   $0602	 ; Store parameter

					   LDA.B				   #$01	  ; Command type = 1
					   STA.W				   $0600	 ; Set command type

					   JSL.L				   CODE_0D8004 ; Execute command (Bank $0D)

														; Clear command and save parameter
					   LDA.B				   #$FF	  ; Invalid command marker
					   STA.B				   $00	   ; Clear command 0

					   LDX.B				   $03	   ; Get result parameter (DP $0503)
					   STX.B				   $01	   ; Store back to parameter slot

CODE_0092A3:
														; Process Command 1 (secondary menu action)
					   LDA.B				   $05	   ; Get command 1 (DP $0505)
					   BMI					 CODE_0092C2 ; If negative, skip

					   LDA.B				   $05	   ; Load command
					   STA.W				   $0601	 ; Store to execution register

					   LDX.B				   $06	   ; Get parameter (DP $0506)
					   STX.W				   $0602	 ; Store parameter

					   LDA.B				   #$02	  ; Command type = 2
					   STA.W				   $0600	 ; Set command type

					   JSL.L				   CODE_0D8004 ; Execute command

														; Clear command
					   LDA.B				   #$FF	  ; Invalid marker
					   STA.B				   $05	   ; Clear command 1

					   LDX.B				   $08	   ; Get result (DP $0508)
					   STX.B				   $06	   ; Store back

CODE_0092C2:
														; Process Command 2 (special actions)
					   LDA.B				   $0A	   ; Get command 2 (DP $050A)
					   BEQ					 CODE_0092E9 ; If zero, skip

														; Check command type
					   CMP.B				   #$02	  ; Compare to type 2
					   BEQ					 CODE_0092D9 ; If equal, execute directly

					   CMP.B				   #$10	  ; Compare to threshold
					   BCC					 CODE_0092D2 ; If below, check cutscene

					   CMP.B				   #$20	  ; Compare to upper threshold
					   BCC					 CODE_0092D9 ; If in range $10-$1F, execute

CODE_0092D2:
														; Check cutscene mode for non-special commands
					   LDA.B				   #$04	  ; Cutscene bit
					   AND.W				   $00E2	 ; Check flags
					   BNE					 CODE_0092E9 ; If cutscene, skip command

CODE_0092D9:
														; Execute command 2
					   LDX.B				   $0A	   ; Get command (DP $050A)
					   STX.W				   $0600	 ; Store command type

					   LDX.B				   $0C	   ; Get parameter (DP $050C)
					   STX.W				   $0602	 ; Store parameter

					   JSL.L				   CODE_0D8004 ; Execute command

					   STZ.B				   $0A	   ; Clear command 2

CODE_0092E9:
														; Cleanup and return
					   SEI							   ; Disable interrupts

					   LDA.B				   #$20	  ; Menu processing bit
					   TRB.W				   $00D9	 ; Clear from flags

					   RTS							   ; Return

														; ===========================================================================
														; Menu Transition Routines
														; ===========================================================================
														; Purpose: Handle menu opening/closing transitions
														; ===========================================================================

CODE_0092F0:
														; Open menu transition
					   JSR.W				   CODE_0092FC ; Common transition setup
					   JMP.W				   CODE_00803A ; Jump to menu open handler

CODE_0092F6:
														; Close menu transition
					   JSR.W				   CODE_0092FC ; Common transition setup
					   JMP.W				   CODE_008016 ; Jump to menu close handler

CODE_0092FC:
														; Common transition setup
					   SEP					 #$30		; 8-bit A,X,Y

														; Set transition flag
					   LDA.B				   #$40	  ; Bit 6 = transition active
					   TSB.W				   $00D6	 ; Set in flags

														; Configure NMI for menu
					   LDA.W				   $0112	 ; Get NMI configuration
					   STA.W				   SNES_NMITIMEN ; Write to NMI register ($4200)

					   CLI							   ; Enable interrupts

					   JSL.L				   CODE_00C7B8 ; Initialize menu graphics

														; Clear transition flags
					   LDA.B				   #$08	  ; Bit 3
					   TRB.W				   $00D2	 ; Clear from state flags

					   LDA.B				   #$04	  ; Bit 2
					   TRB.W				   $00DB	 ; Clear from menu flags

					   RTS							   ; Return

														; ===========================================================================
														; Input Handler - Directional Processing
														; ===========================================================================
														; Purpose: Process directional input with auto-repeat
														; Technical Details:
														;   - Implements input delay and repeat timing
														;   - Used for menu cursor movement
														; ===========================================================================

CODE_009319:
					   PHP							   ; Save processor status
					   PHB							   ; Save data bank
					   PHK							   ; Push program bank
					   PLB							   ; Set as data bank

					   REP					 #$30		; 16-bit A,X,Y
					   PHA							   ; Save accumulator

														; Set input delay
					   LDA.W				   #$0008	; Initial delay = 8 frames
					   STA.W				   $0051	 ; Store delay counter

					   SEP					 #$20		; 8-bit A

					   LDA.B				   #$0C	  ; Auto-repeat rate = 12
					   STA.W				   $0055	 ; Store repeat counter

														; Set input processing flags
					   LDA.B				   #$02	  ; Bit 1
					   TRB.W				   $00DB	 ; Clear from menu flags

					   LDA.B				   #$80	  ; Bit 7
					   TRB.W				   $00E2	 ; Clear from state flags

					   LDA.B				   #$04	  ; Bit 2
					   TSB.W				   $00DB	 ; Set in menu flags

					   REP					 #$30		; 16-bit A,X,Y
					   PLA							   ; Restore accumulator
					   PLB							   ; Restore data bank
					   PLP							   ; Restore processor status
					   RTL							   ; Return

														; ===========================================================================
														; Frame Counter Check
														; ===========================================================================
														; Purpose: Check if specific frames have elapsed (for animations)
														; Input: None (checks internal counters)
														; Returns: A = 0 if time elapsed, non-zero otherwise
														; ===========================================================================

CODE_009342:
					   LDA.W				   #$0004	; Bit 2
					   AND.W				   $00DB	 ; Check menu flags
					   BEQ					 CODE_009352 ; If clear, skip check

														; Check frame counter
					   LDA.W				   $0E97	 ; Get frame counter
					   AND.W				   #$000F	; Mask to 15 frames (0-15)
					   BEQ					 CODE_009353 ; If zero, continue processing

CODE_009352:
					   RTS							   ; Return (not ready yet)

CODE_009353:
														; Check battle mode
					   LDA.W				   #$0010	; Bit 4 = battle active
					   AND.W				   $00DA	 ; Check display flags
					   BNE					 UNREACH_0093CC ; If battle, use different logic

														; Check delay counter
					   LDA.B				   $51	   ; Get delay (DP $0051)
					   BEQ					 CODE_009362 ; If zero, process input

					   DEC.B				   $51	   ; Decrement delay
					   RTS							   ; Return (still delaying)

CODE_009362:
														; Check if input locked
					   LDA.W				   #$0080	; Bit 7 = input lock
					   AND.W				   $00E2	 ; Check state flags
					   BNE					 UNREACH_0093C9 ; If locked, skip

					   JSR.W				   CODE_0095FB ; Read controller state
					   BNE					 UNREACH_0093C9 ; If buttons pressed, skip text processing

														; Check text scroll state
					   LDA.W				   #$0002	; Bit 1 = text scrolling
					   AND.W				   $00DB	 ; Check menu flags
					   BNE					 UNREACH_009385 ; If scrolling, handle differently

														; Start text scroll
					   LDA.W				   #$0002	; Bit 1
					   TSB.W				   $00DB	 ; Set scrolling flag

														; Get text nibble (high 4 bits)
					   LDA.B				   [$53]	 ; Load from text pointer (DP $53)
					   LSR					 A		   ; Shift right 4 times
					   LSR					 A
					   LSR					 A
					   LSR					 A
					   BRA					 CODE_00938F ; Process nibble

UNREACH_009385:
														; Continue text scroll (get low nibble)
db											 $A9,$02,$00,$1C,$DB,$00,$A7,$53,$E6,$53 ; Clear scroll, get low nibble

CODE_00938F:
														; Process text control code
					   AND.W				   #$000F	; Mask to nibble

					   CMP.W				   #$0004	; Compare to threshold
					   BCS					 CODE_0093C3 ; If >= 4, process as text code

														; Check for special control codes (0-3)
db											 $C9,$01,$00,$90,$24,$F0,$0B,$C9,$02,$00,$F0,$07,$A9,$03,$00,$85
db											 $51,$60,$60,$A9,$02,$00,$2D,$D9,$00,$F0,$07,$A9,$02,$00,$1C,$D9
db											 $00,$60,$A9,$02,$00,$0C,$D9,$00,$60,$4C,$F6,$92

CODE_0093C3:
														; Load text character
					   JSR.W				   CODE_0097F2 ; Get character from text table
					   STA.B				   $90	   ; Store character (DP $0090)
					   RTS							   ; Return

UNREACH_0093C9:
db											 $4C,$4B,$95 ; JMP to input handler

														; ===========================================================================
														; 16-bit x 16-bit Multiplication
														; ===========================================================================
														; Purpose: Multiply two 16-bit numbers
														; Input:
														;   $98-$99 = Multiplicand
														;   $9C-$9D = Multiplier
														; Output:
														;   $9E-$9F = Product (low word)
														;   $A0-$A1 = Product (high word) [for 32-bit result]
														; ===========================================================================

CODE_0096B3:
					   PHP							   ; Save processor status
					   REP					 #$30		; 16-bit A,X,Y
					   PHD							   ; Save direct page
					   PHA							   ; Save accumulator
					   PHX							   ; Save X
					   PHY							   ; Save Y

														; Set direct page to zero page
					   LDA.W				   #$0000
					   TCD							   ; D = $0000

														; Copy multiplier to temp
					   LDA.B				   $9C	   ; Get multiplier (DP $009C)
					   STA.B				   $A4	   ; Store to temp (DP $00A4)

					   STZ.B				   $9E	   ; Clear result low

					   LDX.W				   #$0010	; 16 bits to process
					   LDY.B				   $98	   ; Get multiplicand (DP $0098)

CODE_0096C9:
														; Shift and add algorithm
					   ASL.B				   $9E	   ; Shift result left
					   ROL.B				   $A0	   ; Rotate high word

					   ASL.B				   $A4	   ; Shift multiplier left
					   BCC					 CODE_0096DB ; If bit was 0, skip add

														; Add multiplicand to result
					   TYA							   ; Multiplicand to A
CLC_Label:
					   ADC.B				   $9E	   ; Add to result low
					   STA.B				   $9E	   ; Store back

					   BCC					 CODE_0096DB ; If no carry, continue

					   INC.B				   $A0	   ; Increment high word

CODE_0096DB:
					   DEX							   ; Decrement bit counter
					   BNE					 CODE_0096C9 ; Continue for all 16 bits

					   PLY							   ; Restore Y
					   PLX							   ; Restore X
					   PLA							   ; Restore A
					   PLD							   ; Restore direct page
					   PLP							   ; Restore processor status
					   RTL							   ; Return

														; ===========================================================================
														; 32-bit ÷ 16-bit Division
														; ===========================================================================
														; Purpose: Divide 32-bit number by 16-bit number
														; Input:
														;   $98-$9B = Dividend (32-bit)
														;   $9C-$9D = Divisor (16-bit)
														; Output:
														;   $9E-$9F = Quotient (16-bit)
														;   $A2-$A3 = Remainder (16-bit)
														; ===========================================================================

CODE_0096E4:
					   PHP							   ; Save processor status
					   REP					 #$30		; 16-bit A,X,Y
					   PHD							   ; Save direct page
					   PHA							   ; Save accumulator
					   PHX							   ; Save X

														; Set direct page to zero page
					   LDA.W				   #$0000
					   TCD							   ; D = $0000

														; Copy dividend to working registers
					   LDA.B				   $98	   ; Get dividend low word (DP $0098)
					   STA.B				   $A4	   ; Store to temp (DP $00A4)

					   LDA.B				   $9A	   ; Get dividend high word (DP $009A)
					   STA.B				   $A6	   ; Store to temp (DP $00A6)

					   STZ.B				   $A2	   ; Clear remainder

					   LDX.W				   #$0020	; 32 bits to process

CODE_0096FB:
														; Shift and subtract algorithm
					   ASL.B				   $9E	   ; Shift quotient left
					   ROL.B				   $A0	   ; Rotate high word

					   ASL.B				   $A4	   ; Shift dividend left
					   ROL.B				   $A6	   ; Rotate high word
					   ROL.B				   $A2	   ; Rotate into remainder

					   LDA.B				   $A2	   ; Get remainder
					   BCS					 UNREACH_009710 ; If carry set, definitely >= divisor

														; Check if remainder >= divisor
SEC_Label:
					   SBC.B				   $9C	   ; Subtract divisor
					   BCS					 CODE_009712 ; If no borrow, division succeeded
					   BRA					 CODE_009716 ; Skip setting quotient bit

UNREACH_009710:
db											 $E5,$9C	 ; SBC.B $9C (subtract divisor)

CODE_009712:
					   STA.B				   $A2	   ; Store new remainder
					   INC.B				   $9E	   ; Set quotient bit

CODE_009716:
					   DEX							   ; Decrement bit counter
					   BNE					 CODE_0096FB ; Continue for all 32 bits

					   PLX							   ; Restore X
					   PLA							   ; Restore A
					   PLD							   ; Restore direct page
					   PLP							   ; Restore processor status
					   RTL							   ; Return

														; ===========================================================================
														; Hardware Multiply (8-bit x 8-bit)
														; ===========================================================================
														; Purpose: Use SNES hardware multiplier
														; Input: A = multiplier
														; Output: Hardware multiply result in $4216-$4217
														; ===========================================================================

CODE_00971E:
					   PHP							   ; Save processor status
					   SEP					 #$20		; 8-bit A

					   STA.W				   SNES_WRMPYB ; Write to hardware multiplier ($4203)

					   PLP							   ; Restore processor status
					   RTL							   ; Return (result available after 8 cycles)

														; ===========================================================================
														; Hardware Divide (16-bit ÷ 8-bit)
														; ===========================================================================
														; Purpose: Use SNES hardware divider
														; Input: A = divisor
														; Output: Hardware divide result in $4214-$4217
														; ===========================================================================

CODE_009726:
					   PHP							   ; Save processor status
					   SEP					 #$20		; 8-bit A

					   STA.W				   SNES_WRDIVB ; Write to hardware divider ($4206)

					   XBA							   ; Delay (swap and swap back)
					   XBA							   ; 16 cycles for division

					   PLP							   ; Restore processor status
					   RTL							   ; Return (result ready)

														; ===========================================================================
														; Count Leading Zeros (Find Highest Bit Set)
														; ===========================================================================
														; Purpose: Find position of highest bit set in 16-bit value
														; Input: A = value to check
														; Output: A = bit position (0-15), or $FFFF if value was 0
														; ===========================================================================

CODE_009730:
					   PHP							   ; Save processor status
					   REP					 #$30		; 16-bit A,X,Y
					   PHX							   ; Save X

					   LDX.W				   #$FFFF	; Start at -1

CODE_009737:
					   INX							   ; Increment bit count
					   LSR					 A		   ; Shift right
					   BCC					 CODE_009737 ; Continue until carry (bit found)

					   TXA							   ; Transfer bit position to A
					   PLX							   ; Restore X
					   PLP							   ; Restore processor status
					   RTL							   ; Return

														; ===========================================================================
														; RNG - Read Controller State
														; ===========================================================================
														; Purpose: Read joypad and update RNG state
														; Returns: A = combined controller state
														; ===========================================================================

CODE_0095FB:
					   LDA.W				   $102F	 ; Get player 1 state
					   ORA.W				   $10AF	 ; OR with player 2 state
					   AND.W				   #$0003	; Mask to directional bits

					   ORA.W				   $1021	 ; OR with button state 1
					   ORA.W				   $10A1	 ; OR with button state 2
					   AND.W				   #$00FF	; Mask to byte

					   RTS							   ; Return combined state

														;===============================================================================
														; Progress: Bank $00 Continued
														; Lines documented: ~2,700 / 14,017 (19.3%)
														; Total progress: ~3,570 / 74,682 (4.8%)
														; Focus: Menu system, math routines, input handling, RNG
														; Next: More Bank $00 + continue Banks $01/$02
														;===============================================================================
