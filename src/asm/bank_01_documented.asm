; ===========================================================================
; Final Fantasy Mystic Quest - Bank $01 - Battle System
; ===========================================================================
; Size: 15,480 lines of disassembly
; Priority: High (core gameplay system)
; ===========================================================================
; This bank contains the complete battle system implementation including:
; - Battle initialization and state management
; - Enemy AI and behavior
; - Combat calculations (damage, hit chance, criticals)
; - Battle animations and effects
; - Turn order and timing systems
; - Victory/defeat conditions
; ===========================================================================

arch 65816
lorom

org $018000

; ===========================================================================
; Battle System Data Tables
; ===========================================================================
; These appear to be lookup tables for enemy AI behaviors or battle modes
; Format: Single bytes, possibly AI state/priority values
; $DD/$DE/$10/$11/$13 are common values (likely AI mode flags)
; ===========================================================================

DATA8_018000:
	db $1B,$3B,$19,$1A,$10,$15,$39,$18,$0C,$09,$16,$21,$33,$06,$0D,$0B
	db $27,$1D,$05,$30,$0E,$25,$1E
	db $31,$22,$1F,$0F,$34
	db $17,$10
	db $10,$13,$11
	db $DD,$10,$10                           ; AI mode flags
	db $11
	db $10,$11
	db $10
	db $10,$11,$10,$11
	db $10
	db $10,$10,$10,$10
	db $11
	
DATA8_018032:
	; AI behavior table - extensive use of $DD, $DE, $10, $11, $13
	; Likely: $DD=disabled, $DE=dead, $10=normal, $11=defend, $13=special
	db $13,$DE,$11,$DE,$10,$DE,$DE,$DE,$DE,$DD,$DE,$12,$DD,$10,$DE,$11
	db $13,$10,$11,$13,$DE,$DE,$10,$DE,$11,$DE,$10,$DE,$10,$DD,$10,$11
	db $DE,$DD,$DE,$13,$DE,$DE,$DE,$DE,$11,$DE,$DE,$DD,$DE,$11,$DE,$DE
	db $DE,$DE,$10,$DE,$11,$DE,$13,$DE,$10,$DD,$DD,$DE,$DD,$10,$10,$11
	db $13
	db $DE
	db $11,$13,$DD,$10,$11,$DE,$DD,$11,$10,$10,$11,$10,$11,$13,$10,$11
	db $10,$DE,$11,$DD,$10,$11,$13,$DE,$10,$10,$11,$11,$11,$10,$10,$10
	db $DD,$DE,$DD,$10,$10,$11,$13,$10,$DE,$11,$DD,$10,$10,$DE
	db $11
	db $10,$12,$10,$11,$13,$10
	db $11,$13
	db $10,$11
	db $10,$11,$DD,$10,$11,$10,$11,$13,$10,$11,$10,$11,$DE,$10,$11,$10
	db $11,$DD,$10,$11,$10,$11,$13,$11,$11,$11,$13,$11,$DE,$10,$11,$13
	db $10,$11,$10,$DE,$DD,$10,$11,$10,$11,$DE,$10,$10,$11,$11,$DD,$10
	db $10,$13,$11,$DE,$DE,$DE,$DE,$DE,$DE,$DE,$DE,$13,$DE,$11,$DE,$10
	db $DE,$11,$DE,$10,$DE,$DE,$11,$10,$12
	db $11,$10,$11,$10,$11

; ===========================================================================
; Battle Initialization Entry Point
; ===========================================================================
; Purpose: Initialize battle system and set up initial state
; Called from: Main game engine when entering battle
; Technical Details:
;   - Sets up battle flags and counters
;   - Initializes actor states
;   - Prepares graphics and buffers
; ===========================================================================

CODE_0180FB:
	SEP #$20                         ; 8-bit A
	REP #$10                         ; 16-bit X,Y
	
	; Initialize battle state flags
	LDA.B #$FF                       ; Invalid enemy marker
	STA.W $19A5                      ; Current enemy ID
	
	STZ.W $1A46                      ; Clear battle phase counter
	STZ.W $1A45                      ; Clear animation frame
	STZ.W $19AC                      ; Clear turn counter
	STZ.W $19AF                      ; Clear status effect timer
	
	; Set initial combat parameters
	LDA.B #$02                       ; Battle mode = 2
	STA.W $19D7                      ; Battle state flags
	
	LDA.B #$40                       ; Default animation speed
	STA.W $19B4                      ; Animation timer
	
	LDA.B #$10                       ; Initial turn gauge value
	STA.W $1993                      ; Active time battle gauge
	
	; Initialize subsystems
	JSR.W CODE_01817C                ; Initialize battle buffers
	JSR.W CODE_0181BA                ; Clear VRAM battle area
	JSR.W CODE_0181DC                ; Load battle graphics
	
	; Set up actor positions
	REP #$30                         ; 16-bit A,X,Y
	STZ.W $19EE                      ; Clear actor index
	
	LDA.W #$00F8                     ; Y position = 248
	STA.W $1902                      ; Actor 0 Y position
	STA.W $1906                      ; Actor 1 Y position
	
	LDA.W #$0008                     ; X position = 8
	STA.W $1900                      ; Actor 0 X position
	STA.W $1904                      ; Actor 1 X position
	
	; Initialize enemy data
	JSL.L CODE_0B87B9                ; Load enemy stats from Bank $0B
	
	SEP #$20                         ; 8-bit A
	REP #$10                         ; 16-bit X,Y
	
	; Clear WRAM battle buffer ($019400-$01A400)
	STZ.W $1A46                      ; Reset phase counter
	
	LDX.W #$9400                     ; WRAM battle buffer
	STX.W SNES_WMADDL                ; Set WRAM address low/mid
	
	LDA.B #$01                       ; Bank $01 (this bank)
	STA.W SNES_WMADDH                ; Set WRAM address high
	
	LDY.W #$1000                     ; 4096 bytes to clear
	
CODE_018158:
	; Clear loop
	STZ.W SNES_WMDATA                ; Write zero to WRAM
	DEY                              ; Decrement counter
	BNE CODE_018158                  ; Continue until done
	
	; Initialize actor status arrays
	REP #$30                         ; 16-bit A,X,Y
	PHB                              ; Save data bank
	
	LDA.W #$FFFF                     ; Fill pattern
	STA.W $1A72                      ; First word of status array
	
	LDX.W #$1A72                     ; Source address
	LDY.W #$1A73                     ; Destination address  
	LDA.W #$023B                     ; 571 bytes to copy
	MVN $00,$00                      ; Block fill (source bank, dest bank)
	
	PLB                              ; Restore data bank
	
	; Set WRAM battle flag
	LDA.W #$FFFF                     ; Battle active flag
	STA.L $7F9400                    ; Store in extended WRAM
	
	RTL                              ; Return to caller

; ===========================================================================
; Initialize Battle Buffers
; ===========================================================================
; Purpose: Set up WRAM buffers for battle data
; Technical Details: Copies static data from ROM to WRAM
; ===========================================================================

CODE_01817C:
	PHB                              ; Save data bank
	PHP                              ; Save processor status
	REP #$30                         ; 16-bit A,X,Y
	
	; Clear $7FC488-$7FC588 (256 bytes)
	LDA.W #$0000
	STA.L $7FC488                    ; First word
	
	LDY.W #$C489                     ; Destination
	LDX.W #$C488                     ; Source
	LDA.W #$00FF                     ; 255 bytes
	MVN $7F,$7F                      ; Block fill
	
	; Copy battle configuration tables from Bank $07
	LDY.W #$C568                     ; Dest: $7FC568
	LDX.W #$D824                     ; Source: $07D824
	LDA.W #$000F                     ; 16 bytes
	MVN $7F,$07                      ; Copy from Bank $07
	
	LDY.W #$C4F8                     ; Dest: $7FC4F8
	LDX.W #$D824                     ; Source: $07D824
	LDA.W #$000F                     ; 16 bytes
	MVN $7F,$07                      ; Copy from Bank $07
	
	LDY.W #$C548                     ; Dest: $7FC548
	LDX.W #$D834                     ; Source: $07D834
	LDA.W #$000F                     ; 16 bytes
	MVN $7F,$07                      ; Copy from Bank $07
	
	PLP                              ; Restore processor status
	PLB                              ; Restore data bank
	RTS                              ; Return

; ===========================================================================
; Clear VRAM Battle Area
; ===========================================================================
; Purpose: Clear VRAM area used for battle graphics
; VRAM Range: $4000-$5000 (4096 bytes)
; Technical Details: Fills with tile $01FF (blank/transparent)
; ===========================================================================

CODE_0181BA:
	PHP                              ; Save processor status
	SEP #$20                         ; 8-bit A
	REP #$10                         ; 16-bit X,Y
	
	; Set VRAM parameters
	LDA.B #$80                       ; Increment after writing to $2119
	STA.W SNES_VMAINC                ; VRAM increment mode
	
	STZ.W SNES_VMADDL                ; VRAM address low = $00
	
	LDA.B #$40                       ; VRAM address high = $40
	STA.W SNES_VMADDH                ; VRAM address = $4000
	
	REP #$30                         ; 16-bit A,X,Y
	LDX.W #$1000                     ; 4096 words to write
	LDA.W #$01FF                     ; Tile number $01FF (blank)
	
CODE_0181D4:
	; Write loop
	STA.W SNES_VMDATAL               ; Write tile to VRAM
	DEX                              ; Decrement counter
	BNE CODE_0181D4                  ; Continue until done
	
	PLP                              ; Restore processor status
	RTS                              ; Return

; ===========================================================================
; Load Battle Graphics
; ===========================================================================
; Purpose: Load battle sprite graphics to WRAM buffers
; Technical Details: Decompresses and copies graphics from Bank $04
; ===========================================================================

CODE_0181DC:
	SEP #$20                         ; 8-bit A
	REP #$10                         ; 16-bit X,Y
	PHD                              ; Save direct page
	
	PEA.W $192B                      ; Set direct page to $192B
	PLD                              ; Pull to D register
	
	; Load graphics set 1
	LDX.W #$0780                     ; Destination offset
	LDY.W #$C708                     ; Source offset
	LDA.B #$10                       ; 16 tiles
	JSR.W CODE_018208                ; Decompress/load graphics
	
	; Load graphics set 2
	LDX.W #$0900                     ; Destination offset
	LDY.W #$C908                     ; Source offset
	LDA.B #$0C                       ; 12 tiles
	JSR.W CODE_018208                ; Decompress/load graphics
	
	; Load graphics set 3
	LDX.W #$0A80                     ; Destination offset
	LDY.W #$CA48                     ; Source offset
	LDA.B #$1C                       ; 28 tiles
	JSR.W CODE_018208                ; Decompress/load graphics
	
	PLD                              ; Restore direct page
	RTS                              ; Return

; ===========================================================================
; Decompress and Load Battle Graphics
; ===========================================================================
; Purpose: Decompress compressed graphics and load to WRAM buffer
; Input: 
;   X = Destination offset (in WRAM)
;   Y = Source offset (compressed data)
;   A = Number of tiles
; Technical Details:
;   - Uses decompression algorithm (likely ExpandSecondHalfWithZeros)
;   - Copies from Bank $04 to Bank $7F WRAM
; ===========================================================================

CODE_018208:
	PHP                              ; Save processor status
	REP #$30                         ; 16-bit A,X,Y
	
	STX.B $00                        ; Store destination offset
	STY.B $02                        ; Store source offset
	
	AND.W #$00FF                     ; Mask to byte
	STA.B $04                        ; Store tile count
	STA.B $06                        ; Store loop counter
	
CODE_018216:
	; Loop through each tile
	JSR.W CODE_01822F                ; Decompress one tile
	
	LDA.B $00                        ; Get destination offset
	CLC
	ADC.W #$0018                     ; Add $18 (24 bytes per compressed tile)
	STA.B $00                        ; Update destination
	
	LDA.B $02                        ; Get source offset
	CLC
	ADC.W #$0020                     ; Add $20 (32 bytes per decompressed tile)
	STA.B $02                        ; Update source
	
	DEC.B $06                        ; Decrement loop counter
	BNE CODE_018216                  ; Continue loop
	
	PLP                              ; Restore processor status
	RTS                              ; Return

; ===========================================================================
; Decompress Single Battle Tile
; ===========================================================================
; Purpose: Decompress one tile using ExpandSecondHalfWithZeros algorithm
; Technical Details:
;   - Reads from Bank $04 (compressed graphics)
;   - Writes to Bank $7F WRAM (decompressed)
;   - Expands $10 bytes to $20 bytes by inserting zeros
; ===========================================================================

CODE_01822F:
	PHB                              ; Save data bank
	PHP                              ; Save processor status
	REP #$30                         ; 16-bit A,X,Y
	PHB                              ; Save data bank again
	
	; Calculate source address
	LDA.W $192B                      ; Get base offset from direct page
	CLC
	ADC.W #$CA20                     ; Add base address ($04CA20)
	TAX                              ; X = source address
	
	LDY.W $192D                      ; Y = destination offset
	LDA.W #$000F                     ; 16 bytes to copy
	MVN $7F,$04                      ; Copy from Bank $04 to $7F
	
	PLB                              ; Restore data bank
	
	; Process decompression (insert zeros in second half)
	TXA                              ; Get updated source address
	SEC
	SBC.W #$CA20                     ; Convert back to offset
	TAX                              ; X = offset
	
	SEP #$20                         ; 8-bit A
	REP #$10                         ; 16-bit X,Y
	
	PEA.W $007F                      ; Set data bank to $7F
	PLB                              ; Pull to B
	PLA                              ; Clean stack
	
	XBA                              ; Swap accumulator bytes
	LDA.B #$08                       ; 8 bytes to process
	STA.W $1933                      ; Store counter
	
CODE_01825B:
	; Decompression loop (ExpandSecondHalfWithZeros)
	; Reads compressed data and writes with zero padding
	
	LDA.L DATA8_04CA20,X             ; Read compressed byte from Bank $04
	INX                              ; Next source byte
	
	STA.W $0000,Y                    ; Write data byte
	INY                              ; Next destination
	
	LDA.B #$00                       ; Zero byte
	STA.W $0000,Y                    ; Write zero (expansion)
	INY                              ; Next destination
	
	DEC.W $1933                      ; Decrement counter
	BNE CODE_01825B                  ; Continue loop
	
	PLP                              ; Restore processor status
	PLB                              ; Restore data bank
	RTS                              ; Return

; ===========================================================================
; Battle Main Loop Entry Point
; ===========================================================================
; Purpose: Main battle processing loop
; Called every frame during battle
; ===========================================================================

CODE_018272:
	SEP #$20                         ; 8-bit A
	REP #$10                         ; 16-bit X,Y
	PHK                              ; Push program bank
	PLB                              ; Set as data bank
	
	; Initialize battle state
	LDX.W #$FFFF                     ; Invalid value
	STX.W $195F                      ; Clear target selection
	
	LDX.W #$8000                     ; Battle active flag
	STX.W $1A48                      ; Set battle in progress
	
	STZ.W $192A                      ; Clear battle phase
	
	JSR.W CODE_018C5B                ; Initialize enemy AI
	
	; Load enemy stats
	LDA.W $0E91                      ; Get enemy type
	STA.W $19F0                      ; Store current enemy
	
	LDX.W $0E89                      ; Get enemy stats pointer
	STX.W $19F1                      ; Store stats address
	
	; Set battle ready flag
	LDA.B #$80                       ; Battle ready bit
	STA.W $0110                      ; Set status flag
	
	JSR.W CODE_01914D                ; Update battle display
	
	; Check for specific enemy (ID $15)
	LDA.W $0E88                      ; Get enemy ID
	CMP.B #$15                       ; Compare to $15
	BNE CODE_0182A9                  ; If not, skip special handling
	
	JSL.L CODE_009A60                ; Special enemy initialization
	
CODE_0182A9:
	; Battle turn loop
	INC.W $19F7                      ; Increment turn counter
	STZ.W $19F8                      ; Clear turn phase
	
	JSR.W CODE_01E9B3                ; Process battle AI
	JSR.W CODE_0182F2                ; Execute battle command
	
	; Check for special battle mode
	LDA.W $19B0                      ; Get battle flags
	BEQ CODE_0182BE                  ; If clear, skip
	
	JSL.L CODE_01B24C                ; Special battle processing
	
CODE_0182BE:
	; Wait for turn completion
	LDA.W $19F8                      ; Get turn phase
	BNE CODE_0182A9                  ; If not zero, continue turn
	
	JSR.W CODE_01AB5D                ; Update actor states
	JSR.W CODE_01A081                ; Process status effects
	
CODE_0182C9:
	; Wait for VBlank
	LDA.W $19F7                      ; Get VBlank flag
	BNE CODE_0182C9                  ; Wait until zero
	
	BRA CODE_0182A9                  ; Next turn

;===============================================================================
; Progress: Bank $01 Initial Documentation
; Lines documented: ~450 / 15,480 (2.9%)
; Focus: Battle initialization, graphics loading, main loop
; Next: AI system, damage calculations, combat mechanics
;===============================================================================
