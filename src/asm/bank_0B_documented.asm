; ==============================================================================
; Bank $0B - Battle Graphics and Animation Routines
; ==============================================================================
; This bank contains executable code for battle graphics management,
; sprite animation, and visual effects during combat.
;
; Memory Range: $0B8000-$0BFFFF (32 KB)
;
; Major Sections:
; - Graphics loading routines
; - Sprite animation controllers
; - Battle effect rendering
; - OAM (Object Attribute Memory) management
; - DMA transfer routines for graphics
;
; Key Routines:
; - CODE_0B8000: Graphics setup based on battle type
; - CODE_0B803F: Sprite animation handler
; - CODE_0B8077: OAM data update routine
;
; Related Files:
; - Bank $09/$0A: Graphics data used by these routines
; - Bank $0C: Display/screen management code
; ==============================================================================

	ORG $0B8000

; ==============================================================================
; Graphics Setup Routine
; ==============================================================================
; Sets up graphics pointers based on battle encounter type.
; Input: $0E8B = Battle type index
; ==============================================================================

CODE_0B8000:
	LDA.W $0E8B								;0B8000	; Load battle type
	BEQ CODE_0B8017							;0B8003	; Branch if type 0
	DEC A									;0B8005	; Decrement type
	BEQ CODE_0B8023							;0B8006	; Branch if type 1
	DEC A									;0B8008	; Decrement type
	BEQ CODE_0B802F							;0B8009	; Branch if type 2

	; Type 3: Setup pointers
	LDA.B #$4A								;0B800B	; Graphics pointer low
	STA.W $0507								;0B800D	; Store to pointer
	LDA.B #$1B								;0B8010	; Graphics pointer high
	STA.W $0506								;0B8012	; Store to pointer
	BRA CODE_0B8039							;0B8015	; Jump to common setup

CODE_0B8017:
	; Type 0: Default graphics
	LDA.B #$A1								;0B8017	; Graphics pointer low
	STA.W $0507								;0B8019	; Store to pointer
	LDA.B #$1F								;0B801C	; Graphics pointer high
	STA.W $0506								;0B801E	; Store to pointer
	BRA CODE_0B8039							;0B8021	; Jump to common setup

CODE_0B8023:
	; Type 1: Alternate graphics
	LDA.B #$B6								;0B8023	; Graphics pointer low
	STA.W $0507								;0B8025	; Store to pointer
	LDA.B #$1B								;0B8028	; Graphics pointer high
	STA.W $0506								;0B802A	; Store to pointer
	BRA CODE_0B8039							;0B802D	; Jump to common setup

CODE_0B802F:
	; Type 2: Special graphics
	LDA.B #$5F								;0B802F	; Graphics pointer low
	STA.W $0507								;0B8031	; Store to pointer
	LDA.B #$1F								;0B8034	; Graphics pointer high
	STA.W $0506								;0B8036	; Store to pointer

CODE_0B8039:
	; Common graphics setup
	LDA.B #$0A								;0B8039	; Bank $0A (graphics bank)
	STA.W $0505								;0B803B	; Store bank number
	RTL										;0B803E	; Return

; ==============================================================================
; Sprite Animation Handler
; ==============================================================================
; Main routine for updating sprite animations during battle.
; Manages OAM data, animation frames, and DMA transfers.
; ==============================================================================

CODE_0B803F:
	PHP										;0B803F	; Save processor status
	PHB										;0B8040	; Save data bank
	PHX										;0B8041	; Save X register
	PHY										;0B8042	; Save Y register
	SEP #$20								;0B8043	; 8-bit accumulator
	REP #$10								;0B8045	; 16-bit index
	PHK										;0B8047	; Push program bank
	PLB										;0B8048	; Pull to data bank
	JSR.W CODE_0B80D9						;0B8049	; Call animation update
	LDX.W $192B								;0B804C	; Load sprite index
	CPX.W #$FFFF							;0B804F	; Check for invalid
	BEQ CODE_0B80A1							;0B8052	; Branch if invalid
	LDA.W $1A80,X							;0B8054	; Load sprite flags
	AND.B #$CF								;0B8057	; Mask off animation bits
	ORA.B #$10								;0B8059	; Set animation active flag
	STA.W $1A80,X							;0B805B	; Store updated flags
	LDA.W $1A82,X							;0B805E	; Load animation ID
	REP #$30								;0B8061	; 16-bit mode
	AND.W #$00FF							;0B8063	; Mask to byte
	ASL A									;0B8066	; Multiply by 2
	PHX										;0B8067	; Save sprite index
	TAX										;0B8068	; Transfer to X
	LDA.L DATA8_00FDCA,X					;0B8069	; Load animation data pointer
	CLC										;0B806D	; Clear carry
	ADC.W #$0008							;0B806E	; Add offset
	TAY										;0B8071	; Transfer to Y
	PLX										;0B8072	; Restore sprite index
	JSL.L CODE_01AE86						;0B8073	; Call animation loader

; ==============================================================================
; OAM Data Update Routine
; ==============================================================================
; Updates Object Attribute Memory with current sprite positions and tiles.
; ==============================================================================

CODE_0B8077:
	REP #$30								;0B8077	; 16-bit mode
	LDA.W $192D								;0B8079	; Load OAM table index
	AND.W #$00FF							;0B807C	; Mask to byte
	ASL A									;0B807F	; Multiply by 4
	ASL A									;0B8080	; (4 bytes per OAM entry)
	PHX										;0B8081	; Save X
	TAX										;0B8082	; Transfer to X
	LDA.L DATA8_01A63A,X					;0B8083	; Load OAM base address
	TAY										;0B8087	; Transfer to Y
	PLX										;0B8088	; Restore X
	LDA.W $1A73,X							;0B8089	; Load sprite X position
	STA.W $0C02,Y							;0B808C	; Store to OAM
	LDA.W $1A75,X							;0B808F	; Load sprite Y position
	STA.W $0C06,Y							;0B8092	; Store to OAM
	LDA.W $1A77,X							;0B8095	; Load sprite tile index
	STA.W $0C0A,Y							;0B8098	; Store to OAM
	LDA.W $1A79,X							;0B809B	; Load sprite attributes
	STA.W $0C0E,Y							;0B809E	; Store to OAM

CODE_0B80A1:
	PLY										;0B80A1	; Restore Y
	PLX										;0B80A2	; Restore X
	PLB										;0B80A3	; Restore data bank
	PLP										;0B80A4	; Restore processor status
	RTL										;0B80A5	; Return

; ==============================================================================
; [Additional Battle Graphics Routines]
; ==============================================================================
; The remaining code (CODE_0B80D9 onwards) includes:
; - Animation frame updates
; - Effect rendering routines
; - DMA transfer management
; - Palette rotation for effects
; - Sprite priority management
;
; Complete code available in original bank_0B.asm
; Total bank size: ~3,700 lines of battle graphics code
; ==============================================================================

; [Remaining battle graphics code continues to $0BFFFF]
; See original bank_0B.asm for complete implementation

; ==============================================================================
; End of Bank $0B
; ==============================================================================
; Total size: 32 KB (complete bank)
; Primary content: Battle graphics/animation code
; Related banks: $09/$0A (graphics data), $0C (display management)
;
; Key functions documented:
; - Graphics setup by battle type
; - Sprite animation handling
; - OAM data management
;
; Remaining work:
; - Complete disassembly of animation routines
; - Document effect rendering algorithms
; - Map all sprite animation sequences
; ==============================================================================
; =============================================================================
; Bank $0B - Cycle 1 Documentation (Lines 1-400)
; =============================================================================
; Coverage: Battle Graphics and Animation Routines
; Type: Executable 65816 assembly code
; Focus: Graphics loading, sprite animation, OAM management
; =============================================================================

; -----------------------------------------------------------------------------
; CODE_0B8000: Battle Graphics Setup Dispatcher
; -----------------------------------------------------------------------------
; Purpose: Initialize graphics pointers based on battle encounter type
; Input: $0E8B = Battle type index (0-3)
; Output: $0505/$0506/$0507 = Graphics pointer (bank/address)
; 
; Battle Types:
;   Type 0 → Pointers: Bank $0A, Addr $1FA1
;   Type 1 → Pointers: Bank $0A, Addr $1BB6  
;   Type 2 → Pointers: Bank $0A, Addr $1F5F
;   Type 3 → Pointers: Bank $0A, Addr $1B4A
;
; All types share common setup at CODE_0B8039:
;   - Sets bank to $0A (Bank $0A contains graphics data)
;   - Returns to caller via RTL
;
; Cross-References:
;   - Bank $0A graphics data (tile patterns, palettes)
;   - Called during battle initialization
;   - Pointer format: 24-bit address (bank:address)

CODE_0B8000:
	LDA.W $0E8B					; Load battle type index
	BEQ CODE_0B8017				; Type 0: Branch to first handler
	DEC A						; Decrement for type comparison
	BEQ CODE_0B8023				; Type 1: Branch to second handler
	DEC A						; Decrement again
	BEQ CODE_0B802F				; Type 2: Branch to third handler
	
	; Type 3 handler
	LDA.B #$4A					; Graphics address low byte
	STA.W $0507					; Store to pointer low
	LDA.B #$1B					; Graphics address high byte  
	STA.W $0506					; Store to pointer high
	BRA CODE_0B8039				; Jump to common bank setup

CODE_0B8017:  ; Type 0 handler
	LDA.B #$A1					; Graphics address low byte
	STA.W $0507					; Store to pointer low
	LDA.B #$1F					; Graphics address high byte
	STA.W $0506					; Store to pointer high
	BRA CODE_0B8039				; Jump to common bank setup

CODE_0B8023:  ; Type 1 handler
	LDA.B #$B6					; Graphics address low byte
	STA.W $0507					; Store to pointer low
	LDA.B #$1B					; Graphics address high byte
	STA.W $0506					; Store to pointer high
	BRA CODE_0B8039				; Jump to common bank setup

CODE_0B802F:  ; Type 2 handler
	LDA.B #$5F					; Graphics address low byte
	STA.W $0507					; Store to pointer low
	LDA.B #$1F					; Graphics address high byte
	STA.W $0506					; Store to pointer high
	; Fall through to CODE_0B8039

CODE_0B8039:  ; Common bank setup
	LDA.B #$0A					; Bank $0A (graphics data bank)
	STA.W $0505					; Store to pointer bank byte
	RTL							; Return to caller (long return)

; -----------------------------------------------------------------------------
; Sprite Animation Handler (Entry at $0B803F)
; -----------------------------------------------------------------------------
; Purpose: Update sprite animation state and OAM data
; Context: Called during battle V-blank for animation updates
; Stack: Preserves all registers (PHP/PHB/PHX/PHY on entry)
; 
; Process Flow:
;   1. Save processor state (flags, data bank, X, Y)
;   2. Set CPU modes (SEP #$20 = 8-bit A, REP #$10 = 16-bit X/Y)
;   3. Set data bank to current bank (PHK/PLB)
;   4. Call subroutine CODE_0B80D9 (animation state setup)
;   5. Check sprite index at $192B
;   6. If valid sprite:
;      - Update sprite attributes in $1A80 range
;      - Load animation frame data from tables
;      - Call CODE_01AE86 (sprite rendering routine in Bank $01)
;      - Update OAM data at $0C02+ (Object Attribute Memory mirror)
;   7. Restore processor state and return
;
; OAM Data Structure:
;   - $0C02+: Sprite X position
;   - $0C06+: Sprite Y position  
;   - $0C0A+: Sprite tile index
;   - $0C0E+: Sprite attributes (palette, flip, priority)
;
; Animation Frame Lookup:
;   - $1A82,X contains animation frame index
;   - Multiplied ×2 for table lookup (ASL A)
;   - Table at DATA8_00FDCA in Bank $00 provides frame data pointers
;   - +$0008 offset applied for sprite data alignment

	PHP							; Push processor status
	PHB							; Push data bank
	PHX							; Push X register
	PHY							; Push Y register
	SEP #$20					; Set A to 8-bit mode
	REP #$10					; Set X/Y to 16-bit mode
	PHK							; Push program bank (Bank $0B)
	PLB							; Pull to data bank (set DB = $0B)
	JSR.W CODE_0B80D9			; Call animation state setup
	LDX.W $192B					; Load sprite index
	CPX.W #$FFFF				; Check if valid sprite ($FFFF = none)
	BEQ CODE_0B80A1				; Exit if no sprite to update
	
	; Update sprite attributes
	LDA.W $1A80,X				; Load sprite attribute byte
	AND.B #$CF					; Clear bits 4-5 (palette bits)
	ORA.B #$10					; Set bit 4 (palette 1?)
	STA.W $1A80,X				; Store updated attributes
	
	; Load animation frame data
	LDA.W $1A82,X				; Load animation frame index
	REP #$30					; Set A/X/Y to 16-bit mode
	AND.W #$00FF				; Mask to 8-bit value
	ASL A						; Multiply by 2 (word table)
	PHX							; Save sprite index
	TAX							; Transfer to X for lookup
	LDA.L DATA8_00FDCA,X		; Load frame data pointer from Bank $00
	CLC							; Clear carry for addition
	ADC.W #$0008				; Add offset for sprite data
	TAY							; Transfer to Y (parameter for next call)
	PLX							; Restore sprite index
	JSL.L CODE_01AE86			; Call sprite rendering (Bank $01)

CODE_0B8077:  ; OAM Data Update Routine
	REP #$30					; Set A/X/Y to 16-bit mode
	LDA.W $192D					; Load OAM slot index
	AND.W #$00FF				; Mask to 8-bit value
	ASL A						; Multiply by 4 (ASL twice for ×4)
	ASL A						; Each OAM entry is 4 words
	PHX							; Save sprite index
	TAX							; Transfer to X for lookup
	LDA.L DATA8_01A63A,X		; Load OAM base address from Bank $01
	TAY							; Transfer to Y (destination pointer)
	PLX							; Restore sprite index
	
	; Copy sprite data to OAM mirror
	LDA.W $1A73,X				; Load sprite X position
	STA.W $0C02,Y				; Store to OAM X position
	LDA.W $1A75,X				; Load sprite Y position
	STA.W $0C06,Y				; Store to OAM Y position
	LDA.W $1A77,X				; Load sprite tile index
	STA.W $0C0A,Y				; Store to OAM tile index
	LDA.W $1A79,X				; Load sprite attributes
	STA.W $0C0E,Y				; Store to OAM attributes

CODE_0B80A1:  ; Exit routine
	PLY							; Restore Y register
	PLX							; Restore X register
	PLB							; Restore data bank
	PLP							; Restore processor status
	RTL							; Return to caller (long return)

; -----------------------------------------------------------------------------
; Sprite Deactivation Routine (Entry at $0B80A6)
; -----------------------------------------------------------------------------
; Purpose: Similar to animation handler but clears sprite priority bit
; Difference: Uses AND #$CF without ORA #$10 to clear palette bits
; Effect: Deactivates or deprioritizes sprite without removing it
;
; This routine mirrors the animation handler but:
;   - Clears priority/palette bits instead of setting them
;   - Used for sprite fade-out or background layering
;   - Shares same OAM update code at CODE_0B8077

	PHP							; Push processor status
	PHB							; Push data bank
	PHX							; Push X register
	PHY							; Push Y register
	SEP #$20					; Set A to 8-bit mode
	REP #$10					; Set X/Y to 16-bit mode
	JSR.W CODE_0B80D9			; Call animation state setup
	LDX.W $192B					; Load sprite index
	CPX.W #$FFFF				; Check if valid sprite
	BEQ CODE_0B80A1				; Exit if no sprite
	
	; Clear sprite attributes (no priority bit set)
	LDA.W $1A80,X				; Load sprite attribute byte
	AND.B #$CF					; Clear bits 4-5 (remove palette/priority)
	STA.W $1A80,X				; Store cleared attributes
	
	; Load animation frame (no offset added this time)
	LDA.W $1A82,X				; Load animation frame index
	REP #$30					; Set A/X/Y to 16-bit mode
	AND.W #$00FF				; Mask to 8-bit value
	ASL A						; Multiply by 2 (word table)
	PHX							; Save sprite index
	TAX							; Transfer to X for lookup
	CLC							; Clear carry
	LDA.L DATA8_00FDCA,X		; Load frame data pointer
	TAY							; Transfer to Y (no +$0008 offset)
	PLX							; Restore sprite index
	JSL.L CODE_01AE86			; Call sprite rendering
	BRA CODE_0B8077				; Jump to OAM update (shared code)

; -----------------------------------------------------------------------------
; CODE_0B80D9: Animation State Setup Subroutine
; -----------------------------------------------------------------------------
; Purpose: Initialize animation state variables
; Sets up: $192C (animation counter), $192B (sprite index = 2)
; Calls: CODE_018BD1 (animation frame calculator in Bank $01)

CODE_0B80D9:
	LDA.W $009E					; Load frame counter
	STA.W $192C					; Store to animation counter
	LDA.B #$02					; Sprite index = 2
	STA.W $192B					; Store sprite index
	JSL.L CODE_018BD1			; Call animation frame calculator (Bank $01)
	RTS							; Return to caller (short return)

; -----------------------------------------------------------------------------
; Sprite Data Search Routine (Entry at $0B80E9)
; -----------------------------------------------------------------------------
; Purpose: Search sprite table for specific sprite by ID
; Input: $1502 = Target sprite ID to find
; Output: $1500 = Found sprite data offset
; Method: Linear search through 22 sprite slots ($0016 = 22 decimal)
;
; Sprite Table Structure:
;   - Base: $1A72 (via PEA/PLD direct page setup)
;   - Entry size: $1A bytes (26 bytes per sprite)
;   - Total slots: 22 sprites maximum
;   - Offset $00: Sprite active flag ($FF = inactive)
;   - Offset $19: Sprite ID for matching
;   - Offset $0B: Sprite data offset (returned if match found)
;
; Search Algorithm:
;   FOR each_slot IN 22_slots:
;     IF slot_active_flag == $FF: CONTINUE
;     IF slot_sprite_id == target_id: RETURN slot_data_offset
;   NEXT
;   (No match = fall through without setting $1500)

	PHX							; Save X register
	PHY							; Save Y register
	PHA							; Save accumulator
	PHP							; Save processor status
	PHD							; Save direct page register
	PEA.W $1A72					; Push sprite table base address
	PLD							; Pull to direct page (DP = $1A72)
	SEP #$20					; Set A to 8-bit mode
	REP #$10					; Set X/Y to 16-bit mode
	LDX.W #$0000				; X = sprite slot index (start at 0)
	LDY.W #$0016				; Y = slot counter (22 slots = $16 hex)

CODE_0B80FC:  ; Search loop
	LDA.B $00,X					; Load sprite active flag (DP+$00+X)
	CMP.B #$FF					; Check if slot inactive
	BEQ CODE_0B8114				; Skip this slot if inactive
	LDA.B $19,X					; Load sprite ID (DP+$19+X)
	CMP.W $1502					; Compare with target sprite ID
	BNE CODE_0B8114				; Skip if no match
	
	; Match found!
	LDY.B $0B,X					; Load sprite data offset (DP+$0B+X)
	STY.W $1500					; Store to output variable
	PLD							; Restore direct page
	PLP							; Restore processor status
	PLA							; Restore accumulator
	PLY							; Restore Y register
	PLX							; Restore X register
	RTL							; Return with match found

CODE_0B8114:  ; Continue search
	PHP							; Save processor status
	REP #$30					; Set A/X/Y to 16-bit mode
	TXA							; Transfer X to A
	CLC							; Clear carry for addition
	ADC.W #$001A				; Add sprite entry size (26 bytes)
	TAX							; Transfer back to X (next slot)
	PLP							; Restore processor status
	DEY							; Decrement slot counter
	BNE CODE_0B80FC				; Loop if more slots to check
	; Fall through if no match found (implicit return)

; -----------------------------------------------------------------------------
; Battle Type Graphics Loader (Entry at $0B8121)
; -----------------------------------------------------------------------------
; Purpose: Load graphics pointers based on battle type and battle phase
; Inputs:
;   $0E8B = Battle type (0-3)
;   $193F = Battle phase index
; Outputs:
;   $0505/$0506/$0507 = Final graphics pointer
; 
; Uses two lookup tables:
;   DATA8_0B8140: Battle type → graphics address low byte
;   UNREACH_0B8144: Battle phase → graphics address high byte
;
; Combines both lookups to create complete 24-bit pointer:
;   Bank $07 always (stored in $0505)
;   Address from table combination

CODE_0B8121:
	LDA.B #$00					; Clear A high byte
	XBA							; Swap A/B (prepare for 16-bit index)
	LDA.W $0E8B					; Load battle type
	TAX							; Transfer to X for table lookup
	LDA.L DATA8_0B8140,X		; Load graphics address low byte from table
	STA.W $0507					; Store to pointer low byte
	LDA.W $193F					; Load battle phase index
	TAX							; Transfer to X for second lookup
	LDA.L UNREACH_0B8144,X		; Load graphics address high byte from table
	STA.W $0506					; Store to pointer high byte
	LDA.B #$07					; Bank $07 (graphics/sound bank)
	STA.W $0505					; Store to pointer bank byte
	RTL							; Return to caller

; Data Tables for Graphics Pointers
DATA8_0B8140:
	db $88,$8B					; Type 0: $XX88, Type 1: $XX8B
	db $88						; Type 2: $XX88
	db $85						; Type 3: $XX85

UNREACH_0B8144:
	db $0F						; Phase 0: $0FXX
	db $2F,$4F,$6F,$8F			; Phases 1-4: $2FXX, $4FXX, $6FXX, $8FXX

; -----------------------------------------------------------------------------
; CODE_0B8149: Battle Initialization Routine
; -----------------------------------------------------------------------------
; Purpose: Initialize battle state variables and load enemy data
; Sets up:
;   - Battle flags and counters
;   - Enemy formation data
;   - Sound effect queues
;   - Sprite data clearing
;
; Key Variables:
;   $19F6 = Battle phase counter (cleared to 0)
;   $19A5 = Battle flags (set to $80)
;   $1A45 = Animation enable flag (set to $01)
;   $0E89/$0E91 = Enemy formation pointers
;
; Process:
;   1. Clear battle phase counter
;   2. Set battle active flag ($80)
;   3. Enable animations
;   4. Load enemy formation from $19F1/$19F0
;   5. Play battle start sound ($F2)
;   6. Load enemy stats from formation tables
;   7. Clear battle sprite buffers ($0EC8-$0F88 range)

CODE_0B8149:
	STZ.W $19F6					; Clear battle phase counter
	LDA.B #$80					; Battle active flag
	STA.W $19A5					; Store to battle flags
	LDA.B #$01					; Animation enable
	STA.W $1A45					; Store to animation flag
	LDX.W $19F1					; Load enemy formation ID (16-bit)
	STX.W $0E89					; Store to formation pointer
	LDA.W $19F0					; Load enemy formation bank
	STA.W $0E91					; Store to formation bank pointer
	BNE CODE_0B81A5				; Branch if not zero (custom formation)
	
	; Standard formation loading
	LDA.B #$F2					; Sound effect ID ($F2 = battle start fanfare)
	JSL.L CODE_00976B			; Play sound effect (Bank $00)
	STZ.W $1A5B					; Clear sprite animation index
	LDA.W $0E88					; Load formation type
	REP #$20					; Set A to 16-bit mode
	AND.W #$00FF				; Mask to 8-bit value
	ASL A						; Multiply by 2 (word table)
	TAX							; Transfer to X for lookup
	LDA.L UNREACH_07F7C3,X		; Load formation data pointer (Bank $07)
	STA.W $0E89					; Store to formation pointer
	SEP #$20					; Set A to 8-bit mode
	LDA.B #$F3					; Sound effect ID ($F3 = battle music start)
	JSL.L CODE_009776			; Play sound effect (Bank $00)
	BNE CODE_0B81A5				; Branch if... (condition unclear, likely error check)
	
	; Clear sprite data buffers
	LDA.B #$02					; Battle type = 2 (?)
	STA.W $0E8B					; Store to battle type
	LDX.W #$0000				; X = buffer index
	LDA.B #$20					; Counter = 32 bytes

CODE_0B8192:  ; Clear first buffer section
	STZ.W $0EC8,X				; Clear byte at $0EC8+X
	STZ.W $0F28,X				; Clear byte at $0F28+X
	INX							; Increment index
	DEC A						; Decrement counter
	BNE CODE_0B8192				; Loop until 32 bytes cleared
	
	LDA.B #$30					; Counter = 48 bytes

CODE_0B819E:  ; Clear second buffer section
	STZ.W $0EC8,X				; Clear byte at $0EC8+X
	INX							; Increment index
	DEC A						; Decrement counter
	BNE CODE_0B819E				; Loop until 48 bytes cleared

CODE_0B81A5:  ; Enemy data loading
	LDA.W $0E91					; Load formation bank
	REP #$20					; Set A to 16-bit mode
	AND.W #$00FF				; Mask to 8-bit value
	ASL A						; Multiply by 2 (word table)
	TAX							; Transfer to X for lookup
	LDA.L DATA8_07AF3B,X		; Load enemy data table pointer (Bank $07)
	TAX							; Transfer to X (source pointer)
	SEP #$20					; Set A to 8-bit mode
	STX.W $19B5					; Store enemy data pointer
	LDY.W #$0000				; Y = destination index

CODE_0B81BC:  ; Copy enemy data loop (7 bytes)
	LDA.L DATA8_07B013,X		; Load enemy stat byte from Bank $07
	STA.W $1910,Y				; Store to battle RAM at $1910+Y
	INX							; Increment source
	INY							; Increment destination
	CPY.W #$0007				; Copied 7 bytes?
	BNE CODE_0B81BC				; Loop until 7 bytes copied
	
	; Calculate enemy HP multiplier (?)
	LDA.B #$0A					; Multiplier = 10
	STA.W $211B					; Store to hardware multiply register
	STZ.W $211B					; Clear upper byte (10 × 256 = 2560?)
	LDA.W $1911					; Load enemy base stat
	STA.W $211C					; Store to multiply operand
	LDX.W $2134					; Load multiply result (16-bit)
	STX.W $19B7					; Store calculated value
	
	LDY.W #$0000				; Y = destination index

CODE_0B81E1:  ; Copy extended enemy data (10 bytes)
	LDA.L DATA8_0B8CD9,X		; Load data from Bank $0B table
	STA.W $1918,Y				; Store to battle RAM at $1918+Y
	INX							; Increment source
	INY							; Increment destination
	CPY.W #$000A				; Copied 10 bytes?
	BNE CODE_0B81E1				; Loop until 10 bytes copied
	
	; Enemy graphics pointer setup
	LDX.W #$FFFF				; Default = no graphics ($FFFF)
	LDA.W $1912					; Load enemy graphics ID
	CMP.B #$FF					; Check if no graphics
	BEQ CODE_0B8207				; Skip graphics load if $FF
	REP #$20					; Set A to 16-bit mode
	AND.W #$00FF				; Mask to 8-bit value
	ASL A						; Multiply by 2 (word table)
	TAX							; Transfer to X for lookup
	LDA.L DATA8_0B8892,X		; Load graphics pointer from table
	TAX							; Transfer to X (pointer value)
	SEP #$20					; Set A to 8-bit mode

CODE_0B8207:
	STX.W $19B9					; Store enemy graphics pointer
	
	; Extract palette bits from enemy attributes
	LDA.W $1916					; Load enemy attribute byte 1
	AND.B #$E0					; Mask bits 5-7 (palette high bits)
	LSR A						; Shift right 3 times (move to low bits)
	LSR A
	LSR A
	STA.W $1A55					; Store palette high bits
	LDA.W $1915					; Load enemy attribute byte 2
	AND.B #$E0					; Mask bits 5-7 (palette low bits)
	ORA.W $1A55					; Combine with high bits
	LSR A						; Shift right 2 more times
	LSR A						; Final palette value = bits combined >> 2
	STA.W $1A55					; Store final palette index
	RTL							; Return to caller

; -----------------------------------------------------------------------------
; CODE_0B8223: Battle Layer Data Initialization
; -----------------------------------------------------------------------------
; Purpose: Initialize background layer data for battle screen
; Sets up:
;   - Layer scroll positions ($190C/$190E = 0)
;   - Layer data buffers ($1A4A+ = default values)
;   - Background graphics parameters from lookup tables
;
; Tables Used:
;   DATA8_0B8296: Default layer values (11 bytes)
;   DATA8_0B8450: Background graphics primary table
;   DATA8_0B844F: Background graphics attribute table
;   DATA8_0B84DF: Background layer configuration table
;   DATA8_0B829E: Layer scroll/position table
;
; Process:
;   1. Clear layer scroll positions
;   2. Copy default values to $1A4A (11 bytes)
;   3. Check if special background ($1A55 != 0)
;   4. If special: Load from complex multi-table system
;   5. Configure layer attributes, positions, scroll speeds

CODE_0B8223:
	PHB							; Save data bank
	PHK							; Push program bank
	PLB							; Set DB = program bank ($0B)
	LDX.W #$0000				; X = index
	TXA							; Clear A
	XBA							; Clear B (16-bit clear)
	STX.W $190C					; Clear layer 1 scroll X
	STX.W $190E					; Clear layer 2 scroll X

CODE_0B8231:  ; Copy default values loop
	LDA.W DATA8_0B8296,X		; Load default byte
	STA.W $1A4A,X				; Store to layer data buffer
	INX							; Increment index
	CPX.W #$000B				; Copied 11 bytes?
	BNE CODE_0B8231				; Loop until complete
	
	LDA.W $1A55					; Load background type index
	BEQ CODE_0B8294				; Exit if 0 (no special background)
	
	; Special background setup (complex multi-table lookup)
	DEC A						; Decrement for 0-based index
	ASL A						; Multiply by 4 (ASL twice)
	ASL A						; Each entry = 4 bytes
	TAX							; Transfer to X for lookup
	
	; Load 3 bytes from primary table
	LDA.W DATA8_0B8450,X		; Load byte 0
	STA.W $1A55					; Store background param 0
	LDA.W DATA8_0B8451,X		; Load byte 1
	STA.W $1A56					; Store background param 1
	LDA.W DATA8_0B8452,X		; Load byte 2
	STA.W $1A57					; Store background param 2
	
	; Process attribute byte (bits 0-2 and bits 4-6)
	LDA.W DATA8_0B844F,X		; Load attribute byte
	PHA							; Save it
	AND.B #$07					; Mask bits 0-2
	STA.W $1A4C					; Store layer type (0-7)
	PLA							; Restore attribute
	AND.B #$70					; Mask bits 4-6 (palette bits)
	LSR A						; Shift right twice (divide by 4)
	LSR A						; Now bits are in position
	TAX							; Transfer to X for second lookup
	
	; Load layer configuration (3 bytes from second table)
	LDA.W DATA8_0B84DF,X		; Load config byte 0
	STA.W $1A50					; Store layer config 0
	LDA.W DATA8_0B84E0,X		; Load config byte 1
	STA.W $1A51					; Store layer config 1
	LDA.W DATA8_0B84E2,X		; Load config byte 2
	STA.W $1A4F					; Store layer priority
	
	; Load scroll/position data (3 bytes from third table)
	LDA.W DATA8_0B84E1,X		; Load scroll index
	TAX							; Transfer to X for third lookup
	LDA.W DATA8_0B829E,X		; Load scroll value 0
	STA.W $1A52					; Store layer scroll X
	LDA.W DATA8_0B829F,X		; Load scroll value 1
	STA.W $1A53					; Store layer scroll Y
	LDA.W DATA8_0B82A0,X		; Load scroll value 2
	STA.W $1A54					; Store layer scroll speed
	
	LDA.B #$17					; Layer count/flags = $17
	STA.W $1A4E					; Store to layer control

CODE_0B8294:
	PLB							; Restore data bank
	RTL							; Return to caller

; Data Tables
DATA8_0B8296:
	db $00,$00,$00,$49,$15,$00,$00,$00	; Default layer values (11 bytes total)

DATA8_0B829E:
	db $20						; Scroll table entry 0

DATA8_0B829F:
	db $00						; Scroll table entry 1

DATA8_0B82A0:
	db $30						; Scroll table entry 2
	db $00,$00,$20,$20,$00,$00,$20,$30,$00	; Additional scroll entries

; =============================================================================
; Bank $0B Cycle 1 Summary
; =============================================================================
; Lines documented: ~350 lines
; Source coverage: Lines 1-400 (400 source lines)
; Documentation ratio: ~88% (code requires inline analysis)
;
; Key Routines Documented:
; 1. CODE_0B8000: Battle graphics setup (4 battle types)
; 2. Sprite animation handler (OAM updates, frame data loading)
; 3. Sprite deactivation routine (priority clearing)
; 4. CODE_0B80D9: Animation state setup
; 5. Sprite data search (linear search, 22 slots)
; 6. Battle type graphics loader (dual-table lookup)
; 7. CODE_0B8149: Battle initialization (formations, sound, sprite clearing)
; 8. CODE_0B8223: Background layer initialization (multi-table configuration)
;
; Technical Discoveries:
; - Battle system uses 4 types with different graphics pointers
; - Sprite table: 22 slots × 26 bytes each = 572 bytes
; - OAM mirror at $0C02+ (hardware Object Attribute Memory copy)
; - Multi-table lookup system for background configuration
; - Hardware multiply used for enemy HP calculation ($211B/$211C/$2134)
; - Direct page optimization for sprite table access (PEA/PLD)
; - Cross-bank calls to Banks $00 (sound), $01 (sprites), $07 (data)
;
; Cross-Bank Integration:
; - Bank $00: Sound effects (CODE_00976B, CODE_009776), frame data (DATA8_00FDCA)
; - Bank $01: Sprite rendering (CODE_01AE86), OAM tables (DATA8_01A63A)
; - Bank $07: Enemy data (DATA8_07AF3B, DATA8_07B013, UNREACH_07F7C3)
; - Bank $0A: Graphics tile data (referenced by pointers at $0505-$0507)
; - Bank $0B: Enemy graphics pointers (DATA8_0B8892), layer config (multiple tables)
;
; Hardware Registers Used:
; - $211B/$211C: Hardware multiply (SNES PPU math unit)
; - $2134: Hardware multiply result (16-bit)
; - $0C02-$0C0F: OAM data mirror (copied to PPU during V-blank)
;
; Next Cycle: Lines 400-800
; - Continue battle effects code
; - Animation frame management
; - More data tables and lookup systems
; =============================================================================
; =============================================================================
; Bank $0B - Cycle 2 Documentation (Lines 400-800)
; =============================================================================
; Coverage: Battle State Management, Graphics Decompression, Hardware Setup
; Type: Executable 65816 assembly code
; Focus: Battle configuration, data copying, PPU register initialization
; =============================================================================

; -----------------------------------------------------------------------------
; CODE_0B82CB: Battle State Flag Configuration
; -----------------------------------------------------------------------------
; Purpose: Configure battle state flags based on battle conditions
; Modifies: $19B4 (battle state flags), $19CB (battle mode bits)
; 
; Process:
;   1. Clear lower nibble of $19B4 (reset battle phase flags)
;   2. Check bit 3 of $19CB (battle type flag)
;   3. If set AND $0E8D != 0: Set special flag (incomplete code at $0B82DF)
;   4. Extract bits 0-2 from $19CB, combine with $19D3 sign bit
;   5. Merge into $19B4 lower nibble
;   6. Choose configuration table offset: $0000 or $000A based on flags
;   7. Copy 10 bytes from DATA8_0B8324 table to $1993
;   8. Set PPU BG map pointer based on $1910 sign bit:
;      - Negative: $0E0E (alternate map)
;      - Positive: $0E06 (default map)
;
; Battle State Bits ($19B4):
;   Bit 0-2: Battle phase/type (from $19CB bits 0-2)
;   Bit 3: Sign extension (from $19D3)
;   Bit 4-7: Cleared at entry

CODE_0B82CB:
	LDA.W $19B4					; Load current battle state
	AND.B #$F0					; Clear lower nibble (bits 0-3)
	STA.W $19B4					; Store cleared flags
	
	LDA.W $19CB					; Load battle mode register
	AND.B #$08					; Check bit 3 (special battle type?)
	BEQ CODE_0B82E3				; Skip if not set
	LDA.W $0E8D					; Load battle condition register
	BEQ CODE_0B82E3				; Skip if zero
	
	; Incomplete special case code (appears to set flag but never branches)
	db $A9,$01,$80,$05			; LDA #$01 / BRA +5 (dead code?)

CODE_0B82E3:
	LDA.W $19CB					; Load battle mode register
	AND.B #$07					; Mask bits 0-2 (phase bits)
	XBA							; Swap to high byte
	LDA.W $19D3					; Load battle subtype
	BPL CODE_0B82F2				; Branch if positive
	
	; Negative subtype: Set bit 3 in phase value
	XBA							; Swap back to low byte
	ORA.B #$08					; Set bit 3 (sign extension)
	XBA							; Swap to high byte again

CODE_0B82F2:
	XBA							; Swap back to low byte
	ORA.W $19B4					; Merge with cleared state flags
	STA.W $19B4					; Store final battle state
	
	; Choose configuration table offset
	LDX.W #$0000				; Default offset = 0
	AND.B #$07					; Check merged bits 0-2
	DEC A						; Decrement for comparison
	BEQ CODE_0B8304				; If result == 0, use default offset
	LDX.W #$000A				; Otherwise, offset = 10 (second table)

CODE_0B8304:
	; Copy 10 configuration bytes
	LDY.W #$0000				; Y = destination index

CODE_0B8307:  ; Copy loop
	LDA.L DATA8_0B8324,X		; Load config byte from table
	STA.W $1993,Y				; Store to battle config RAM
	INX							; Increment source
	INY							; Increment destination
	CPY.W #$000A				; Copied 10 bytes?
	BNE CODE_0B8307				; Loop until complete
	
	; Set PPU background map pointer
	LDX.W #$0E06				; Default BG map = $0E06
	LDA.W $1910					; Load enemy attribute flags
	BPL CODE_0B8320				; Use default if positive
	LDX.W #$0E0E				; Alternate BG map = $0E0E (for special enemies)

CODE_0B8320:
	STX.W $19B2					; Store BG map pointer
	RTL							; Return

; Configuration Data Tables
DATA8_0B8324:
	; Table 0 (offset $00): Default battle configuration
	db $10,$40,$04,$02,$0C,$02,$00,$00,$00,$00
	
	; Table 1 (offset $0A): Alternate battle configuration
	db $10,$C0,$0C,$02,$04,$02,$00,$00,$00,$00

; -----------------------------------------------------------------------------
; CODE_0B8338: Battle Map Tile Lookup and Animation Frame Calculation
; -----------------------------------------------------------------------------
; Purpose: Complex tile lookup with hardware multiply for map coordinates
; Uses: SNES hardware multiply registers ($4202/$4203/$4216)
; Input: Y register (contains map coordinate data)
; Output: A = tile attributes, X = animation frame offset
;
; Hardware Multiply Calculation:
;   1. Extract high byte from Y coordinate
;   2. Multiply by $1924 (map row stride)
;   3. Mask to 6 bits ($003F), add multiply result
;   4. Use as index into $7F8000 (battle map data in WRAM)
;   5. Extract tile ID (bits 0-6), lookup animation frame at $7FD174

CODE_0B8338:
	REP #$20					; Set A to 16-bit
	TYA							; Transfer Y to A (coordinate data)
	SEP #$20					; Set A to 8-bit
	XBA							; Get high byte
	STA.W $4202					; Store to multiply register A
	LDA.W $1924					; Load map row stride
	STA.W $4203					; Store to multiply register B
	XBA							; Swap back
	REP #$20					; Set A to 16-bit
	AND.W #$003F				; Mask to 6 bits (column offset)
	CLC							; Clear carry
	ADC.W $4216					; Add multiply result (row offset)
	TAX							; Transfer to X (save index)
	TAY							; Transfer to Y (save index again)
	
	; Tile data lookup
	SEP #$20					; Set A to 8-bit
	LDA.L $7F8000,X				; Load tile data from WRAM
	PHA							; Save tile data
	
	; Animation frame lookup
	REP #$20					; Set A to 16-bit
	AND.W #$007F				; Mask to tile ID (bits 0-6)
	ASL A						; Multiply by 2 (word table)
	TAX							; Transfer to X for lookup
	LDA.L $7FD174,X				; Load animation frame offset
	SEP #$20					; Set A to 8-bit
	TAX							; Transfer frame offset to X
	PLA							; Restore tile data
	RTS							; Return (A = tile data, X = frame offset)

; -----------------------------------------------------------------------------
; CODE_0B836A: Enemy Graphics Decompression Routine
; -----------------------------------------------------------------------------
; Purpose: Decompress enemy graphics data from Bank $06 to WRAM $7F:CEF4
; Uses: MVN (Move Negative) block transfer instruction
; Process: Processes enemy attribute flags ($1918 bits 0-3) through 3 tables
;
; MVN Instruction:
;   MVN dest_bank, source_bank
;   Copies (A+1) bytes from (source_bank:X) to (dest_bank:Y)
;   Decrements A, increments X/Y until A wraps to $FFFF
;
; Decompression Tables:
;   DATA8_0B83AC: Block sizes (2 bytes each) - 3 entries
;   DATA8_0B83AD: Block size high bytes
;   DATA8_0B83B2: Source addresses in Bank $06

CODE_0B836A:
	PHB							; Save data bank
	PHK							; Push program bank ($0B)
	PLB							; Set data bank = $0B
	LDX.W #$0000				; X = table index
	LDY.W #$CEF4				; Y = dest address (WRAM)
	LDA.W $1918					; Load enemy graphics flags
	AND.B #$0F					; Mask to lower nibble

CODE_0B8378:  ; Decompression loop (3 blocks)
	PHX							; Save table index
	PHA							; Save graphics flags
	XBA							; Swap A (preserve flags in B)
	
	; Calculate block size from table
	LDA.W DATA8_0B83AC,X		; Load size low byte
	STA.W $211B					; Store to hardware multiply low
	LDA.W DATA8_0B83AD,X		; Load size high byte
	STA.W $211B					; Store to hardware multiply high
	XBA							; Swap back (flags to A)
	STA.W $211C					; Store flags as multiplier
	
	; Calculate source address
	REP #$20					; Set A to 16-bit
	LDA.W DATA8_0B83B2,X		; Load base address from table
	CLC							; Clear carry
	ADC.W $2134					; Add multiply result (offset)
	PHA							; Save calculated source address
	LDA.W DATA8_0B83AC,X		; Load block size again
	DEC A						; Decrement for MVN (size-1)
	PLX							; Pop source address to X
	SEP #$20					; Set A to 8-bit
	
	; Block transfer
	PHB							; Save current data bank
	MVN $7F,$06					; Copy from Bank $06 to WRAM Bank $7F
								; Copies (A+1) bytes: Bank$06:X → $7F:Y
	PLB							; Restore data bank
	
	PLA							; Restore graphics flags
	PLX							; Restore table index
	INX							; Increment table index
	INX							; (2 bytes per entry)
	CPX.W #$0006				; Processed 3 blocks?
	BNE CODE_0B8378				; Loop for next block
	
	PLB							; Restore original data bank
	RTL							; Return

; Decompression Configuration Tables
DATA8_0B83AC:
	db $00						; Block 0 size low byte

DATA8_0B83AD:
	db $02						; Block 0 size high byte = $0200 (512 bytes)
	db $80,$00					; Block 1 size = $0080 (128 bytes)
	db $00,$01					; Block 2 size = $0100 (256 bytes)

DATA8_0B83B2:
	db $00,$80					; Block 0 source = $8000
	db $00,$A0					; Block 1 source = $A000
	db $00,$A8					; Block 2 source = $A800

; -----------------------------------------------------------------------------
; CODE_0B83B8: Enemy Graphics Data Transfer
; -----------------------------------------------------------------------------
; Purpose: Copy 128 bytes of enemy sprite data from Bank $05 to WRAM $7F:C588
; Special case: Enemy ID $19 uses Bank $07 source instead
;
; Transfer calculation:
;   $1919 (enemy ID) × 128 bytes ($80) = offset in Bank $05
;   Source: Bank$05:$8000 + offset → Dest: $7F:$C588

CODE_0B83B8:
	LDA.W $1919					; Load enemy sprite ID
	CMP.B #$19					; Check if special enemy (ID $19)
	BEQ CODE_0B83DF				; Branch to special case
	
	; Standard enemy graphics transfer
	STA.W $4202					; Store ID to multiply register A
	LDA.B #$80					; 128 bytes per sprite
	STA.W $4203					; Store to multiply register B
	REP #$20					; Set A to 16-bit
	LDA.W #$8000				; Base address in source bank
	CLC							; Clear carry
	ADC.W $4216					; Add multiply result (offset)
	TAX							; Transfer to X (source address)
	LDY.W #$C588				; Y = destination in WRAM
	LDA.W #$007F				; Transfer size = 128 bytes (127+1)
	PHB							; Save data bank
	MVN $7F,$05					; Copy Bank$05:X → $7F:Y
	PLB							; Restore data bank
	SEP #$20					; Set A to 8-bit
	RTL							; Return

CODE_0B83DF:  ; Special enemy $19 handler
	REP #$20					; Set A to 16-bit
	LDX.W #$D984				; Source address in Bank $07
	LDY.W #$C588				; Dest address in WRAM
	LDA.W #$007F				; Transfer size = 128 bytes
	PHB							; Save data bank
	MVN $7F,$07					; Copy Bank$07:D984 → $7F:C588
	PLB							; Restore data bank
	SEP #$20					; Set A to 8-bit
	RTL							; Return

; -----------------------------------------------------------------------------
; CODE_0B83F2: Battle Background Tile Data Transfer
; -----------------------------------------------------------------------------
; Purpose: Copy 3 sets of 16 bytes each from Bank $07 to WRAM battle buffers
; Destination addresses suggest background tile patterns for layered rendering
;
; Transfers:
;   1. Bank$07:D824 (16 bytes) → $7F:C568
;   2. Bank$07:D824 (16 bytes) → $7F:C4F8
;   3. Bank$07:D834 (16 bytes) → $7F:C548

CODE_0B83F2:
	PHB							; Save data bank
	REP #$20					; Set A to 16-bit
	
	; Transfer 1
	LDX.W #$D824				; Source address
	LDY.W #$C568				; Dest address
	LDA.W #$000F				; Size = 16 bytes (15+1)
	MVN $7F,$07					; Copy Bank$07 → WRAM
	
	; Transfer 2 (same source, different destination)
	LDX.W #$D824				; Source address (reused)
	LDY.W #$C4F8				; Dest address (different layer?)
	LDA.W #$000F				; Size = 16 bytes
	MVN $7F,$07					; Copy Bank$07 → WRAM
	
	; Transfer 3
	LDX.W #$D834				; Source address (offset +$10)
	LDY.W #$C548				; Dest address
	LDA.W #$000F				; Size = 16 bytes
	MVN $7F,$07					; Copy Bank$07 → WRAM
	
	SEP #$20					; Set A to 8-bit
	PLB							; Restore data bank
	RTL							; Return

; -----------------------------------------------------------------------------
; CODE_0B841D: PPU Register Configuration for Battle Graphics
; -----------------------------------------------------------------------------
; Purpose: Configure SNES PPU registers for battle screen rendering
; Sets: BG map addresses, layer blending, color math modes
;
; PPU Registers:
;   $2107: BG1 tilemap address and size
;   $2108: BG2 tilemap address and size
;   $212C: Main screen designation (which layers visible)
;   $212D: Subscreen designation (for transparency effects)
;   $2130: Color math control (how layers blend)
;   $2131: Color math mode (addition/subtraction)
;
; Battle layer configuration loaded from $1A4D-$1A51 (set by earlier routines)

CODE_0B841D:
	LDA.B #$41					; BG1 map = $4100, size 32×32 tiles
	STA.W $2107					; Write to BG1 tilemap register
	
	LDA.W $1A4D					; Load BG2 tilemap config
	STA.W $2108					; Write to BG2 tilemap register
	
	LDA.W $1A4E					; Load main screen layers
	STA.W $212C					; Write to main screen designation
	
	LDA.W $1A4F					; Load subscreen layers (for blending)
	STA.W $212D					; Write to subscreen designation
	
	LDA.W $1A50					; Load color math control
	STA.W $2130					; Write to color math register
	
	; Special handling for battle mode $70
	LDY.W $1A51					; Load color math mode config
	LDA.W $19CB					; Load battle mode flags
	AND.B #$70					; Check bits 4-6
	CMP.B #$70					; All three bits set?
	BNE CODE_0B844A				; Skip if not
	
	; Mode $70: Enable additional blending bit
	TYA							; Transfer config to A
	ORA.B #$10					; Set bit 4 (enable fixed color addition?)
	TAY							; Transfer back to Y

CODE_0B844A:
	TYA							; Transfer final config to A
	STA.W $2131					; Write to color math mode register
	RTL							; Return

; -----------------------------------------------------------------------------
; Background Graphics Configuration Tables
; -----------------------------------------------------------------------------
; Complex multi-table system for configuring battle backgrounds
; Referenced by CODE_0B8223 (documented in Cycle 1)

DATA8_0B844F:
	db $14						; Attribute byte for background type 0

DATA8_0B8450:
	db $1A						; Graphics address low byte 0

DATA8_0B8451:
	db $08						; Graphics address high byte 0

DATA8_0B8452:
	db $01						; Bank/flags byte 0
	
	; Additional background configurations (16 entries × 4 bytes each)
	; Format: [attr] [addr_low] [addr_high] [bank/flags]
	db $14,$44,$08,$01			; Background type 1
	db $14,$4A,$0F,$01			; Background type 2
	db $04,$28,$04,$03			; Background type 3
	db $34,$51,$0F,$01			; Background type 4
	db $04,$04,$04,$00			; Background type 5
	db $04,$04,$04,$03			; Background type 6
	db $14,$1C,$08,$01			; Background type 7
	db $34,$22,$08,$01			; Background type 8
	db $54,$31,$0F,$01			; Background type 9
	db $04,$22,$08,$01			; Background type 10
	db $04,$57,$08,$01			; Background type 11
	db $14,$3F,$08,$01			; Background type 12
	db $04,$32,$04,$03			; Background type 13
	db $54,$7F,$0F,$00			; Background type 14
	db $04,$2F,$04,$02			; Background type 15
	db $14,$51,$08,$01			; Background type 16
	db $04,$0A,$08,$01			; Background type 17

; Layer scroll/animation configuration table (18 entries × 4 bytes each)
DATA8_0B8497:
	db $03,$15,$00,$00			; Scroll config 0
	db $33,$39,$00,$00			; Scroll config 1
	db $03,$15,$00,$00			; Scroll config 2
	db $35,$05,$00,$00			; Scroll config 3
	db $03,$17,$00,$00			; Scroll config 4
	db $03,$16,$00,$00			; Scroll config 5
	db $35,$10,$00,$00			; Scroll config 6
	db $35,$11,$00,$00			; Scroll config 7
	db $02,$28,$E0,$FF			; Scroll config 8 (negative scroll?)
	db $02,$2A,$00,$00			; Scroll config 9
	db $02,$AB,$00,$00			; Scroll config 10
	db $26,$29,$00,$00			; Scroll config 11
	db $21,$FF,$00,$00			; Scroll config 12
	db $31,$08,$00,$12			; Scroll config 13
	db $61,$00,$00,$EE			; Scroll config 14
	db $01,$15,$00,$17			; Scroll config 15
	db $31,$12,$20,$00			; Scroll config 16
	db $41,$06,$21,$00			; Scroll config 17

; Layer blending/priority configuration table
DATA8_0B84DF:
	db $00						; Blend config 0

DATA8_0B84E0:
	db $00						; Blend config 0 (continued)

DATA8_0B84E1:
	db $00						; Scroll index 0

DATA8_0B84E2:
	db $02,$02,$40,$00,$02,$00,$00,$04	; Configs 0-1
	db $02,$00,$C2,$00,$02,$00,$00,$08	; Configs 2-3
	db $02,$02,$51,$00,$02,$00,$C1,$04	; Configs 4-5
	db $01							; Config 6 (partial)

; -----------------------------------------------------------------------------
; CODE_0B84FB: Enemy Tile Data Setup
; -----------------------------------------------------------------------------
; Purpose: Configure tile data parameters for enemy rendering
; Sets: $1924 (tile stride), $0900-$0906 (DMA parameters)
; Uses: Multi-table lookup based on enemy attributes
;
; Process:
;   1. Extract bits 4-7 from $1918 (enemy graphics mode)
;   2. Lookup tile stride from UNREACH_0B8540 table
;   3. Calculate tile data pointer from enemy ID ($1910 bits 0-5)
;   4. Multiply by 3, lookup in DATA8_0B8735 table
;   5. Setup DMA parameters for graphics transfer

CODE_0B84FB:
	REP #$20					; Set A to 16-bit
	LDA.W $1918					; Load enemy graphics flags
	AND.W #$00F0				; Mask bits 4-7 (graphics mode)
	LSR A						; Shift right 3 times (divide by 8)
	LSR A						; Now value is 0-15 (index × 2)
	LSR A
	TAX							; Transfer to X for lookup
	LDA.L UNREACH_0B8540,X		; Load tile stride (16-bit value)
	STA.W $1924					; Store to tile stride variable
	
	SEP #$20					; Set A to 8-bit
	LDA.W $1910					; Load enemy type flags
	AND.B #$3F					; Mask bits 0-5 (enemy base type)
	STA.W $4202					; Store to multiply register A
	LDA.B #$03					; Multiply by 3
	STA.W $4203					; Store to multiply register B
	
	; Setup DMA parameters
	LDX.W #$7F80				; DMA dest bank:address high
	STX.W $0904					; Store to DMA dest pointer
	STZ.W $0903					; Clear DMA dest pointer low byte
	
	LDX.W $4216					; Load multiply result (enemy_type × 3)
	REP #$20					; Set A to 16-bit
	LDA.L DATA8_0B8735,X		; Load source address from table
	STA.W $0900					; Store to DMA source pointer
	SEP #$20					; Set A to 8-bit
	LDA.L DATA8_0B8737,X		; Load source bank from table
	STA.W $0902					; Store to DMA source bank
	
	JSL.L CODE_0B8669			; Call graphics loading routine
	RTL							; Return

; Tile stride lookup table (16 entries × 2 bytes)
UNREACH_0B8540:
	db $10,$10,$20,$10,$30,$10,$40,$10	; Modes 0-3
	db $10,$20,$20,$20,$30,$20,$40,$20	; Modes 4-7
	db $10,$30,$20,$30,$30,$30,$40,$30	; Modes 8-11
	db $10,$40,$20,$40,$30,$40,$40,$40	; Modes 12-15

; -----------------------------------------------------------------------------
; CODE_0B8560: Background Layer Type Dispatcher
; -----------------------------------------------------------------------------
; Purpose: Jump table for different background layer rendering modes
; Input: $1A4C = Layer type index (0-7)
; Method: Indirect JSR through table DATA8_0B856C

CODE_0B8560:
	LDA.B #$00					; Clear A high byte
	XBA							; Prepare for 16-bit index
	LDA.W $1A4C					; Load layer type
	ASL A						; Multiply by 2 (word table)
	TAX							; Transfer to X
	JSR.W (DATA8_0B856C,X)		; Indirect jump to handler
	RTL							; Return after handler completes

; Background layer handler jump table (8 entries)
DATA8_0B856C:
	dw $8633					; Type 0 handler
	dw $857A					; Type 1 handler
	dw $85BF					; Type 2 handler
	dw $8633					; Type 3 handler (same as 0)
	dw $8634					; Type 4 handler
	dw $862E					; Type 5 handler
	dw $85BF					; Type 6 handler (same as 2)

; -----------------------------------------------------------------------------
; Background Type 1 Handler ($857A)
; -----------------------------------------------------------------------------
; Purpose: Configure static background graphics
; Special handling for negative $1A55 (special background flag)

	LDA.W $1A55					; Load background ID
	BPL CODE_0B85BE				; Skip special setup if positive
	
	; Special background setup
	LDX.W #$1000				; Special flag value
	STX.W $1A4A					; Store to background config
	
	; Load music/sound based on available data
	LDX.W #$F6D1				; Music pointer 1
	LDA.B #$03					; Music bank 3
	JSL.L CODE_009776			; Attempt to load music
	BNE CODE_0B85A9				; Skip if loaded
	
	LDX.W #$F538				; Music pointer 2 (fallback)
	LDA.B #$02					; Music bank 2
	JSL.L CODE_009776			; Attempt to load music
	BNE CODE_0B85A9				; Skip if loaded
	
	LDX.W #$F37C				; Music pointer 3 (fallback)
	LDA.B #$01					; Music bank 1
	JSL.L CODE_009776			; Attempt to load music
	BNE CODE_0B85A9				; Skip if loaded
	
	LDX.W #$F240				; Music pointer 4 (final fallback)

CODE_0B85A9:
	; Setup DMA for graphics transfer
	STX.W $0900					; Store music/graphics source
	LDA.B #$07					; Source bank 7
	STA.W $0902					; Store to DMA source bank
	LDX.W #$7F90				; Dest = WRAM $7F:90xx
	STX.W $0904					; Store to DMA dest pointer
	STZ.W $0903					; Clear dest low byte
	JSL.L CODE_0B86EA			; Call graphics decompression

CODE_0B85BE:
	RTS							; Return to dispatcher

; =============================================================================
; Bank $0B Cycle 2 Summary
; =============================================================================
; Lines documented: ~400 lines
; Source coverage: Lines 400-800 (400 source lines)
; Documentation ratio: ~100% (lots of data tables included)
;
; Key Routines Documented:
; 1. CODE_0B82CB: Battle state flag configuration
; 2. CODE_0B8338: Map tile lookup with hardware multiply
; 3. CODE_0B836A: Enemy graphics decompression (MVN block transfers)
; 4. CODE_0B83B8: Enemy sprite data transfer (128 bytes)
; 5. CODE_0B83F2: Background tile transfer (3×16 bytes)
; 6. CODE_0B841D: PPU register configuration (battle graphics setup)
; 7. CODE_0B84FB: Enemy tile data setup (DMA parameters)
; 8. CODE_0B8560: Background layer type dispatcher (jump table)
;
; Technical Discoveries:
; - MVN (Move Negative) block transfer instruction used extensively
; - Hardware multiply ($4202/$4203/$4216) for offset calculations
; - Multi-bank graphics sources: Banks $05, $06, $07
; - WRAM battle buffers: $7F:C4F8-C5FF range (sprites, tiles, maps)
; - PPU register direct writes ($2107/$2108/$212C/$212D/$2130/$2131)
; - Complex multi-table background configuration system (18+ variants)
; - Jump table dispatch pattern for layer rendering modes
; - Music/sound loading with fallback system (4 attempts)
;
; Data Tables:
; - DATA8_0B8324: Battle configuration (2 tables × 10 bytes)
; - DATA8_0B83AC/AD/B2: Decompression parameters (3 blocks)
; - DATA8_0B844F-8452: Background graphics config (18 types × 4 bytes)
; - DATA8_0B8497: Layer scroll/animation (18 configs × 4 bytes)
; - DATA8_0B84DF-E2: Layer blending/priority configs
; - UNREACH_0B8540: Tile stride lookup (16 modes × 2 bytes)
; - DATA8_0B856C: Background handler jump table (8 entries)
;
; Hardware Registers Used:
; - $4202/$4203/$4216: Hardware multiply/divide unit
; - $2107: BG1 tilemap address ($4100, 32×32)
; - $2108: BG2 tilemap address (variable)
; - $212C/$212D: Main/sub screen layer designation
; - $2130/$2131: Color math control/mode
; - $211B/$211C/$2134: Additional math unit (decompression)
;
; Cross-Bank References:
; - Bank $05: Enemy sprite data ($8000 base, 128 bytes per sprite)
; - Bank $06: Compressed graphics ($8000, $A000, $A800 blocks)
; - Bank $07: Background tiles ($D824, $D834, $D984), music ($F240-F6D1)
; - Bank $00: Sound loading (CODE_009776)
;
; Next Cycle: Lines 800-1200
; - Background rendering implementations
; - Scrolling/parallax code
; - Additional graphics effects
; - More data tables
; =============================================================================
