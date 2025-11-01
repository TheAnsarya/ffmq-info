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
	sep					 #$30		; 8-bit A,X,Y

; Check if menu command processing enabled
	lda.B				   #$20	  ; Bit 5 = menu active
	and.W				   $00d9	 ; Check display flags
	bne					 CODE_009270 ; If set, skip processing

	jsr.W				   CODE_009273 ; Process menu command

CODE_009270:
	rep					 #$30		; 16-bit A,X,Y
	rts							   ; Return

; ===========================================================================
; Process Menu Command Queue
; ===========================================================================
; Purpose: Execute queued menu commands with sound effects
; Technical Details:
;   - Uses $0500-$050f direct page for command queue
;   - Commands are executed via Bank $0d JSL calls
;   - Manages CLI/SEI for timing-critical operations
; ===========================================================================

CODE_009273:
	rep					 #$10		; 16-bit X,Y

; Set menu processing flag
	lda.B				   #$20	  ; Bit 5
	tsb.W				   $00d9	 ; Set in display flags

; Set direct page to command queue area
	pea.W				   $0500	 ; Push $0500
	pld							   ; Pull to D register

	cli							   ; Enable interrupts (for sound)

; Check if cutscene mode active
	lda.B				   #$04	  ; Bit 2
	and.W				   $00e2	 ; Check cutscene flags
	bne					 CODE_0092A3 ; If set, skip command 0

; Process Command 0 (primary menu action)
	lda.B				   $00	   ; Get command 0 (DP $0500)
	bmi					 CODE_0092A3 ; If negative, skip (no command)

	sta.W				   $0601	 ; Store to command execution register

	ldx.B				   $01	   ; Get command parameter (DP $0501)
	stx.W				   $0602	 ; Store parameter

	lda.B				   #$01	  ; Command type = 1
	sta.W				   $0600	 ; Set command type

	jsl.L				   CODE_0D8004 ; Execute command (Bank $0d)

; Clear command and save parameter
	lda.B				   #$ff	  ; Invalid command marker
	sta.B				   $00	   ; Clear command 0

	ldx.B				   $03	   ; Get result parameter (DP $0503)
	stx.B				   $01	   ; Store back to parameter slot

CODE_0092A3:
; Process Command 1 (secondary menu action)
	lda.B				   $05	   ; Get command 1 (DP $0505)
	bmi					 CODE_0092C2 ; If negative, skip

	lda.B				   $05	   ; Load command
	sta.W				   $0601	 ; Store to execution register

	ldx.B				   $06	   ; Get parameter (DP $0506)
	stx.W				   $0602	 ; Store parameter

	lda.B				   #$02	  ; Command type = 2
	sta.W				   $0600	 ; Set command type

	jsl.L				   CODE_0D8004 ; Execute command

; Clear command
	lda.B				   #$ff	  ; Invalid marker
	sta.B				   $05	   ; Clear command 1

	ldx.B				   $08	   ; Get result (DP $0508)
	stx.B				   $06	   ; Store back

CODE_0092C2:
; Process Command 2 (special actions)
	lda.B				   $0a	   ; Get command 2 (DP $050a)
	beq					 CODE_0092E9 ; If zero, skip

; Check command type
	cmp.B				   #$02	  ; Compare to type 2
	beq					 CODE_0092D9 ; If equal, execute directly

	cmp.B				   #$10	  ; Compare to threshold
	bcc					 CODE_0092D2 ; If below, check cutscene

	cmp.B				   #$20	  ; Compare to upper threshold
	bcc					 CODE_0092D9 ; If in range $10-$1f, execute

CODE_0092D2:
; Check cutscene mode for non-special commands
	lda.B				   #$04	  ; Cutscene bit
	and.W				   $00e2	 ; Check flags
	bne					 CODE_0092E9 ; If cutscene, skip command

CODE_0092D9:
; Execute command 2
	ldx.B				   $0a	   ; Get command (DP $050a)
	stx.W				   $0600	 ; Store command type

	ldx.B				   $0c	   ; Get parameter (DP $050c)
	stx.W				   $0602	 ; Store parameter

	jsl.L				   CODE_0D8004 ; Execute command

	stz.B				   $0a	   ; Clear command 2

CODE_0092E9:
; Cleanup and return
	sei							   ; Disable interrupts

	lda.B				   #$20	  ; Menu processing bit
	trb.W				   $00d9	 ; Clear from flags

	rts							   ; Return

; ===========================================================================
; Menu Transition Routines
; ===========================================================================
; Purpose: Handle menu opening/closing transitions
; ===========================================================================

CODE_0092F0:
; Open menu transition
	jsr.W				   CODE_0092FC ; Common transition setup
	jmp.W				   CODE_00803A ; Jump to menu open handler

CODE_0092F6:
; Close menu transition
	jsr.W				   CODE_0092FC ; Common transition setup
	jmp.W				   CODE_008016 ; Jump to menu close handler

CODE_0092FC:
; Common transition setup
	sep					 #$30		; 8-bit A,X,Y

; Set transition flag
	lda.B				   #$40	  ; Bit 6 = transition active
	tsb.W				   $00d6	 ; Set in flags

; Configure NMI for menu
	lda.W				   $0112	 ; Get NMI configuration
	sta.W				   SNES_NMITIMEN ; Write to NMI register ($4200)

	cli							   ; Enable interrupts

	jsl.L				   CODE_00C7B8 ; Initialize menu graphics

; Clear transition flags
	lda.B				   #$08	  ; Bit 3
	trb.W				   $00d2	 ; Clear from state flags

	lda.B				   #$04	  ; Bit 2
	trb.W				   $00db	 ; Clear from menu flags

	rts							   ; Return

; ===========================================================================
; Input Handler - Directional Processing
; ===========================================================================
; Purpose: Process directional input with auto-repeat
; Technical Details:
;   - Implements input delay and repeat timing
;   - Used for menu cursor movement
; ===========================================================================

CODE_009319:
	php							   ; Save processor status
	phb							   ; Save data bank
	phk							   ; Push program bank
	plb							   ; Set as data bank

	rep					 #$30		; 16-bit A,X,Y
	pha							   ; Save accumulator

; Set input delay
	lda.W				   #$0008	; Initial delay = 8 frames
	sta.W				   $0051	 ; Store delay counter

	sep					 #$20		; 8-bit A

	lda.B				   #$0c	  ; Auto-repeat rate = 12
	sta.W				   $0055	 ; Store repeat counter

; Set input processing flags
	lda.B				   #$02	  ; Bit 1
	trb.W				   $00db	 ; Clear from menu flags

	lda.B				   #$80	  ; Bit 7
	trb.W				   $00e2	 ; Clear from state flags

	lda.B				   #$04	  ; Bit 2
	tsb.W				   $00db	 ; Set in menu flags

	rep					 #$30		; 16-bit A,X,Y
	pla							   ; Restore accumulator
	plb							   ; Restore data bank
	plp							   ; Restore processor status
	rtl							   ; Return

; ===========================================================================
; Frame Counter Check
; ===========================================================================
; Purpose: Check if specific frames have elapsed (for animations)
; Input: None (checks internal counters)
; Returns: A = 0 if time elapsed, non-zero otherwise
; ===========================================================================

CODE_009342:
	lda.W				   #$0004	; Bit 2
	and.W				   $00db	 ; Check menu flags
	beq					 CODE_009352 ; If clear, skip check

; Check frame counter
	lda.W				   $0e97	 ; Get frame counter
	and.W				   #$000f	; Mask to 15 frames (0-15)
	beq					 CODE_009353 ; If zero, continue processing

CODE_009352:
	rts							   ; Return (not ready yet)

CODE_009353:
; Check battle mode
	lda.W				   #$0010	; Bit 4 = battle active
	and.W				   $00da	 ; Check display flags
	bne					 UNREACH_0093CC ; If battle, use different logic

; Check delay counter
	lda.B				   $51	   ; Get delay (DP $0051)
	beq					 CODE_009362 ; If zero, process input

	dec.B				   $51	   ; Decrement delay
	rts							   ; Return (still delaying)

CODE_009362:
; Check if input locked
	lda.W				   #$0080	; Bit 7 = input lock
	and.W				   $00e2	 ; Check state flags
	bne					 UNREACH_0093C9 ; If locked, skip

	jsr.W				   CODE_0095FB ; Read controller state
	bne					 UNREACH_0093C9 ; If buttons pressed, skip text processing

; Check text scroll state
	lda.W				   #$0002	; Bit 1 = text scrolling
	and.W				   $00db	 ; Check menu flags
	bne					 UNREACH_009385 ; If scrolling, handle differently

; Start text scroll
	lda.W				   #$0002	; Bit 1
	tsb.W				   $00db	 ; Set scrolling flag

; Get text nibble (high 4 bits)
	lda.B				   [$53]	 ; Load from text pointer (DP $53)
	lsr					 a; Shift right 4 times
	lsr					 a
	lsr					 a
	lsr					 a
	bra					 CODE_00938F ; Process nibble

UNREACH_009385:
; Continue text scroll (get low nibble)
	db											 $a9,$02,$00,$1c,$db,$00,$a7,$53,$e6,$53 ; Clear scroll, get low nibble

CODE_00938F:
; Process text control code
	and.W				   #$000f	; Mask to nibble

	cmp.W				   #$0004	; Compare to threshold
	bcs					 CODE_0093C3 ; If >= 4, process as text code

; Check for special control codes (0-3)
	db											 $c9,$01,$00,$90,$24,$f0,$0b,$c9,$02,$00,$f0,$07,$a9,$03,$00,$85
	db											 $51,$60,$60,$a9,$02,$00,$2d,$d9,$00,$f0,$07,$a9,$02,$00,$1c,$d9
	db											 $00,$60,$a9,$02,$00,$0c,$d9,$00,$60,$4c,$f6,$92

CODE_0093C3:
; Load text character
	jsr.W				   CODE_0097F2 ; Get character from text table
	sta.B				   $90	   ; Store character (DP $0090)
	rts							   ; Return

UNREACH_0093C9:
	db											 $4c,$4b,$95 ; JMP to input handler

; ===========================================================================
; 16-bit x 16-bit Multiplication
; ===========================================================================
; Purpose: Multiply two 16-bit numbers
; Input:
;   $98-$99 = Multiplicand
;   $9c-$9d = Multiplier
; Output:
;   $9e-$9f = Product (low word)
;   $a0-$a1 = Product (high word) [for 32-bit result]
; ===========================================================================

CODE_0096B3:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A,X,Y
	phd							   ; Save direct page
	pha							   ; Save accumulator
	phx							   ; Save X
	phy							   ; Save Y

; Set direct page to zero page
	lda.W				   #$0000
	tcd							   ; D = $0000

; Copy multiplier to temp
	lda.B				   $9c	   ; Get multiplier (DP $009c)
	sta.B				   $a4	   ; Store to temp (DP $00a4)

	stz.B				   $9e	   ; Clear result low

	ldx.W				   #$0010	; 16 bits to process
	ldy.B				   $98	   ; Get multiplicand (DP $0098)

CODE_0096C9:
; Shift and add algorithm
	asl.B				   $9e	   ; Shift result left
	rol.B				   $a0	   ; Rotate high word

	asl.B				   $a4	   ; Shift multiplier left
	bcc					 CODE_0096DB ; If bit was 0, skip add

; Add multiplicand to result
	tya							   ; Multiplicand to A
CLC_Label:
	adc.B				   $9e	   ; Add to result low
	sta.B				   $9e	   ; Store back

	bcc					 CODE_0096DB ; If no carry, continue

	inc.B				   $a0	   ; Increment high word

CODE_0096DB:
	dex							   ; Decrement bit counter
	bne					 CODE_0096C9 ; Continue for all 16 bits

	ply							   ; Restore Y
	plx							   ; Restore X
	pla							   ; Restore A
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return

; ===========================================================================
; 32-bit ÷ 16-bit Division
; ===========================================================================
; Purpose: Divide 32-bit number by 16-bit number
; Input:
;   $98-$9b = Dividend (32-bit)
;   $9c-$9d = Divisor (16-bit)
; Output:
;   $9e-$9f = Quotient (16-bit)
;   $a2-$a3 = Remainder (16-bit)
; ===========================================================================

CODE_0096E4:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A,X,Y
	phd							   ; Save direct page
	pha							   ; Save accumulator
	phx							   ; Save X

; Set direct page to zero page
	lda.W				   #$0000
	tcd							   ; D = $0000

; Copy dividend to working registers
	lda.B				   $98	   ; Get dividend low word (DP $0098)
	sta.B				   $a4	   ; Store to temp (DP $00a4)

	lda.B				   $9a	   ; Get dividend high word (DP $009a)
	sta.B				   $a6	   ; Store to temp (DP $00a6)

	stz.B				   $a2	   ; Clear remainder

	ldx.W				   #$0020	; 32 bits to process

CODE_0096FB:
; Shift and subtract algorithm
	asl.B				   $9e	   ; Shift quotient left
	rol.B				   $a0	   ; Rotate high word

	asl.B				   $a4	   ; Shift dividend left
	rol.B				   $a6	   ; Rotate high word
	rol.B				   $a2	   ; Rotate into remainder

	lda.B				   $a2	   ; Get remainder
	bcs					 UNREACH_009710 ; If carry set, definitely >= divisor

; Check if remainder >= divisor
SEC_Label:
	sbc.B				   $9c	   ; Subtract divisor
	bcs					 CODE_009712 ; If no borrow, division succeeded
	bra					 CODE_009716 ; Skip setting quotient bit

UNREACH_009710:
	db											 $e5,$9c	 ; SBC.B $9c (subtract divisor)

CODE_009712:
	sta.B				   $a2	   ; Store new remainder
	inc.B				   $9e	   ; Set quotient bit

CODE_009716:
	dex							   ; Decrement bit counter
	bne					 CODE_0096FB ; Continue for all 32 bits

	plx							   ; Restore X
	pla							   ; Restore A
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return

; ===========================================================================
; Hardware Multiply (8-bit x 8-bit)
; ===========================================================================
; Purpose: Use SNES hardware multiplier
; Input: A = multiplier
; Output: Hardware multiply result in $4216-$4217
; ===========================================================================

CODE_00971E:
	php							   ; Save processor status
	sep					 #$20		; 8-bit A

	sta.W				   SNES_WRMPYB ; Write to hardware multiplier ($4203)

	plp							   ; Restore processor status
	rtl							   ; Return (result available after 8 cycles)

; ===========================================================================
; Hardware Divide (16-bit ÷ 8-bit)
; ===========================================================================
; Purpose: Use SNES hardware divider
; Input: A = divisor
; Output: Hardware divide result in $4214-$4217
; ===========================================================================

CODE_009726:
	php							   ; Save processor status
	sep					 #$20		; 8-bit A

	sta.W				   SNES_WRDIVB ; Write to hardware divider ($4206)

	xba							   ; Delay (swap and swap back)
	xba							   ; 16 cycles for division

	plp							   ; Restore processor status
	rtl							   ; Return (result ready)

; ===========================================================================
; Count Leading Zeros (Find Highest Bit Set)
; ===========================================================================
; Purpose: Find position of highest bit set in 16-bit value
; Input: A = value to check
; Output: A = bit position (0-15), or $ffff if value was 0
; ===========================================================================

CODE_009730:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A,X,Y
	phx							   ; Save X

	ldx.W				   #$ffff	; Start at -1

CODE_009737:
	inx							   ; Increment bit count
	lsr					 a; Shift right
	bcc					 CODE_009737 ; Continue until carry (bit found)

	txa							   ; Transfer bit position to A
	plx							   ; Restore X
	plp							   ; Restore processor status
	rtl							   ; Return

; ===========================================================================
; RNG - Read Controller State
; ===========================================================================
; Purpose: Read joypad and update RNG state
; Returns: A = combined controller state
; ===========================================================================

CODE_0095FB:
	lda.W				   $102f	 ; Get player 1 state
	ora.W				   $10af	 ; OR with player 2 state
	and.W				   #$0003	; Mask to directional bits

	ora.W				   $1021	 ; OR with button state 1
	ora.W				   $10a1	 ; OR with button state 2
	and.W				   #$00ff	; Mask to byte

	rts							   ; Return combined state

;===============================================================================
; Progress: Bank $00 Continued
; Lines documented: ~2,700 / 14,017 (19.3%)
; Total progress: ~3,570 / 74,682 (4.8%)
; Focus: Menu system, math routines, input handling, RNG
; Next: More Bank $00 + continue Banks $01/$02
;===============================================================================
