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
CODE_018222:
                       PHP                                  ;018222|08      |      ;
                       PHK                                  ;018223|4B      |      ;
                       PLB                                  ;018224|AB      |      ;
                       SEP #                             ;018225|E220    |      ;
                       REP #                             ;018227|C210    |      ;
                       STA.W                           ;018229|8D9A0A  |010A9A;
                       ASL A                                ;01822C|0A      |      ;
                       ASL A                                ;01822D|0A      |      ;
                       ASL A                                ;01822E|0A      |      ;
                       TAX                                  ;01822F|AA      |      ;
                       LDA.W DATA8_018242,X                 ;018230|BD4282  |018242;
                       STA.W                           ;018233|8D890A  |010A89;
                       LDA.W DATA8_018243,X                 ;018236|BD4382  |018243;
                       STA.W                           ;018239|8D8A0A  |010A8A;
                       LDA.W DATA8_018244,X                 ;01823C|BD4482  |018244;
                       STA.W                           ;01823F|8D950A  |010A95;
                       db ,,,,,,,,,,,,,,;018242|        |      ;
                                                            ;      |        |      ;
         DATA8_018242:
                       db ,,,,,,,,,,,,,,,;018251|        |      ;
                       db ,,,,,,,,,,,,,,,;018261|        |      ;
                       db ,,,,,,,,,,,,,,,;018271|        |      ;
                       db ,,,,,,,,,,,,,,,;018281|        |      ;
                       db ,,,,,,,,,,,,,,,;018291|        |      ;
                       db ,,,,,,,,,,,,,,,;0182A1|        |      ;
                       db ,,,,,,,,,,,,,,,;0182B1|        |      ;
                       db ,,,,,,,,,,,,,,,;0182C1|        |      ;
                       db ,,,,,,,,,,,,,,,;0182D1|        |      ;
                       db ,,,,,,,,,,,,,,,;0182E1|        |      ;
                       db ,,,,,,,,,,,,,,,;0182F1|        |      ;
                       db ,,,,,,,,,,,,,,,;018301|        |      ;
                       db ,,,,,,,,,,,,,,,;018311|        |      ;
                                                            ;      |        |      ;
          CODE_018321:
                       PHP                                  ;018321|08      |      ;
                       PHB                                  ;018322|8B      |      ;
                       PHK                                  ;018323|4B      |      ;
                       PLB                                  ;018324|AB      |      ;
                       SEP #                             ;018325|E220    |      ;
                       REP #                             ;018327|C210    |      ;
                       LDA.W                           ;018329|AD890A  |010A89;
                       STA.W                           ;01832C|8D3319  |011933;
                       LDA.W                           ;01832F|AD8A0A  |010A8A;
                       LSR A                                ;018332|4A      |      ;
                       TAY                                  ;018333|A8      |      ;
                       LSR A                                ;018334|4A      |      ;
                       LSR A                                ;018335|4A      |      ;
                       LSR A                                ;018336|4A      |      ;
                       STA.W                           ;018337|8D3219  |011932;
                       TYA                                  ;01833A|98      |      ;
                       AND.B #                           ;01833B|290F    |      ;
                       TAX                                  ;01833D|AA      |      ;
                       TAY                                  ;01833E|A8      |      ;
                       LDA.L DATA8_04CA20,X                 ;01833F|BF20CA04|04CA20;
                       INX                                  ;018343|E8      |      ;
                       STA.W ,Y                        ;018344|990000  |7F0000;
                       INY                                  ;018347|C8      |      ;
                       LDA.B #                           ;018348|A900    |      ;
                       STA.W ,Y                        ;01834A|990000  |7F0000;
                       INY                                  ;01834D|C8      |      ;
                       DEC.W                           ;01834E|CE3319  |7F1933;
                       BNE CODE_01825B                      ;018351|D0EC    |01825B;
                       PLP                                  ;018353|28      |      ;
                       PLB                                  ;018354|AB      |      ;
                       RTS                                  ;018355|60      |      ;
          CODE_018272:
                       SEP #                             ;018272|E220    |      ;
                       REP #                             ;018274|C210    |      ;
                       PHK                                  ;018276|4B      |      ;
                       PLB                                  ;018277|AB      |      ;
                       LDX.W #                         ;018278|A2FFFF  |      ;
                       STX.W                           ;01827B|8E5F19  |01195F;
                       LDX.W #                         ;01827E|A20080  |      ;
                       STX.W                           ;018281|8E481A  |011A48;
                       STZ.W                           ;018284|9C2A19  |01192A;
                       JSR.W CODE_018C5B                    ;018287|205B8C  |018C5B;
                       LDA.W                           ;01828A|AD910E  |010E91;
                       STA.W                           ;01828D|8DF019  |0119F0;
                       LDX.W                           ;018290|AE890E  |010E89;
                       STX.W                           ;018293|8EF119  |0119F1;
                       LDA.B #                           ;018296|A980    |      ;
                       STA.W                           ;018298|8D1001  |010110;
                       JSR.W CODE_01914D                    ;01829B|204D91  |01914D;
                       LDA.W                           ;01829E|AD880E  |000E88;
                       CMP.B #                           ;0182A1|C915    |      ;
                       BNE CODE_0182A9                      ;0182A3|D004    |0182A9;
                       JSL.L CODE_009A60                    ;0182A5|22609A00|009A60;
                                                            ;      |        |      ;
          CODE_0182A9:
                       INC.W                           ;0182A9|EEF719  |0119F7;
                       STZ.W                           ;0182AC|9CF819  |0119F8;
                       JSR.W CODE_01E9B3                    ;0182AF|20B3E9  |01E9B3;
                       JSR.W CODE_0182F2                    ;0182B2|20F282  |0182F2;
                       LDA.W                           ;0182B5|ADB019  |0119B0;
                       BEQ CODE_0182BE                      ;0182B8|F004    |0182BE;
                       JSL.L CODE_01B24C                    ;0182BA|224CB201|01B24C;
                                                            ;      |        |      ;
          CODE_0182BE:
                       LDA.W                           ;0182BE|ADF819  |0119F8;
                       BNE CODE_0182A9                      ;0182C1|D0E6    |0182A9;
                       JSR.W CODE_01AB5D                    ;0182C3|205DAB  |01AB5D;
                       JSR.W CODE_01A081                    ;0182C6|2081A0  |01A081;
                                                            ;      |        |      ;
          CODE_0182C9:
                       LDA.W                           ;0182C9|ADF719  |0119F7;
                       BNE CODE_0182C9                      ;0182CC|D0FB    |0182C9;
                       BRA CODE_0182A9                      ;0182CE|80D9    |0182A9;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0182D0:
                       PHP                                  ;0182D0|08      |      ;
                       PHX                                  ;0182D1|DA      |      ;
                       PHY                                  ;0182D2|5A      |      ;
                       SEP #                             ;0182D3|E220    |      ;
                       REP #                             ;0182D5|C210    |      ;
                       BRA CODE_0182E3                      ;0182D7|800A    |0182E3;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0182D9:
                       PHP                                  ;0182D9|08      |      ;
                       PHX                                  ;0182DA|DA      |      ;
                       PHY                                  ;0182DB|5A      |      ;
                       SEP #                             ;0182DC|E220    |      ;
                       REP #                             ;0182DE|C210    |      ;
                       JSR.W CODE_01AB5D                    ;0182E0|205DAB  |01AB5D;
                                                            ;      |        |      ;
          CODE_0182E3:
                       JSR.W CODE_01A081                    ;0182E3|2081A0  |01A081;
                                                            ;      |        |      ;
          CODE_0182E6:
                       LDA.W                           ;0182E6|ADF719  |0019F7;
                       BNE CODE_0182E6                      ;0182E9|D0FB    |0182E6;
                       INC.W                           ;0182EB|EEF719  |0019F7;
                       PLY                                  ;0182EE|7A      |      ;
                       PLX                                  ;0182EF|FA      |      ;
                       PLP                                  ;0182F0|28      |      ;
                       RTS                                  ;0182F1|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0182F2:
                       REP #                             ;0182F2|C220    |      ;
                       AND.W #                         ;0182F4|29FF00  |      ;
                       ASL A                                ;0182F7|0A      |      ;
                       TAX                                  ;0182F8|AA      |      ;
                       SEP #                             ;0182F9|E220    |      ;
                       JMP.W (DATA8_0182FE,X)               ;0182FB|7CFE82  |0182FE;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
         DATA8_0182FE:
                       db ,,,,,,,,,,,,,,,;0182FE|        |      ;
                       db ,,,,,,,,,,,,,,,;01830E|        |      ;
                       db ,                           ;01831E|        |      ;
                       SEP #                             ;018320|E220    |      ;
                       REP #                             ;018322|C210    |      ;
                       PHB                                  ;018324|8B      |      ;
                       LDA.W                           ;018325|ADA519  |0019A5;
                       BNE CODE_01832D                      ;018328|D003    |01832D;
                       JSR.W CODE_018A2D                    ;01832A|202D8A  |018A2D;
                                                            ;      |        |      ;
          CODE_01832D:
                       PLB                                  ;01832D|AB      |      ;
                       RTL                                  ;01832E|6B      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
         DATA8_01832F:
                       db                                ;01832F|        |      ;
                                                            ;      |        |      ;
         DATA8_018330:
                       db ,,,,,,       ;018330|        |      ;
                       PHP                                  ;018337|08      |      ;
                       PHB                                  ;018338|8B      |      ;
                       PHK                                  ;018339|4B      |      ;
                       PLB                                  ;01833A|AB      |      ;
                       SEP #                             ;01833B|E220    |      ;
                       REP #                             ;01833D|C210    |      ;
                       LDA.W                           ;01833F|ADA519  |0119A5;
                       BMI CODE_018358                      ;018342|3014    |018358;
                       JSR.W CODE_018E07                    ;018344|20078E  |018E07;
                       JSR.W CODE_01973A                    ;018347|203A97  |01973A;
                       LDA.B #                           ;01834A|A900    |      ;
                       XBA                                  ;01834C|EB      |      ;
                       LDA.W                           ;01834D|AD461A  |011A46;
                       ASL A                                ;018350|0A      |      ;
                       TAX                                  ;018351|AA      |      ;
                       JSR.W (DATA8_01835B,X)               ;018352|FC5B83  |01835B;
                       STZ.W                           ;018355|9C461A  |011A46;
                                                            ;      |        |      ;
          CODE_018358:
                       PLB                                  ;018358|AB      |      ;
                       PLP                                  ;018359|28      |      ;
                       RTL                                  ;01835A|6B      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
         DATA8_01835B:
                       db ,,,,,,,,,,,,,,,;01835B|        |      ;
                       db ,                           ;01836B|        |      ;
                                                            ;      |        |      ;
          CODE_01836D:
                       LDX.W #                         ;01836D|A20000  |      ;
                       TXA                                  ;018370|8A      |      ;
                       XBA                                  ;018371|EB      |      ;
                                                            ;      |        |      ;
          CODE_018372:
                       LDA.W DATA8_01839F,X                 ;018372|BD9F83  |01839F;
                       STA.W                           ;018375|8D2121  |012121;
                       LDY.W #                         ;018378|A00022  |      ;
                       STY.W                           ;01837B|8C0043  |014300;
                       LDY.W DATA8_0183A0,X                 ;01837E|BCA083  |0183A0;
                       STY.W                           ;018381|8C0243  |014302;
                       LDA.B #                           ;018384|A97F    |      ;
                       STA.W                           ;018386|8D0443  |014304;
                       LDA.W DATA8_0183A2,X                 ;018389|BDA283  |0183A2;
                       TAY                                  ;01838C|A8      |      ;
                       STY.W                           ;01838D|8C0543  |014305;
                       LDA.B #                           ;018390|A901    |      ;
                       STA.W                           ;018392|8D0B42  |01420B;
                       INX                                  ;018395|E8      |      ;
                       INX                                  ;018396|E8      |      ;
                       INX                                  ;018397|E8      |      ;
                       INX                                  ;018398|E8      |      ;
                       CPX.W #                         ;018399|E02000  |      ;
                       BNE CODE_018372                      ;01839C|D0D4    |018372;
                       RTS                                  ;01839E|60      |      ;
                                                            ;      |        |      ;
         DATA8_01839F:
                       db                                ;01839F|        |      ;
                                                            ;      |        |      ;
         DATA8_0183A0:
                       db ,                           ;0183A0|        |      ;
                                                            ;      |        |      ;
         DATA8_0183A2:
                       db ,,,,,,,,,,,,,,,;0183A2|        |      ;
                       db ,,,,,,,,,,,,;0183B2|        |      ;
                                                            ;      |        |      ;
          CODE_0183BF:
                       JSR.W CODE_0183CC                    ;0183BF|20CC83  |0183CC;
                       LDA.W                           ;0183C2|AD4C1A  |011A4C;
                       DEC A                                ;0183C5|3A      |      ;
                       BNE CODE_0183CB                      ;0183C6|D003    |0183CB;
                       JSR.W CODE_018401                    ;0183C8|200184  |018401;
                                                            ;      |        |      ;
          CODE_0183CB:
                       RTS                                  ;0183CB|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0183CC:
                       LDX.W #                         ;0183CC|A20000  |      ;
                                                            ;      |        |      ;
          CODE_0183CF:
                       LDY.W ,X                        ;0183CF|BC0B1A  |011A0B;
                       BEQ CODE_018400                      ;0183D2|F02C    |018400;
                       STY.W                           ;0183D4|8C0543  |014305;
                       LDY.W #                         ;0183D7|A00118  |      ;
                       STY.W                           ;0183DA|8C0043  |014300;
                       LDY.W ,X                        ;0183DD|BC031A  |011A03;
                       STY.W                           ;0183E0|8C0243  |014302;
                       LDA.B #                           ;0183E3|A900    |      ;
                       STA.W                           ;0183E5|8D0443  |014304;
                       LDY.W ,X                        ;0183E8|BCFB19  |0119FB;
                       STY.W                           ;0183EB|8C1621  |012116;
                       LDA.W                           ;0183EE|ADFA19  |0119FA;
                       STA.W                           ;0183F1|8D1521  |012115;
                       LDA.B #                           ;0183F4|A901    |      ;
                       STA.W                           ;0183F6|8D0B42  |01420B;
                       INX                                  ;0183F9|E8      |      ;
                       INX                                  ;0183FA|E8      |      ;
                       CPX.W #                         ;0183FB|E00800  |      ;
                       BNE CODE_0183CF                      ;0183FE|D0CF    |0183CF;
                                                            ;      |        |      ;
          CODE_018400:
                       RTS                                  ;018400|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_018401:
                       LDX.W #                         ;018401|A20000  |      ;
                                                            ;      |        |      ;
          CODE_018404:
                       LDY.W ,X                        ;018404|BC241A  |011A24;
                       BEQ CODE_018435                      ;018407|F02C    |018435;
                       STY.W                           ;018409|8C0543  |014305;
                       LDY.W #                         ;01840C|A00118  |      ;
                       STY.W                           ;01840F|8C0043  |014300;
                       LDY.W ,X                        ;018412|BC1C1A  |011A1C;
                       STY.W                           ;018415|8C0243  |014302;
                       LDA.B #                           ;018418|A900    |      ;
                       STA.W                           ;01841A|8D0443  |014304;
                       LDY.W ,X                        ;01841D|BC141A  |011A14;
                       STY.W                           ;018420|8C1621  |012116;
                       LDA.W                           ;018423|AD131A  |011A13;
                       STA.W                           ;018426|8D1521  |012115;
                       LDA.B #                           ;018429|A901    |      ;
                       STA.W                           ;01842B|8D0B42  |01420B;
                       INX                                  ;01842E|E8      |      ;
                       INX                                  ;01842F|E8      |      ;
                       CPX.W #                         ;018430|E00800  |      ;
                       BNE CODE_018404                      ;018433|D0CF    |018404;
                                                            ;      |        |      ;
          CODE_018435:
                       RTS                                  ;018435|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_018436:
                       LDX.W #                         ;018436|A20000  |      ;
                       STX.W                           ;018439|8E1621  |012116;
                       LDA.B #                           ;01843C|A980    |      ;
                       STA.W                           ;01843E|8D1521  |012115;
                       LDX.W #                         ;018441|A20118  |      ;
                       STX.W                           ;018444|8E0043  |014300;
                       LDX.W #                         ;018447|A274D2  |      ;
                       STX.W                           ;01844A|8E0243  |014302;
                       LDA.B #                           ;01844D|A97F    |      ;
                       STA.W                           ;01844F|8D0443  |014304;
                       LDX.W #                         ;018452|A20020  |      ;
                       STX.W                           ;018455|8E0543  |014305;
                       LDA.B #                           ;018458|A901    |      ;
                       STA.W                           ;01845A|8D0B42  |01420B;
                       RTS                                  ;01845D|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_01845E:
                       LDX.W #                         ;01845E|A288C5  |      ;
                       LDA.B #                           ;018461|A900    |      ;
                                                            ;      |        |      ;
          CODE_018463:
                       PHA                                  ;018463|48      |      ;
                       STA.W                           ;018464|8D2121  |012121;
                       LDY.W #                         ;018467|A00022  |      ;
                       STY.W                           ;01846A|8C0043  |014300;
                       STX.W                           ;01846D|8E0243  |014302;
                       LDA.B #                           ;018470|A97F    |      ;
                       STA.W                           ;018472|8D0443  |014304;
                       LDY.W #                         ;018475|A01000  |      ;
                       STY.W                           ;018478|8C0543  |014305;
                       LDA.B #                           ;01847B|A901    |      ;
                       STA.W                           ;01847D|8D0B42  |01420B;
                       REP #                             ;018480|C220    |      ;
                       TXA                                  ;018482|8A      |      ;
                       CLC                                  ;018483|18      |      ;
                       ADC.W #                         ;018484|691000  |      ;
                       TAX                                  ;018487|AA      |      ;
                       SEP #                             ;018488|E220    |      ;
                       PLA                                  ;01848A|68      |      ;
                       CLC                                  ;01848B|18      |      ;
                       ADC.B #                           ;01848C|6910    |      ;
                       CMP.B #                           ;01848E|C980    |      ;
                       BNE CODE_018463                      ;018490|D0D1    |018463;
                       RTS                                  ;018492|60      |      ;
                                                            ;      |        |      ;
          CODE_018493:
                       LDX.W #                         ;018493|A20069  |      ;
                       STX.W                           ;018496|8E1621  |012116;
                       LDA.B #                           ;018499|A980    |      ;
                       STA.W                           ;01849B|8D1521  |012115;
                       LDX.W #                         ;01849E|A20118  |      ;
                       STX.W                           ;0184A1|8E0043  |014300;
                       STZ.W                           ;0184A4|9C0243  |014302;
                       LDX.W #                         ;0184A7|A2007F  |      ;
                       STX.W                           ;0184AA|8E0343  |014303;
                       LDX.W #                         ;0184AD|A2002E  |      ;
                       STX.W                           ;0184B0|8E0543  |014305;
                       LDA.B #                           ;0184B3|A901    |      ;
                       STA.W                           ;0184B5|8D0B42  |01420B;
                       RTS                                  ;0184B8|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0184B9:
                       LDX.W #                         ;0184B9|A20061  |      ;
                       STX.W                           ;0184BC|8E1621  |012116;
                       LDA.B #                           ;0184BF|A980    |      ;
                       STA.W                           ;0184C1|8D1521  |012115;
                       LDX.W #                         ;0184C4|A20118  |      ;
                       STX.W                           ;0184C7|8E0043  |014300;
                       LDX.W #                         ;0184CA|A20040  |      ;
                       STX.W                           ;0184CD|8E0243  |014302;
                       LDA.B #                           ;0184D0|A97F    |      ;
                       STA.W                           ;0184D2|8D0443  |014304;
                       LDX.W #                         ;0184D5|A2000C  |      ;
                       STX.W                           ;0184D8|8E0543  |014305;
                       LDA.B #                           ;0184DB|A901    |      ;
                       STA.W                           ;0184DD|8D0B42  |01420B;
                       RTS                                  ;0184E0|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_0184E1:
                       LDX.W #                         ;0184E1|A22000  |      ;
                       STX.W                           ;0184E4|8E0221  |012102;
                       LDX.W #                         ;0184E7|A20004  |      ;
                       STX.W                           ;0184EA|8E0043  |014300;
                       LDX.W #                         ;0184ED|A2400C  |      ;
                       STX.W                           ;0184F0|8E0243  |014302;
                       STZ.W                           ;0184F3|9C0443  |014304;
                       LDX.W #                         ;0184F6|A2C001  |      ;
                       STX.W                           ;0184F9|8E0543  |014305;
                       LDA.B #                           ;0184FC|A901    |      ;
                       STA.W                           ;0184FE|8D0B42  |01420B;
                       LDX.W #                         ;018501|A20201  |      ;
                       STX.W                           ;018504|8E0221  |012102;
                       LDX.W #                         ;018507|A20004  |      ;
                       STX.W                           ;01850A|8E0043  |014300;
                       LDX.W #                         ;01850D|A2040E  |      ;
                       STX.W                           ;018510|8E0243  |014302;
                       STZ.W                           ;018513|9C0443  |014304;
                       LDX.W #                         ;018516|A21C00  |      ;
                       STX.W                           ;018519|8E0543  |014305;
                       LDA.B #                           ;01851C|A901    |      ;
                       STA.W                           ;01851E|8D0B42  |01420B;
                       RTS                                  ;018521|60      |      ;
                                                            ;      |        |      ;
                       JSR.W CODE_01836D                    ;018522|206D83  |01836D;
                       JMP.W CODE_01845E                    ;018525|4C5E84  |01845E;
                                                            ;      |        |      ;
                       PHP                                  ;018528|08      |      ;
                       PHB                                  ;018529|8B      |      ;
                       PHK                                  ;01852A|4B      |      ;
                       PLB                                  ;01852B|AB      |      ;
                       REP #                             ;01852C|C230    |      ;
                       INC.W                           ;01852E|EEA619  |0119A6;
                       SEP #                             ;018531|E220    |      ;
                       STZ.W                           ;018533|9CF719  |0119F7;
                       LDA.W                           ;018536|ADA519  |0119A5;
                       INC A                                ;018539|1A      |      ;
                       BEQ CODE_018554                      ;01853A|F018    |018554;
                       BMI CODE_018547                      ;01853C|3009    |018547;
                       JSR.W CODE_018673                    ;01853E|207386  |018673;
                       LDX.W                           ;018541|AE481A  |011A48;
                       STX.W                           ;018544|8E0221  |012102;
                                                            ;      |        |      ;
          CODE_018547:
                       LDA.B #                           ;018547|A900    |      ;
                       XBA                                  ;018549|EB      |      ;
                       LDA.W                           ;01854A|AD451A  |011A45;
                       AND.B #                           ;01854D|2903    |      ;
                       ASL A                                ;01854F|0A      |      ;
                       TAX                                  ;018550|AA      |      ;
                       JSR.W (DATA8_018557,X)               ;018551|FC5785  |018557;
                                                            ;      |        |      ;
          CODE_018554:
                       PLB                                  ;018554|AB      |      ;
                       PLP                                  ;018555|28      |      ;
                       RTL                                  ;018556|6B      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
         DATA8_018557:
                       db ,,,,,,,   ;018557|        |      ;
                       LDA.W                           ;01855F|AD1001  |010110;
                       BPL CODE_018568                      ;018562|1004    |018568;
                       STZ.W                           ;018564|9C451A  |011A45;
                       RTS                                  ;018567|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;
          CODE_018568:
                       LDX.W #                         ;018568|A20001  |      ;
                       STX.W                           ;01856B|8E0D08  |01080D;
                       LDX.W #                         ;01856E|A20004  |      ;
                       STX.W                           ;018571|8E0F08  |01080F;
                       LDA.B #                           ;018574|A980    |      ;
                       STA.W                           ;018576|8D1108  |010811;
                       BRA CODE_01858C                      ;018579|8011    |01858C;
                                                            ;      |        |      ;
                       LDX.W #                         ;01857B|A2C87A  |      ;
                       STX.W                           ;01857E|8E0D08  |01080D;
                       LDX.W #                         ;018581|A2A8F9  |      ;
                       STX.W                           ;018584|8E0F08  |01080F;
                       LDA.B #                           ;018587|A90F    |      ;
                       STA.W                           ;018589|8D1108  |010811;
                                                            ;      |        |      ;
          CODE_01858C:
                       LDX.W #                         ;01858C|A20000  |      ;
                       STX.W                           ;01858F|8E2A21  |01212A;
                       STZ.W                           ;018592|9C2E21  |01212E;
                       STZ.W                           ;018595|9C2F21  |01212F;
                       LDA.B #                           ;018598|A9FF    |      ;
                       STZ.W                           ;01859A|9C2621  |012126;
                       STA.W                           ;01859D|8D2721  |012127;
                       STZ.W                           ;0185A0|9C2821  |012128;
                       STA.W                           ;0185A3|8D2921  |012129;
                       LDA.B #                           ;0185A6|A922    |      ;
                       STA.W                           ;0185A8|8D2321  |012123;
                       STA.W                           ;0185AB|8D2421  |012124;
                       STA.W                           ;0185AE|8D2521  |012125;
                       LDA.W                           ;0185B1|AD501A  |011A50;
                       AND.B #                           ;0185B4|290F    |      ;
                       ORA.B #                           ;0185B6|0950    |      ;
                       STA.W                           ;0185B8|8D3021  |012130;
                       LDA.B #                           ;0185BB|A981    |      ;
                       STA.W                           ;0185BD|8D0908  |010809;
                       LDA.B #                           ;0185C0|A9FF    |      ;
                       STA.W                           ;0185C2|8D0108  |010801;
                       STZ.W                           ;0185C5|9C0208  |010802;
                       STA.W                           ;0185C8|8D0A08  |01080A;
                       STZ.W                           ;0185CB|9C0B08  |01080B;
                       STZ.W                           ;0185CE|9C0C08  |01080C;
                       DEC A                                ;0185D1|3A      |      ;
                       STA.W                           ;0185D2|8D0008  |010800;
                       LDA.B #                           ;0185D5|A903    |      ;
                       STA.W                           ;0185D7|8D451A  |011A45;
                       RTS                                  ;0185DA|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 1)
; Advanced Battle Animation and Sprite Management Systems
; ==============================================================================

; ==============================================================================
; Advanced Sprite Position Calculation with Screen Clipping
; Complex sprite coordinate processing with boundary checks and multi-sprite handling
; ==============================================================================

CODE_01A0E5:
                       SEC                                  ;01A0E5|38      |      ;
                       SBC.B $00                          ;01A0E6|E500    |001A62;
                       AND.W #$03FF                       ;01A0E8|29FF03  |      ;
                       STA.B $23,X                        ;01A0EB|9523    |001A85;
                       LDA.B $25,X                        ;01A0ED|B525    |001A87;
                       SEC                                  ;01A0EF|38      |      ;
                       SBC.B $02                          ;01A0F0|E502    |001A64;
                       AND.W #$03FF                       ;01A0F2|29FF03  |      ;
                       STA.B $25,X                        ;01A0F5|9525    |001A87;
                       SEP #$20                           ;01A0F7|E220    |      ;
                       LDA.B $1E,X                        ;01A0F9|B51E    |001A80;
                       EOR.W $19B4                        ;01A0FB|4DB419  |0119B4;
                       BIT.B #$08                         ;01A0FE|8908    |      ;
                       BEQ CODE_01A105                     ;01A100|F003    |01A105;
                       JMP.W CODE_01A186                   ;01A102|4C86A1  |01A186;

CODE_01A105:
                       LDA.B #$00                         ;01A105|A900    |      ;
                       XBA                                 ;01A107|EB      |      ;
                       LDA.B $19,X                        ;01A108|B519    |001A7B;
                       BPL CODE_01A10F                     ;01A10A|1003    |01A10F;
                       db $EB,$3A,$EB                   ;01A10C|        |      ;

CODE_01A10F:
                       REP #$20                           ;01A10F|C220    |      ;
                       CLC                                 ;01A111|18      |      ;
                       ADC.B $23,X                        ;01A112|7523    |001A85;
                       STA.B $0A                          ;01A114|850A    |001A6C;
                       LDA.W #$0000                       ;01A116|A90000  |      ;
                       SEP #$20                           ;01A119|E220    |      ;
                       LDA.B $1A,X                        ;01A11B|B51A    |001A7C;
                       BPL CODE_01A122                     ;01A11D|1003    |01A122;
                       db $EB,$3A,$EB                   ;01A11F|        |      ;

CODE_01A122:
                       REP #$20                           ;01A122|C220    |      ;
                       CLC                                 ;01A124|18      |      ;
                       ADC.B $25,X                        ;01A125|7525    |001A87;
                       STA.B $0C                          ;01A127|850C    |001A6E;
                       REP #$20                           ;01A129|C220    |      ;
                       LDX.B $04                          ;01A12B|A604    |001A66;
                       LDY.W DATA8_01A63C,X                ;01A12D|BC3CA6  |01A63C;
                       LDA.W DATA8_01A63A,X                ;01A130|BD3AA6  |01A63A;
                       TAX                                 ;01A133|AA      |      ;
                       LDA.B $0C                          ;01A134|A50C    |001A6E;
                       CMP.W #$00E8                       ;01A136|C9E800  |      ;
                       BCC CODE_01A140                     ;01A139|9005    |01A140;
                       CMP.W #$03F8                       ;01A13B|C9F803  |      ;
                       BCC CODE_01A191                     ;01A13E|9051    |01A191;

; ==============================================================================
; Multi-Sprite OAM Setup with Complex Boundary Testing
; Handles 4-sprite large character display with screen clipping and priority
; ==============================================================================

CODE_01A140:
                       LDA.B $0A                          ;01A140|A50A    |001A6C;
                       CMP.W #$00F8                       ;01A142|C9F800  |      ;
                       BCC CODE_01A15E                     ;01A145|9017    |01A15E;
                       CMP.W #$0100                       ;01A147|C90001  |      ;
                       BCC CODE_01A1A8                     ;01A14A|905C    |01A1A8;
                       CMP.W #$03F0                       ;01A14C|C9F003  |      ;
                       BCC CODE_01A191                     ;01A14F|9040    |01A191;
                       CMP.W #$03F8                       ;01A151|C9F803  |      ;
                       BCC CODE_01A1D3                     ;01A154|907D    |01A1D3;
                       CMP.W #$0400                       ;01A156|C90004  |      ;
                       BCS CODE_01A15E                     ;01A159|B003    |01A15E;
                       JMP.W CODE_01A1FF                   ;01A15B|4CFFA1  |01A1FF;

; ==============================================================================
; Standard 4-Sprite OAM Configuration
; Sets up normal sprite display with 16x16 tile arrangement
; ==============================================================================

CODE_01A15E:
                       SEP #$20                           ;01A15E|E220    |      ;
                       STA.W $0C00,X                      ;01A160|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A163|9D080C  |010C08;
                       CLC                                 ;01A166|18      |      ;
                       ADC.B #$08                         ;01A167|6908    |      ;
                       STA.W $0C04,X                      ;01A169|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A16C|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A16F|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A171|9D010C  |010C01;
                       STA.W $0C05,X                      ;01A174|9D050C  |010C05;
                       CLC                                 ;01A177|18      |      ;
                       ADC.B #$08                         ;01A178|6908    |      ;
                       STA.W $0C09,X                      ;01A17A|9D090C  |010C09;
                       STA.W $0C0D,X                      ;01A17D|9D0D0C  |010C0D;
                       LDA.B #$00                         ;01A180|A900    |      ;
                       STA.W $0C00,Y                      ;01A182|99000C  |010C00;
                       RTS                                 ;01A185|60      |      ;

; ==============================================================================
; Off-Screen Sprite Handling
; Hides sprites that are completely outside visible screen area
; ==============================================================================

CODE_01A186:
                       REP #$20                           ;01A186|C220    |      ;
                       LDX.B $04                          ;01A188|A604    |001A66;
                       LDY.W DATA8_01A63C,X                ;01A18A|BC3CA6  |01A63C;
                       LDA.W DATA8_01A63A,X                ;01A18D|BD3AA6  |01A63A;
                       TAX                                 ;01A190|AA      |      ;

CODE_01A191:
                       LDA.W #$E080                       ;01A191|A980E0  |      ;
                       STA.W $0C00,X                      ;01A194|9D000C  |010C00;
                       STA.W $0C04,X                      ;01A197|9D040C  |010C04;
                       STA.W $0C08,X                      ;01A19A|9D080C  |010C08;
                       STA.W $0C0C,X                      ;01A19D|9D0C0C  |010C0C;
                       SEP #$20                           ;01A1A0|E220    |      ;
                       LDA.B #$55                         ;01A1A2|A955    |      ;
                       STA.W $0C00,Y                      ;01A1A4|99000C  |010C00;
                       RTS                                 ;01A1A7|60      |      ;

; ==============================================================================
; Right Edge Clipping Configuration
; Handles sprites partially visible on right edge of screen
; ==============================================================================

CODE_01A1A8:
                       SEP #$20                           ;01A1A8|E220    |      ;
                       STA.W $0C00,X                      ;01A1AA|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A1AD|9D080C  |010C08;
                       LDA.B #$80                         ;01A1B0|A980    |      ;
                       STA.W $0C04,X                      ;01A1B2|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A1B5|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A1B8|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A1BA|9D010C  |010C01;
                       CLC                                 ;01A1BD|18      |      ;
                       ADC.B #$08                         ;01A1BE|6908    |      ;
                       STA.W $0C09,X                      ;01A1C0|9D090C  |010C09;
                       LDA.B #$E0                         ;01A1C3|A9E0    |      ;
                       STA.W $0C05,X                      ;01A1C5|9D050C  |010C05;
                       STA.W $0C0D,X                      ;01A1C8|9D0D0C  |010C0D;
                       SEP #$20                           ;01A1CB|E220    |      ;
                       LDA.B #$44                         ;01A1CD|A944    |      ;
                       STA.W $0C00,Y                      ;01A1CF|99000C  |010C00;
                       RTS                                 ;01A1D2|60      |      ;

; ==============================================================================
; Left Edge Clipping Configuration
; Handles sprites partially visible on left edge of screen
; ==============================================================================

CODE_01A1D3:
                       SEP #$20                           ;01A1D3|E220    |      ;
                       CLC                                 ;01A1D5|18      |      ;
                       ADC.B #$08                         ;01A1D6|6908    |      ;
                       STA.W $0C04,X                      ;01A1D8|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A1DB|9D0C0C  |010C0C;
                       LDA.B #$80                         ;01A1DE|A980    |      ;
                       STA.W $0C00,X                      ;01A1E0|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A1E3|9D080C  |010C08;
                       LDA.B $0C                          ;01A1E6|A50C    |001A6E;
                       STA.W $0C05,X                      ;01A1E8|9D050C  |010C05;
                       CLC                                 ;01A1EB|18      |      ;
                       ADC.B #$08                         ;01A1EC|6908    |      ;
                       STA.W $0C0D,X                      ;01A1EE|9D0D0C  |010C0D;
                       LDA.B #$E0                         ;01A1F1|A9E0    |      ;
                       STA.W $0C01,X                      ;01A1F3|9D010C  |010C01;
                       STA.W $0C09,X                      ;01A1F6|9D090C  |010C09;
                       LDA.B #$55                         ;01A1F9|A955    |      ;
                       STA.W $0C00,Y                      ;01A1FB|99000C  |010C00;
                       RTS                                 ;01A1FE|60      |      ;

; ==============================================================================
; Full Visibility Sprite Setup (Screen Wrap)
; Handles sprites fully visible including wraparound positioning
; ==============================================================================

CODE_01A1FF:
                       SEP #$20                           ;01A1FF|E220    |      ;
                       STA.W $0C00,X                      ;01A201|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A204|9D080C  |010C08;
                       CLC                                 ;01A207|18      |      ;
                       ADC.B #$08                         ;01A208|6908    |      ;
                       STA.W $0C04,X                      ;01A20A|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A20D|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A210|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A212|9D010C  |010C01;
                       STA.W $0C05,X                      ;01A215|9D050C  |010C05;
                       CLC                                 ;01A218|18      |      ;
                       ADC.B #$08                         ;01A219|6908    |      ;
                       STA.W $0C09,X                      ;01A21B|9D090C  |010C09;
                       STA.W $0C0D,X                      ;01A21E|9D0D0C  |010C0D;
                       LDA.B #$11                         ;01A221|A911    |      ;
                       STA.W $0C00,Y                      ;01A223|99000C  |010C00;
                       RTS                                 ;01A226|60      |      ;

; ==============================================================================
; Sound Effect System Initialization
; Complex audio channel management with battle sound coordination
; ==============================================================================

CODE_01A227:
                       PHP                                 ;01A227|08      |      ;
                       SEP #$20                           ;01A228|E220    |      ;
                       REP #$10                           ;01A22A|C210    |      ;
                       LDX.W #$FFFF                       ;01A22C|A2FFFF  |      ;
                       STX.W $19DE                        ;01A22F|8EDE19  |0119DE;
                       STX.W $19E0                        ;01A232|8EE019  |0119E0;
                       LDA.W $1914                        ;01A235|AD1419  |011914;
                       BIT.B #$20                         ;01A238|8920    |      ;
                       BEQ CODE_01A267                     ;01A23A|F02B    |01A267;
                       LDA.B #$00                         ;01A23C|A900    |      ;
                       XBA                                 ;01A23E|EB      |      ;
                       LDA.W $1913                        ;01A23F|AD1319  |011913;
                       AND.B #$0F                         ;01A242|290F    |      ;
                       ASL A                               ;01A244|0A      |      ;
                       TAX                                 ;01A245|AA      |      ;
                       LDA.L UNREACH_0CD666,X              ;01A246|BF66D60C|0CD666;
                       PHX                                 ;01A24A|DA      |      ;
                       ASL A                               ;01A24B|0A      |      ;
                       TAX                                 ;01A24C|AA      |      ;
                       REP #$30                           ;01A24D|C230    |      ;
                       LDA.L DATA8_0CD686,X                ;01A24F|BF86D60C|0CD686;
                       STA.W $19DE                        ;01A253|8DDE19  |0119DE;
                       PLX                                 ;01A256|FA      |      ;
                       LDA.L UNREACH_0CD667,X              ;01A257|BF67D60C|0CD667;
                       AND.W #$000F                       ;01A25B|290F00  |      ;
                       ASL A                               ;01A25E|0A      |      ;
                       TAX                                 ;01A25F|AA      |      ;
                       LDA.L DATA8_0CD727,X                ;01A260|BF27D70C|0CD727;
                       STA.W $19E0                        ;01A264|8DE019  |0119E0;

; ==============================================================================
; Sound Channel Buffer Initialization
; Clears all audio memory buffers for battle sound effects
; ==============================================================================

CODE_01A267:
                       REP #$30                           ;01A267|C230    |      ;
                       LDA.W #$0000                       ;01A269|A90000  |      ;
                       STA.L $7FCED8                      ;01A26C|8FD8CE7F|7FCED8;
                       STA.L $7FCEDA                      ;01A270|8FDACE7F|7FCEDA;
                       STA.L $7FCEDC                      ;01A274|8FDCCE7F|7FCEDC;
                       STA.L $7FCEDE                      ;01A278|8FDECE7F|7FCEDE;
                       STA.L $7FCEE0                      ;01A27C|8FE0CE7F|7FCEE0;
                       STA.L $7FCEE2                      ;01A280|8FE2CE7F|7FCEE2;
                       STA.L $7FCEE4                      ;01A284|8FE4CE7F|7FCEE4;
                       STA.L $7FCEE6                      ;01A288|8FE6CE7F|7FCEE6;
                       STA.L $7FCEE8                      ;01A28C|8FE8CE7F|7FCEE8;
                       STA.L $7FCEEA                      ;01A290|8FEACE7F|7FCEEA;
                       STA.L $7FCEEC                      ;01A294|8FECCE7F|7FCEEC;
                       STA.L $7FCEEE                      ;01A298|8FEECE7F|7FCEEE;
                       STA.L $7FCEF0                      ;01A29C|8FF0CE7F|7FCEF0;
                       STA.L $7FCEF2                      ;01A2A0|8FF2CE7F|7FCEF2;
                       PLP                                 ;01A2A4|28      |      ;
                       RTS                                 ;01A2A5|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 2)
; Advanced Sound Effect Processing and Graphics Animation
; ==============================================================================

; ==============================================================================
; Primary Sound Effect Processing System
; Complex sound channel management with battle coordination and timing
; ==============================================================================

CODE_01A2A6:
                       PHB                                 ;01A2A6|8B      |      ;
                       PHP                                 ;01A2A7|08      |      ;
                       PHD                                 ;01A2A8|0B      |      ;
                       SEP #$20                           ;01A2A9|E220    |      ;
                       REP #$10                           ;01A2AB|C210    |      ;
                       LDA.W $19DF                        ;01A2AD|ADDF19  |0119DF;
                       CMP.B #$FF                         ;01A2B0|C9FF    |      ;
                       BEQ CODE_01A2C9                     ;01A2B2|F015    |01A2C9;
                       PEA.W $1CD7                        ;01A2B4|F4D71C  |011CD7;
                       PLD                                 ;01A2B7|2B      |      ;
                       LDY.W #$0007                       ;01A2B8|A00700  |      ;
                       STY.B $06                          ;01A2BB|8406    |001CDD;
                       LDX.W #$0000                       ;01A2BD|A20000  |      ;
                       STX.B $00                          ;01A2C0|8600    |001CD7;
                       LDX.W $19DE                        ;01A2C2|AEDE19  |0119DE;
                       STX.B $02                          ;01A2C5|8602    |001CD9;
                       BPL CODE_01A2CD                     ;01A2C7|1004    |01A2CD;

CODE_01A2C9:
                       PLD                                 ;01A2C9|2B      |      ;
                       PLP                                 ;01A2CA|28      |      ;
                       PLB                                 ;01A2CB|AB      |      ;
                       RTS                                 ;01A2CC|60      |      ;

; ==============================================================================
; Sound Data Processing Loop
; Main audio processing routine with data validation and channel management
; ==============================================================================

CODE_01A2CD:
                       SEP #$20                           ;01A2CD|E220    |      ;
                       REP #$10                           ;01A2CF|C210    |      ;
                       LDX.B $02                          ;01A2D1|A602    |001CD9;
                       LDA.L DATA8_0CD694,X                ;01A2D3|BF94D60C|0CD694;
                       CMP.B #$FF                         ;01A2D7|C9FF    |      ;
                       BEQ CODE_01A32E                     ;01A2D9|F053    |01A32E;
                       STA.B $04                          ;01A2DB|8504    |001CDB;
                       LDX.B $00                          ;01A2DD|A600    |001CD7;
                       LDA.L $7FCED8,X                    ;01A2DF|BFD8CE7F|7FCED8;
                       CMP.B $04                          ;01A2E3|C504    |001CDB;
                       BCC CODE_01A32E                     ;01A2E5|9047    |01A32E;
                       LDA.B #$00                         ;01A2E7|A900    |      ;
                       STA.L $7FCED8,X                    ;01A2E9|9FD8CE7F|7FCED8;
                       XBA                                 ;01A2ED|EB      |      ;
                       LDA.L $7FCED9,X                    ;01A2EE|BFD9CE7F|7FCED9;
                       REP #$30                           ;01A2F2|C230    |      ;
                       CLC                                 ;01A2F4|18      |      ;
                       ADC.B $02                          ;01A2F5|6502    |001CD9;
                       INC A                               ;01A2F7|1A      |      ;
                       INC A                               ;01A2F8|1A      |      ;
                       TAX                                 ;01A2F9|AA      |      ;
                       LDA.L DATA8_0CD694,X                ;01A2FA|BF94D60C|0CD694;
                       AND.W #$00FF                       ;01A2FE|29FF00  |      ;
                       ASL A                               ;01A301|0A      |      ;
                       TAX                                 ;01A302|AA      |      ;
                       LDA.L DATA8_058A80,X                ;01A303|BF808A05|058A80;
                       LDX.B $00                          ;01A307|A600    |001CD7;
                       STA.L $7FC5FA,X                    ;01A309|9FFAC57F|7FC5FA;
                       SEP #$20                           ;01A30D|E220    |      ;
                       REP #$10                           ;01A30F|C210    |      ;
                       LDX.B $00                          ;01A311|A600    |001CD7;
                       LDA.L $7FCED9,X                    ;01A313|BFD9CE7F|7FCED9;
                       INC A                               ;01A317|1A      |      ;
                       STA.B $04                          ;01A318|8504    |001CDB;
                       PHX                                 ;01A31A|DA      |      ;
                       LDX.B $02                          ;01A31B|A602    |001CD9;
                       LDA.L DATA8_0CD695,X                ;01A31D|BF95D60C|0CD695;
                       CMP.B $04                          ;01A321|C504    |001CDB;
                       BCS CODE_01A327                     ;01A323|B002    |01A327;
                       STZ.B $04                          ;01A325|6404    |001CDB;

CODE_01A327:
                       PLX                                 ;01A327|FA      |      ;
                       LDA.B $04                          ;01A328|A504    |001CDB;
                       STA.L $7FCED9,X                    ;01A32A|9FD9CE7F|7FCED9;

; ==============================================================================
; Audio Channel Iterator and Data Validation
; Advances to next sound channel and validates data integrity
; ==============================================================================

CODE_01A32E:
                       DEC.B $06                          ;01A32E|C606    |001CDD;
                       BNE CODE_01A335                     ;01A330|D003    |01A335;
                       JMP.W CODE_01A2C9                   ;01A332|4CC9A2  |01A2C9;

CODE_01A335:
                       LDX.B $00                          ;01A335|A600    |001CD7;
                       INX                                 ;01A337|E8      |      ;
                       INX                                 ;01A338|E8      |      ;
                       STX.B $00                          ;01A339|8600    |001CD7;
                       LDX.B $02                          ;01A33B|A602    |001CD9;

CODE_01A33D:
                       LDA.L DATA8_0CD694,X                ;01A33D|BF94D60C|0CD694;
                       INX                                 ;01A341|E8      |      ;
                       CMP.B #$FF                         ;01A342|C9FF    |      ;
                       BNE CODE_01A33D                     ;01A344|D0F7    |01A33D;
                       STX.B $02                          ;01A346|8602    |001CD9;
                       JMP.W CODE_01A2CD                   ;01A348|4CCDA2  |01A2CD;

; ==============================================================================
; Secondary Sound Effect Processing System
; Alternate sound channel processing for complex multi-layer audio
; ==============================================================================

CODE_01A34B:
                       PHB                                 ;01A34B|8B      |      ;
                       PHP                                 ;01A34C|08      |      ;
                       PHD                                 ;01A34D|0B      |      ;
                       SEP #$20                           ;01A34E|E220    |      ;
                       REP #$10                           ;01A350|C210    |      ;
                       LDA.W $19E1                        ;01A352|ADE119  |0119E1;
                       CMP.B #$FF                         ;01A355|C9FF    |      ;
                       BEQ CODE_01A36E                     ;01A357|F015    |01A36E;
                       PEA.W $1CD7                        ;01A359|F4D71C  |011CD7;
                       PLD                                 ;01A35C|2B      |      ;
                       LDY.W #$0007                       ;01A35D|A00700  |      ;
                       STY.B $06                          ;01A360|8406    |001CDD;
                       LDX.W #$0000                       ;01A362|A20000  |      ;
                       STX.B $00                          ;01A365|8600    |001CD7;
                       LDX.W $19E0                        ;01A367|AEE019  |0119E0;
                       STX.B $02                          ;01A36A|8602    |001CD9;
                       BPL CODE_01A372                     ;01A36C|1004    |01A372;

CODE_01A36E:
                       PLD                                 ;01A36E|2B      |      ;
                       PLP                                 ;01A36F|28      |      ;
                       PLB                                 ;01A370|AB      |      ;
                       RTS                                 ;01A371|60      |      ;

; ==============================================================================
; Secondary Audio Data Processing
; Mirror of primary system for layered audio effects during battle
; ==============================================================================

CODE_01A372:
                       SEP #$20                           ;01A372|E220    |      ;
                       REP #$10                           ;01A374|C210    |      ;
                       LDX.B $02                          ;01A376|A602    |001CD9;
                       LDA.L DATA8_0CD72F,X                ;01A378|BF2FD70C|0CD72F;
                       CMP.B #$FF                         ;01A37C|C9FF    |      ;
                       BEQ CODE_01A3D3                     ;01A37E|F053    |01A3D3;
                       STA.B $04                          ;01A380|8504    |001CDB;
                       LDX.B $00                          ;01A382|A600    |001CD7;
                       LDA.L $7FCEE6,X                    ;01A384|BFE6CE7F|7FCEE6;
                       CMP.B $04                          ;01A388|C504    |001CDB;
                       BCC CODE_01A3D3                     ;01A38A|9047    |01A3D3;
                       LDA.B #$00                         ;01A38C|A900    |      ;
                       STA.L $7FCEE6,X                    ;01A38E|9FE6CE7F|7FCEE6;
                       XBA                                 ;01A392|EB      |      ;
                       LDA.L $7FCEE7,X                    ;01A393|BFE7CE7F|7FCEE7;
                       REP #$30                           ;01A397|C230    |      ;
                       CLC                                 ;01A399|18      |      ;
                       ADC.B $02                          ;01A39A|6502    |001CD9;
                       INC A                               ;01A39C|1A      |      ;
                       INC A                               ;01A39D|1A      |      ;
                       TAX                                 ;01A39E|AA      |      ;
                       LDA.L DATA8_0CD72F,X                ;01A39F|BF2FD70C|0CD72F;
                       AND.W #$00FF                       ;01A3A3|29FF00  |      ;
                       ASL A                               ;01A3A6|0A      |      ;
                       TAX                                 ;01A3A7|AA      |      ;
                       LDA.L DATA8_058A80,X                ;01A3A8|BF808A05|058A80;
                       LDX.B $00                          ;01A3AC|A600    |001CD7;
                       STA.L $7FC52A,X                    ;01A3AE|9F2AC57F|7FC52A;
                       SEP #$20                           ;01A3B2|E220    |      ;
                       REP #$10                           ;01A3B4|C210    |      ;
                       LDX.B $00                          ;01A3B6|A600    |001CD7;
                       LDA.L $7FCEE7,X                    ;01A3B8|BFE7CE7F|7FCEE7;
                       INC A                               ;01A3BC|1A      |      ;
                       STA.B $04                          ;01A3BD|8504    |001CDB;
                       PHX                                 ;01A3BF|DA      |      ;
                       LDX.B $02                          ;01A3C0|A602    |001CD9;
                       LDA.L DATA8_0CD730,X                ;01A3C2|BF30D70C|0CD730;
                       CMP.B $04                          ;01A3C6|C504    |001CDB;
                       BCS CODE_01A3CC                     ;01A3C8|B002    |01A3CC;
                       STZ.B $04                          ;01A3CA|6404    |001CDB;

CODE_01A3CC:
                       PLX                                 ;01A3CC|FA      |      ;
                       LDA.B $04                          ;01A3CD|A504    |001CDB;
                       STA.L $7FCEE7,X                    ;01A3CF|9FE7CE7F|7FCEE7;

; ==============================================================================
; Secondary Audio Channel Processing
; Iterator and validation for second audio layer
; ==============================================================================

CODE_01A3D3:
                       DEC.B $06                          ;01A3D3|C606    |001CDD;
                       BNE CODE_01A3DA                     ;01A3D5|D003    |01A3DA;
                       JMP.W CODE_01A36E                   ;01A3D7|4C6EA3  |01A36E;

CODE_01A3DA:
                       LDX.B $00                          ;01A3DA|A600    |001CD7;
                       INX                                 ;01A3DC|E8      |      ;
                       INX                                 ;01A3DD|E8      |      ;
                       STX.B $00                          ;01A3DE|8600    |001CD7;
                       LDX.B $02                          ;01A3E0|A602    |001CD9;

CODE_01A3E2:
                       LDA.L DATA8_0CD72F,X                ;01A3E2|BF2FD70C|0CD72F;
                       INX                                 ;01A3E6|E8      |      ;
                       CMP.B #$FF                         ;01A3E7|C9FF    |      ;
                       BNE CODE_01A3E2                     ;01A3E9|D0F7    |01A3E2;
                       STX.B $02                          ;01A3EB|8602    |001CD9;
                       JMP.W CODE_01A372                   ;01A3ED|4C72A3  |01A372;

; ==============================================================================
; Main Battle Animation Controller
; Coordinates all sprite animation and graphics updates during battle
; ==============================================================================

CODE_01A3F0:
                       PHP                                 ;01A3F0|08      |      ;
                       PHB                                 ;01A3F1|8B      |      ;
                       REP #$30                           ;01A3F2|C230    |      ;
                       LDA.W $19B9                        ;01A3F4|ADB919  |0119B9;
                       BMI CODE_01A401                     ;01A3F7|3008    |01A401;
                       SEP #$20                           ;01A3F9|E220    |      ;
                       JSR.W CODE_01A423                   ;01A3FB|2023A4  |01A423;
                       JSR.W CODE_01A9EE                   ;01A3FE|20EEA9  |01A9EE;

CODE_01A401:
                       PLB                                 ;01A401|AB      |      ;
                       PLP                                 ;01A402|28      |      ;
                       RTS                                 ;01A403|60      |      ;

; ==============================================================================
; Extended Battle Animation Handler
; Enhanced animation processing with additional graphics coordination
; ==============================================================================

CODE_01A404:
                       PHP                                 ;01A404|08      |      ;
                       PHB                                 ;01A405|8B      |      ;
                       REP #$30                           ;01A406|C230    |      ;
                       LDA.W $19B9                        ;01A408|ADB919  |0119B9;
                       BMI CODE_01A420                     ;01A40B|3013    |01A420;
                       SEP #$20                           ;01A40D|E220    |      ;
                       JSR.W CODE_01A423                   ;01A40F|2023A4  |01A423;
                       JSR.W CODE_01A692                   ;01A412|2092A6  |01A692;
                       JSR.W CODE_01A947                   ;01A415|2047A9  |01A947;
                       JSR.W CODE_01A9EE                   ;01A418|20EEA9  |01A9EE;
                       SEP #$20                           ;01A41B|E220    |      ;
                       STZ.W $1A71                        ;01A41D|9C711A  |001A71;

CODE_01A420:
                       PLB                                 ;01A420|AB      |      ;
                       PLP                                 ;01A421|28      |      ;
                       RTS                                 ;01A422|60      |      ;

; ==============================================================================
; Graphics Preparation and Memory Management
; Major graphics loading system with memory initialization and data transfer
; ==============================================================================

CODE_01A423:
                       REP #$30                           ;01A423|C230    |      ;
                       PHD                                 ;01A425|0B      |      ;
                       PEA.W $192B                        ;01A426|F42B19  |01192B;
                       PLD                                 ;01A429|2B      |      ;
                       PHB                                 ;01A42A|8B      |      ;
                       LDA.W #$0000                       ;01A42B|A90000  |      ;
                       STA.L $7F0000                      ;01A42E|8F00007F|7F0000;
                       LDX.W #$0000                       ;01A432|A20000  |      ;
                       LDY.W #$0001                       ;01A435|A00100  |      ;
                       LDA.W #$3DFF                       ;01A438|A9FF3D  |      ;
                       MVN $7F,$7F                       ;01A43B|547F7F  |      ;
                       PLB                                 ;01A43E|AB      |      ;
                       SEP #$20                           ;01A43F|E220    |      ;
                       REP #$10                           ;01A441|C210    |      ;
                       LDA.B #$06                         ;01A443|A906    |      ;
                       STA.B $0A                          ;01A445|850A    |001935;
                       STZ.B $0C                          ;01A447|640C    |001937;
                       LDA.B #$0C                         ;01A449|A90C    |      ;
                       STA.B $0B                          ;01A44B|850B    |001936;
                       LDX.W #$C488                       ;01A44D|A288C4  |      ;
                       STX.B $00                          ;01A450|8600    |00192B;
                       LDY.W #$0006                       ;01A452|A00600  |      ;
                       LDX.W $19B9                        ;01A455|AEB919  |0119B9;
                       REP #$30                           ;01A458|C230    |      ;

; ==============================================================================
; Graphics Data Loading Loop
; Processes character graphics and transfers to VRAM with complex addressing
; ==============================================================================

CODE_01A45A:
                       LDA.L DATA8_0B88FC,X                ;01A45A|BFFC880B|0B88FC;
                       AND.W #$00FF                       ;01A45E|29FF00  |      ;
                       ASL A                               ;01A461|0A      |      ;
                       ASL A                               ;01A462|0A      |      ;
                       ASL A                               ;01A463|0A      |      ;
                       ASL A                               ;01A464|0A      |      ;
                       CLC                                 ;01A465|18      |      ;
                       ADC.W #$D824                       ;01A466|6924D8  |      ;
                       PHX                                 ;01A469|DA      |      ;
                       PHY                                 ;01A46A|5A      |      ;
                       PHB                                 ;01A46B|8B      |      ;
                       LDY.B $00                          ;01A46C|A400    |00192B;
                       TAX                                 ;01A46E|AA      |      ;
                       LDA.W #$000F                       ;01A46F|A90F00  |      ;
                       MVN $7F,$07                       ;01A472|547F07  |      ;
                       PLB                                 ;01A475|AB      |      ;
                       PLY                                 ;01A476|7A      |      ;
                       PLX                                 ;01A477|FA      |      ;
                       INX                                 ;01A478|E8      |      ;
                       LDA.B $00                          ;01A479|A500    |00192B;
                       CLC                                 ;01A47B|18      |      ;
                       ADC.W #$0020                       ;01A47C|692000  |      ;
                       STA.B $00                          ;01A47F|8500    |00192B;
                       DEY                                 ;01A481|88      |      ;
                       BNE CODE_01A45A                     ;01A482|D0D6    |01A45A;
                       REP #$30                           ;01A484|C230    |      ;
                       PEA.W $0004                        ;01A486|F40400  |010004;
                       PLB                                 ;01A489|AB      |      ;
                       LDA.W #$0010                       ;01A48A|A91000  |      ;
                       STA.B $14                          ;01A48D|8514    |00193F;
                       LDY.W #$E520                       ;01A48F|A020E5  |      ;
                       LDX.W #$0000                       ;01A492|A20000  |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 3)
; Advanced Graphics Memory Transfer and Animation Processing
; ==============================================================================

; ==============================================================================
; Main Graphics Memory Transfer Loop
; Large-scale graphics processing with dual memory bank coordination
; ==============================================================================

CODE_01A495:
                       REP #$30                           ;01A495|C230    |      ;
                       LDA.W #$0002                       ;01A497|A90200  |      ;
                       STA.B $16                          ;01A49A|8516    |001941;

; ==============================================================================
; Dual Memory Block Transfer Engine
; Processes 4x 16-byte blocks in parallel with complex bank switching
; ==============================================================================

CODE_01A49C:
                       LDA.W $0000,Y                      ;01A49C|B90000  |040000;
                       STA.L $7F0000,X                    ;01A49F|9F00007F|7F0000;
                       LDA.W $0002,Y                      ;01A4A3|B90200  |040002;
                       STA.L $7F0002,X                    ;01A4A6|9F02007F|7F0002;
                       LDA.W $0004,Y                      ;01A4AA|B90400  |040004;
                       STA.L $7F0004,X                    ;01A4AD|9F04007F|7F0004;
                       LDA.W $0006,Y                      ;01A4B1|B90600  |040006;
                       STA.L $7F0006,X                    ;01A4B4|9F06007F|7F0006;
                       TYA                                 ;01A4B8|98      |      ;
                       CLC                                 ;01A4B9|18      |      ;
                       ADC.W #$0008                       ;01A4BA|690800  |      ;
                       TAY                                 ;01A4BD|A8      |      ;
                       TXA                                 ;01A4BE|8A      |      ;
                       CLC                                 ;01A4BF|18      |      ;
                       ADC.W #$0008                       ;01A4C0|690800  |      ;
                       TAX                                 ;01A4C3|AA      |      ;
                       DEC.B $16                          ;01A4C4|C616    |001941;
                       BNE CODE_01A49C                     ;01A4C6|D0D4    |01A49C;
                       SEP #$20                           ;01A4C8|E220    |      ;
                       REP #$10                           ;01A4CA|C210    |      ;
                       LDA.B #$08                         ;01A4CC|A908    |      ;
                       STA.B $18                          ;01A4CE|8518    |001943;

; ==============================================================================
; Secondary Graphics Transfer with Format Conversion
; Single-byte transfer loop with automatic format conversion
; ==============================================================================

CODE_01A4D0:
                       LDA.W $0000,Y                      ;01A4D0|B90000  |040000;
                       STA.L $7F0000,X                    ;01A4D3|9F00007F|7F0000;
                       LDA.B #$00                         ;01A4D7|A900    |      ;
                       STA.L $7F0001,X                    ;01A4D9|9F01007F|7F0001;
                       INX                                 ;01A4DD|E8      |      ;
                       INX                                 ;01A4DE|E8      |      ;
                       INY                                 ;01A4DF|C8      |      ;
                       DEC.B $18                          ;01A4E0|C618    |001943;
                       BNE CODE_01A4D0                     ;01A4E2|D0EC    |01A4D0;
                       REP #$30                           ;01A4E4|C230    |      ;
                       DEC.B $14                          ;01A4E6|C614    |00193F;
                       BNE CODE_01A495                     ;01A4E8|D0AB    |01A495;
                       PLB                                 ;01A4EA|AB      |      ;

; ==============================================================================
; Character Graphics Processing Loop
; Complex sprite data processing with 16-tile character animation
; ==============================================================================

CODE_01A4EB:
                       SEP #$20                           ;01A4EB|E220    |      ;
                       REP #$10                           ;01A4ED|C210    |      ;
                       LDA.B #$80                         ;01A4EF|A980    |      ;
                       STA.B $0E                          ;01A4F1|850E    |001939;
                       LDY.W #$0008                       ;01A4F3|A00800  |      ;

CODE_01A4F6:
                       LDA.B #$00                         ;01A4F6|A900    |      ;
                       XBA                                 ;01A4F8|EB      |      ;
                       LDA.B $0A                          ;01A4F9|A50A    |001935;
                       REP #$30                           ;01A4FB|C230    |      ;
                       CLC                                 ;01A4FD|18      |      ;
                       ADC.W $19B9                        ;01A4FE|6DB919  |0119B9;
                       TAX                                 ;01A501|AA      |      ;
                       SEP #$20                           ;01A502|E220    |      ;
                       REP #$10                           ;01A504|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A506|BFFC880B|0B88FC;
                       STA.B $0D                          ;01A50A|850D    |001938;

; ==============================================================================
; Bit-Level Sprite Processing
; Processes individual sprite bits with complex masking and animation
; ==============================================================================

CODE_01A50C:
                       PHY                                 ;01A50C|5A      |      ;
                       LDA.B $0D                          ;01A50D|A50D    |001938;
                       AND.B $0E                          ;01A50F|250E    |001939;
                       BEQ CODE_01A52C                     ;01A511|F019    |01A52C;
                       LDA.B #$00                         ;01A513|A900    |      ;
                       XBA                                 ;01A515|EB      |      ;
                       LDA.B $0B                          ;01A516|A50B    |001936;
                       INC.B $0B                          ;01A518|E60B    |001936;
                       REP #$30                           ;01A51A|C230    |      ;
                       CLC                                 ;01A51C|18      |      ;
                       ADC.W $19B9                        ;01A51D|6DB919  |0119B9;
                       TAX                                 ;01A520|AA      |      ;
                       SEP #$20                           ;01A521|E220    |      ;
                       REP #$10                           ;01A523|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A525|BFFC880B|0B88FC;
                       JSR.W CODE_01A865                   ;01A529|2065A8  |01A865;

CODE_01A52C:
                       SEP #$20                           ;01A52C|E220    |      ;
                       REP #$10                           ;01A52E|C210    |      ;
                       INC.B $0C                          ;01A530|E60C    |001937;
                       LDA.B $0E                          ;01A532|A50E    |001939;
                       LSR A                               ;01A534|4A      |      ;
                       STA.B $0E                          ;01A535|850E    |001939;
                       PLY                                 ;01A537|7A      |      ;
                       DEY                                 ;01A538|88      |      ;
                       BNE CODE_01A50C                     ;01A539|D0D1    |01A50C;
                       INC.B $0A                          ;01A53B|E60A    |001935;
                       LDA.B $0A                          ;01A53D|A50A    |001935;
                       CMP.B #$0C                         ;01A53F|C90C    |      ;
                       BEQ CODE_01A550                     ;01A541|F00D    |01A550;
                       CMP.B #$0B                         ;01A543|C90B    |      ;
                       BNE CODE_01A4EB                     ;01A545|D0A4    |01A4EB;
                       LDA.B #$80                         ;01A547|A980    |      ;
                       STA.B $0E                          ;01A549|850E    |001939;
                       LDY.W #$0004                       ;01A54B|A00400  |      ;
                       BRA CODE_01A4F6                     ;01A54E|80A6    |01A4F6;

; ==============================================================================
; Final Graphics Processing and Validation
; Completes character processing with special effect integration
; ==============================================================================

CODE_01A550:
                       REP #$30                           ;01A550|C230    |      ;
                       LDA.W #$000B                       ;01A552|A90B00  |      ;
                       CLC                                 ;01A555|18      |      ;
                       ADC.W $19B9                        ;01A556|6DB919  |0119B9;
                       TAX                                 ;01A559|AA      |      ;
                       SEP #$20                           ;01A55A|E220    |      ;
                       REP #$10                           ;01A55C|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A55E|BFFC880B|0B88FC;
                       BIT.B #$01                         ;01A562|8901    |      ;
                       BEQ CODE_01A573                     ;01A564|F00D    |01A573;
                       LDA.B #$F2                         ;01A566|A9F2    |      ;
                       JSL.L CODE_009776                   ;01A568|22769700|009776;
                       BNE CODE_01A571                     ;01A56C|D003    |01A571;
                       JSR.W CODE_01A5AA                   ;01A56E|20AAA5  |01A5AA;

CODE_01A571:
                       BRA CODE_01A5A8                     ;01A571|8035    |01A5A8;

; ==============================================================================
; Standard Graphics Transfer Mode
; Handles normal character display without special effects
; ==============================================================================

CODE_01A573:
                       LDX.W #$ADA0                       ;01A573|A2A0AD  |      ;
                       STX.B $02                          ;01A576|8602    |00192D;
                       LDA.B #$04                         ;01A578|A904    |      ;
                       STA.B $06                          ;01A57A|8506    |001931;
                       LDA.B #$7F                         ;01A57C|A97F    |      ;
                       STA.B $07                          ;01A57E|8507    |001932;
                       LDA.B #$00                         ;01A580|A900    |      ;
                       XBA                                 ;01A582|EB      |      ;
                       LDA.B $0C                          ;01A583|A50C    |001937;
                       ASL A                               ;01A585|0A      |      ;
                       TAX                                 ;01A586|AA      |      ;
                       REP #$30                           ;01A587|C230    |      ;
                       LDA.L DATA8_01A5E0,X                ;01A589|BFE0A501|01A5E0;
                       STA.B $04                          ;01A58D|8504    |00192F;
                       LDY.W #$0060                       ;01A58F|A06000  |      ;

; ==============================================================================
; Graphics Transfer Coordination Loop
; Coordinates 96 transfer operations with memory management
; ==============================================================================

CODE_01A592:
                       JSR.W CODE_01A901                   ;01A592|2001A9  |01A901;
                       LDA.B $02                          ;01A595|A502    |00192D;
                       CLC                                 ;01A597|18      |      ;
                       ADC.W #$0018                       ;01A598|691800  |      ;
                       STA.B $02                          ;01A59B|8502    |00192D;
                       LDA.B $04                          ;01A59D|A504    |00192F;
                       CLC                                 ;01A59F|18      |      ;
                       ADC.W #$0020                       ;01A5A0|692000  |      ;
                       STA.B $04                          ;01A5A3|8504    |00192F;
                       DEY                                 ;01A5A5|88      |      ;
                       BNE CODE_01A592                     ;01A5A6|D0EA    |01A592;

CODE_01A5A8:
                       PLD                                 ;01A5A8|2B      |      ;
                       RTS                                 ;01A5A9|60      |      ;

; ==============================================================================
; Special Effects Graphics Handler
; Extended graphics processing for special battle effects
; ==============================================================================

CODE_01A5AA:
                       PHP                                 ;01A5AA|08      |      ;
                       PHD                                 ;01A5AB|0B      |      ;
                       PEA.W $192B                        ;01A5AC|F42B19  |00192B;
                       PLD                                 ;01A5AF|2B      |      ;
                       LDX.W #$BE20                       ;01A5B0|A220BE  |      ;
                       STX.B $02                          ;01A5B3|8602    |00192D;
                       LDA.B #$04                         ;01A5B5|A904    |      ;
                       STA.B $06                          ;01A5B7|8506    |001931;
                       LDA.B #$7F                         ;01A5B9|A97F    |      ;
                       STA.B $07                          ;01A5BB|8507    |001932;
                       REP #$30                           ;01A5BD|C230    |      ;
                       LDA.W #$1E00                       ;01A5BF|A9001E  |      ;
                       STA.B $04                          ;01A5C2|8504    |00192F;
                       LDY.W #$0080                       ;01A5C4|A08000  |      ;

; ==============================================================================
; Extended Graphics Transfer Loop (128 Operations)
; Larger transfer cycle for complex special effects
; ==============================================================================

CODE_01A5C7:
                       JSR.W CODE_01A901                   ;01A5C7|2001A9  |01A901;
                       LDA.B $02                          ;01A5CA|A502    |00192D;
                       CLC                                 ;01A5CC|18      |      ;
                       ADC.W #$0018                       ;01A5CD|691800  |      ;
                       STA.B $02                          ;01A5D0|8502    |00192D;
                       LDA.B $04                          ;01A5D2|A504    |00192F;
                       CLC                                 ;01A5D4|18      |      ;
                       ADC.W #$0020                       ;01A5D5|692000  |      ;
                       STA.B $04                          ;01A5D8|8504    |00192F;
                       DEY                                 ;01A5DA|88      |      ;
                       BNE CODE_01A5C7                     ;01A5DB|D0EA    |01A5C7;
                       PLD                                 ;01A5DD|2B      |      ;
                       PLP                                 ;01A5DE|28      |      ;
                       RTS                                 ;01A5DF|60      |      ;

; ==============================================================================
; Graphics Configuration Data Tables
; Complex addressing tables for multi-bank graphics coordination
; ==============================================================================

DATA8_01A5E0:
                       db $00,$02,$80,$02,$00,$03,$80,$03,$00,$04,$00,$06,$00,$0E,$00,$16 ; 01A5E0
                       db $00,$08,$80,$08,$00,$09,$80,$09,$00,$0A,$80,$0A,$00,$0B,$80,$0B ; 01A5F0
                       db $00,$0C                        ; 01A600
                       db $80,$0C,$00,$0D,$80,$0D    ; 01A602
                       db $00,$10,$80,$10,$00,$11,$80,$11,$00,$12,$80,$12,$00,$13,$80,$13 ; 01A608
                       db $00,$14                        ; 01A618
                       db $80,$14,$00,$15,$80,$15    ; 01A61A
                       db $00,$18,$80,$18,$00,$19,$80,$19,$00,$1A ; 01A620
                       db $80,$1A,$00,$1B              ; 01A62A
                       db $80,$1B,$00,$1C              ; 01A62E
                       db $80,$1C,$00,$1D,$80,$1D    ; 01A632
                       db $00,$1E                        ; 01A638

; ==============================================================================
; OAM Configuration Tables
; Sprite positioning and attribute data for battle system
; ==============================================================================

DATA8_01A63A:
                       db $80,$00                        ; 01A63A

DATA8_01A63C:
                       db $08,$02,$90,$00,$09,$02,$A0,$00,$0A,$02,$B0,$00,$0B,$02,$E0,$00 ; 01A63C
                       db $0E,$02,$F0,$00,$0F,$02,$00,$01,$10,$02,$10,$01,$11,$02,$20,$01 ; 01A64C
                       db $12,$02,$30,$01,$13,$02,$40,$01,$14,$02,$50,$01,$15,$02,$60,$01 ; 01A65C
                       db $16,$02,$70,$01,$17,$02,$80,$01,$18,$02,$90,$01,$19,$02,$A0,$01 ; 01A66C
                       db $1A,$02,$B0,$01,$1B,$02,$C0,$01,$1C,$02,$D0,$01,$1D,$02,$E0,$01 ; 01A67C
                       db $1E,$02,$F0,$01,$1F,$02    ; 01A68C

; ==============================================================================
; Main Sprite Engine Initialization
; Sets up sprite management system with memory allocation and coordination
; ==============================================================================

CODE_01A692:
                       SEP #$20                           ;01A692|E220    |      ;
                       REP #$10                           ;01A694|C210    |      ;
                       PHD                                 ;01A696|0B      |      ;
                       PEA.W $1A72                        ;01A697|F4721A  |001A72;
                       PLD                                 ;01A69A|2B      |      ;
                       LDX.W #$0000                       ;01A69B|A20000  |      ;
                       STX.W $1939                        ;01A69E|8E3919  |001939;
                       JSR.W CODE_01AF56                   ;01A6A1|2056AF  |01AF56;
                       SEP #$20                           ;01A6A4|E220    |      ;
                       REP #$10                           ;01A6A6|C210    |      ;
                       LDA.B #$FF                         ;01A6A8|A9FF    |      ;
                       STA.W $193B                        ;01A6AA|8D3B19  |00193B;
                       LDA.B #$08                         ;01A6AD|A908    |      ;
                       STA.W $1935                        ;01A6AF|8D3519  |001935;

; ==============================================================================
; Sprite Data Processing Loop
; Processes all active sprites with validation and coordinate processing
; ==============================================================================

CODE_01A6B2:
                       SEP #$20                           ;01A6B2|E220    |      ;
                       REP #$10                           ;01A6B4|C210    |      ;
                       INC.W $193B                        ;01A6B6|EE3B19  |00193B;
                       LDA.W $1935                        ;01A6B9|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A6BC|20DD90  |0190DD;
                       CMP.B #$FF                         ;01A6BF|C9FF    |      ;
                       BEQ CODE_01A6F0                     ;01A6C1|F02D    |01A6F0;
                       JSR.W CODE_01A6F2                   ;01A6C3|20F2A6  |01A6F2;
                       BCS CODE_01A6E1                     ;01A6C6|B019    |01A6E1;
                       REP #$30                           ;01A6C8|C230    |      ;
                       LDX.W $1939                        ;01A6CA|AE3919  |001939;
                       LDA.B $01,X                        ;01A6CD|B501    |001A73;
                       STA.B $03,X                        ;01A6CF|9503    |001A75;
                       STA.B $05,X                        ;01A6D1|9505    |001A77;
                       STA.B $07,X                        ;01A6D3|9507    |001A79;
                       LDA.W $1939                        ;01A6D5|AD3919  |001939;
                       CLC                                 ;01A6D8|18      |      ;
                       ADC.W #$001A                       ;01A6D9|691A00  |      ;
                       STA.W $1939                        ;01A6DC|8D3919  |001939;
                       BRA CODE_01A6B2                     ;01A6DF|80D1    |01A6B2;

CODE_01A6E1:
                       SEP #$20                           ;01A6E1|E220    |      ;
                       REP #$10                           ;01A6E3|C210    |      ;
                       LDA.W $1935                        ;01A6E5|AD3519  |001935;
                       CLC                                 ;01A6E8|18      |      ;
                       ADC.B #$07                         ;01A6E9|6907    |      ;
                       STA.W $1935                        ;01A6EB|8D3519  |001935;
                       BRA CODE_01A6B2                     ;01A6EE|80C2    |01A6B2;

CODE_01A6F0:
                       PLD                                 ;01A6F0|2B      |      ;
                       RTS                                 ;01A6F1|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 1)
; Advanced Battle Animation and Sprite Management Systems
; ==============================================================================

; ==============================================================================
; Advanced Sprite Position Calculation with Screen Clipping
; Complex sprite coordinate processing with boundary checks and multi-sprite handling
; ==============================================================================

CODE_01A0E5:
                       SEC                                  ;01A0E5|38      |      ;
                       SBC.B $00                          ;01A0E6|E500    |001A62;
                       AND.W #$03FF                       ;01A0E8|29FF03  |      ;
                       STA.B $23,X                        ;01A0EB|9523    |001A85;
                       LDA.B $25,X                        ;01A0ED|B525    |001A87;
                       SEC                                  ;01A0EF|38      |      ;
                       SBC.B $02                          ;01A0F0|E502    |001A64;
                       AND.W #$03FF                       ;01A0F2|29FF03  |      ;
                       STA.B $25,X                        ;01A0F5|9525    |001A87;
                       SEP #$20                           ;01A0F7|E220    |      ;
                       LDA.B $1E,X                        ;01A0F9|B51E    |001A80;
                       EOR.W $19B4                        ;01A0FB|4DB419  |0119B4;
                       BIT.B #$08                         ;01A0FE|8908    |      ;
                       BEQ CODE_01A105                     ;01A100|F003    |01A105;
                       JMP.W CODE_01A186                   ;01A102|4C86A1  |01A186;

CODE_01A105:
                       LDA.B #$00                         ;01A105|A900    |      ;
                       XBA                                 ;01A107|EB      |      ;
                       LDA.B $19,X                        ;01A108|B519    |001A7B;
                       BPL CODE_01A10F                     ;01A10A|1003    |01A10F;
                       db $EB,$3A,$EB                   ;01A10C|        |      ;

CODE_01A10F:
                       REP #$20                           ;01A10F|C220    |      ;
                       CLC                                 ;01A111|18      |      ;
                       ADC.B $23,X                        ;01A112|7523    |001A85;
                       STA.B $0A                          ;01A114|850A    |001A6C;
                       LDA.W #$0000                       ;01A116|A90000  |      ;
                       SEP #$20                           ;01A119|E220    |      ;
                       LDA.B $1A,X                        ;01A11B|B51A    |001A7C;
                       BPL CODE_01A122                     ;01A11D|1003    |01A122;
                       db $EB,$3A,$EB                   ;01A11F|        |      ;

CODE_01A122:
                       REP #$20                           ;01A122|C220    |      ;
                       CLC                                 ;01A124|18      |      ;
                       ADC.B $25,X                        ;01A125|7525    |001A87;
                       STA.B $0C                          ;01A127|850C    |001A6E;
                       REP #$20                           ;01A129|C220    |      ;
                       LDX.B $04                          ;01A12B|A604    |001A66;
                       LDY.W DATA8_01A63C,X                ;01A12D|BC3CA6  |01A63C;
                       LDA.W DATA8_01A63A,X                ;01A130|BD3AA6  |01A63A;
                       TAX                                 ;01A133|AA      |      ;
                       LDA.B $0C                          ;01A134|A50C    |001A6E;
                       CMP.W #$00E8                       ;01A136|C9E800  |      ;
                       BCC CODE_01A140                     ;01A139|9005    |01A140;
                       CMP.W #$03F8                       ;01A13B|C9F803  |      ;
                       BCC CODE_01A191                     ;01A13E|9051    |01A191;

; ==============================================================================
; Multi-Sprite OAM Setup with Complex Boundary Testing
; Handles 4-sprite large character display with screen clipping and priority
; ==============================================================================

CODE_01A140:
                       LDA.B $0A                          ;01A140|A50A    |001A6C;
                       CMP.W #$00F8                       ;01A142|C9F800  |      ;
                       BCC CODE_01A15E                     ;01A145|9017    |01A15E;
                       CMP.W #$0100                       ;01A147|C90001  |      ;
                       BCC CODE_01A1A8                     ;01A14A|905C    |01A1A8;
                       CMP.W #$03F0                       ;01A14C|C9F003  |      ;
                       BCC CODE_01A191                     ;01A14F|9040    |01A191;
                       CMP.W #$03F8                       ;01A151|C9F803  |      ;
                       BCC CODE_01A1D3                     ;01A154|907D    |01A1D3;
                       CMP.W #$0400                       ;01A156|C90004  |      ;
                       BCS CODE_01A15E                     ;01A159|B003    |01A15E;
                       JMP.W CODE_01A1FF                   ;01A15B|4CFFA1  |01A1FF;

; ==============================================================================
; Standard 4-Sprite OAM Configuration
; Sets up normal sprite display with 16x16 tile arrangement
; ==============================================================================

CODE_01A15E:
                       SEP #$20                           ;01A15E|E220    |      ;
                       STA.W $0C00,X                      ;01A160|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A163|9D080C  |010C08;
                       CLC                                 ;01A166|18      |      ;
                       ADC.B #$08                         ;01A167|6908    |      ;
                       STA.W $0C04,X                      ;01A169|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A16C|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A16F|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A171|9D010C  |010C01;
                       STA.W $0C05,X                      ;01A174|9D050C  |010C05;
                       CLC                                 ;01A177|18      |      ;
                       ADC.B #$08                         ;01A178|6908    |      ;
                       STA.W $0C09,X                      ;01A17A|9D090C  |010C09;
                       STA.W $0C0D,X                      ;01A17D|9D0D0C  |010C0D;
                       LDA.B #$00                         ;01A180|A900    |      ;
                       STA.W $0C00,Y                      ;01A182|99000C  |010C00;
                       RTS                                 ;01A185|60      |      ;

; ==============================================================================
; Off-Screen Sprite Handling
; Hides sprites that are completely outside visible screen area
; ==============================================================================

CODE_01A186:
                       REP #$20                           ;01A186|C220    |      ;
                       LDX.B $04                          ;01A188|A604    |001A66;
                       LDY.W DATA8_01A63C,X                ;01A18A|BC3CA6  |01A63C;
                       LDA.W DATA8_01A63A,X                ;01A18D|BD3AA6  |01A63A;
                       TAX                                 ;01A190|AA      |      ;

CODE_01A191:
                       LDA.W #$E080                       ;01A191|A980E0  |      ;
                       STA.W $0C00,X                      ;01A194|9D000C  |010C00;
                       STA.W $0C04,X                      ;01A197|9D040C  |010C04;
                       STA.W $0C08,X                      ;01A19A|9D080C  |010C08;
                       STA.W $0C0C,X                      ;01A19D|9D0C0C  |010C0C;
                       SEP #$20                           ;01A1A0|E220    |      ;
                       LDA.B #$55                         ;01A1A2|A955    |      ;
                       STA.W $0C00,Y                      ;01A1A4|99000C  |010C00;
                       RTS                                 ;01A1A7|60      |      ;

; ==============================================================================
; Right Edge Clipping Configuration
; Handles sprites partially visible on right edge of screen
; ==============================================================================

CODE_01A1A8:
                       SEP #$20                           ;01A1A8|E220    |      ;
                       STA.W $0C00,X                      ;01A1AA|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A1AD|9D080C  |010C08;
                       LDA.B #$80                         ;01A1B0|A980    |      ;
                       STA.W $0C04,X                      ;01A1B2|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A1B5|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A1B8|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A1BA|9D010C  |010C01;
                       CLC                                 ;01A1BD|18      |      ;
                       ADC.B #$08                         ;01A1BE|6908    |      ;
                       STA.W $0C09,X                      ;01A1C0|9D090C  |010C09;
                       LDA.B #$E0                         ;01A1C3|A9E0    |      ;
                       STA.W $0C05,X                      ;01A1C5|9D050C  |010C05;
                       STA.W $0C0D,X                      ;01A1C8|9D0D0C  |010C0D;
                       SEP #$20                           ;01A1CB|E220    |      ;
                       LDA.B #$44                         ;01A1CD|A944    |      ;
                       STA.W $0C00,Y                      ;01A1CF|99000C  |010C00;
                       RTS                                 ;01A1D2|60      |      ;

; ==============================================================================
; Left Edge Clipping Configuration
; Handles sprites partially visible on left edge of screen
; ==============================================================================

CODE_01A1D3:
                       SEP #$20                           ;01A1D3|E220    |      ;
                       CLC                                 ;01A1D5|18      |      ;
                       ADC.B #$08                         ;01A1D6|6908    |      ;
                       STA.W $0C04,X                      ;01A1D8|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A1DB|9D0C0C  |010C0C;
                       LDA.B #$80                         ;01A1DE|A980    |      ;
                       STA.W $0C00,X                      ;01A1E0|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A1E3|9D080C  |010C08;
                       LDA.B $0C                          ;01A1E6|A50C    |001A6E;
                       STA.W $0C05,X                      ;01A1E8|9D050C  |010C05;
                       CLC                                 ;01A1EB|18      |      ;
                       ADC.B #$08                         ;01A1EC|6908    |      ;
                       STA.W $0C0D,X                      ;01A1EE|9D0D0C  |010C0D;
                       LDA.B #$E0                         ;01A1F1|A9E0    |      ;
                       STA.W $0C01,X                      ;01A1F3|9D010C  |010C01;
                       STA.W $0C09,X                      ;01A1F6|9D090C  |010C09;
                       LDA.B #$55                         ;01A1F9|A955    |      ;
                       STA.W $0C00,Y                      ;01A1FB|99000C  |010C00;
                       RTS                                 ;01A1FE|60      |      ;

; ==============================================================================
; Full Visibility Sprite Setup (Screen Wrap)
; Handles sprites fully visible including wraparound positioning
; ==============================================================================

CODE_01A1FF:
                       SEP #$20                           ;01A1FF|E220    |      ;
                       STA.W $0C00,X                      ;01A201|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A204|9D080C  |010C08;
                       CLC                                 ;01A207|18      |      ;
                       ADC.B #$08                         ;01A208|6908    |      ;
                       STA.W $0C04,X                      ;01A20A|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A20D|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A210|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A212|9D010C  |010C01;
                       STA.W $0C05,X                      ;01A215|9D050C  |010C05;
                       CLC                                 ;01A218|18      |      ;
                       ADC.B #$08                         ;01A219|6908    |      ;
                       STA.W $0C09,X                      ;01A21B|9D090C  |010C09;
                       STA.W $0C0D,X                      ;01A21E|9D0D0C  |010C0D;
                       LDA.B #$11                         ;01A221|A911    |      ;
                       STA.W $0C00,Y                      ;01A223|99000C  |010C00;
                       RTS                                 ;01A226|60      |      ;

; ==============================================================================
; Sound Effect System Initialization
; Complex audio channel management with battle sound coordination
; ==============================================================================

CODE_01A227:
                       PHP                                 ;01A227|08      |      ;
                       SEP #$20                           ;01A228|E220    |      ;
                       REP #$10                           ;01A22A|C210    |      ;
                       LDX.W #$FFFF                       ;01A22C|A2FFFF  |      ;
                       STX.W $19DE                        ;01A22F|8EDE19  |0119DE;
                       STX.W $19E0                        ;01A232|8EE019  |0119E0;
                       LDA.W $1914                        ;01A235|AD1419  |011914;
                       BIT.B #$20                         ;01A238|8920    |      ;
                       BEQ CODE_01A267                     ;01A23A|F02B    |01A267;
                       LDA.B #$00                         ;01A23C|A900    |      ;
                       XBA                                 ;01A23E|EB      |      ;
                       LDA.W $1913                        ;01A23F|AD1319  |011913;
                       AND.B #$0F                         ;01A242|290F    |      ;
                       ASL A                               ;01A244|0A      |      ;
                       TAX                                 ;01A245|AA      |      ;
                       LDA.L UNREACH_0CD666,X              ;01A246|BF66D60C|0CD666;
                       PHX                                 ;01A24A|DA      |      ;
                       ASL A                               ;01A24B|0A      |      ;
                       TAX                                 ;01A24C|AA      |      ;
                       REP #$30                           ;01A24D|C230    |      ;
                       LDA.L DATA8_0CD686,X                ;01A24F|BF86D60C|0CD686;
                       STA.W $19DE                        ;01A253|8DDE19  |0119DE;
                       PLX                                 ;01A256|FA      |      ;
                       LDA.L UNREACH_0CD667,X              ;01A257|BF67D60C|0CD667;
                       AND.W #$000F                       ;01A25B|290F00  |      ;
                       ASL A                               ;01A25E|0A      |      ;
                       TAX                                 ;01A25F|AA      |      ;
                       LDA.L DATA8_0CD727,X                ;01A260|BF27D70C|0CD727;
                       STA.W $19E0                        ;01A264|8DE019  |0119E0;

; ==============================================================================
; Sound Channel Buffer Initialization
; Clears all audio memory buffers for battle sound effects
; ==============================================================================

CODE_01A267:
                       REP #$30                           ;01A267|C230    |      ;
                       LDA.W #$0000                       ;01A269|A90000  |      ;
                       STA.L $7FCED8                      ;01A26C|8FD8CE7F|7FCED8;
                       STA.L $7FCEDA                      ;01A270|8FDACE7F|7FCEDA;
                       STA.L $7FCEDC                      ;01A274|8FDCCE7F|7FCEDC;
                       STA.L $7FCEDE                      ;01A278|8FDECE7F|7FCEDE;
                       STA.L $7FCEE0                      ;01A27C|8FE0CE7F|7FCEE0;
                       STA.L $7FCEE2                      ;01A280|8FE2CE7F|7FCEE2;
                       STA.L $7FCEE4                      ;01A284|8FE4CE7F|7FCEE4;
                       STA.L $7FCEE6                      ;01A288|8FE6CE7F|7FCEE6;
                       STA.L $7FCEE8                      ;01A28C|8FE8CE7F|7FCEE8;
                       STA.L $7FCEEA                      ;01A290|8FEACE7F|7FCEEA;
                       STA.L $7FCEEC                      ;01A294|8FECCE7F|7FCEEC;
                       STA.L $7FCEEE                      ;01A298|8FEECE7F|7FCEEE;
                       STA.L $7FCEF0                      ;01A29C|8FF0CE7F|7FCEF0;
                       STA.L $7FCEF2                      ;01A2A0|8FF2CE7F|7FCEF2;
                       PLP                                 ;01A2A4|28      |      ;
                       RTS                                 ;01A2A5|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 2)
; Advanced Sound Effect Processing and Graphics Animation
; ==============================================================================

; ==============================================================================
; Primary Sound Effect Processing System
; Complex sound channel management with battle coordination and timing
; ==============================================================================

CODE_01A2A6:
                       PHB                                 ;01A2A6|8B      |      ;
                       PHP                                 ;01A2A7|08      |      ;
                       PHD                                 ;01A2A8|0B      |      ;
                       SEP #$20                           ;01A2A9|E220    |      ;
                       REP #$10                           ;01A2AB|C210    |      ;
                       LDA.W $19DF                        ;01A2AD|ADDF19  |0119DF;
                       CMP.B #$FF                         ;01A2B0|C9FF    |      ;
                       BEQ CODE_01A2C9                     ;01A2B2|F015    |01A2C9;
                       PEA.W $1CD7                        ;01A2B4|F4D71C  |011CD7;
                       PLD                                 ;01A2B7|2B      |      ;
                       LDY.W #$0007                       ;01A2B8|A00700  |      ;
                       STY.B $06                          ;01A2BB|8406    |001CDD;
                       LDX.W #$0000                       ;01A2BD|A20000  |      ;
                       STX.B $00                          ;01A2C0|8600    |001CD7;
                       LDX.W $19DE                        ;01A2C2|AEDE19  |0119DE;
                       STX.B $02                          ;01A2C5|8602    |001CD9;
                       BPL CODE_01A2CD                     ;01A2C7|1004    |01A2CD;

CODE_01A2C9:
                       PLD                                 ;01A2C9|2B      |      ;
                       PLP                                 ;01A2CA|28      |      ;
                       PLB                                 ;01A2CB|AB      |      ;
                       RTS                                 ;01A2CC|60      |      ;

; ==============================================================================
; Sound Data Processing Loop
; Main audio processing routine with data validation and channel management
; ==============================================================================

CODE_01A2CD:
                       SEP #$20                           ;01A2CD|E220    |      ;
                       REP #$10                           ;01A2CF|C210    |      ;
                       LDX.B $02                          ;01A2D1|A602    |001CD9;
                       LDA.L DATA8_0CD694,X                ;01A2D3|BF94D60C|0CD694;
                       CMP.B #$FF                         ;01A2D7|C9FF    |      ;
                       BEQ CODE_01A32E                     ;01A2D9|F053    |01A32E;
                       STA.B $04                          ;01A2DB|8504    |001CDB;
                       LDX.B $00                          ;01A2DD|A600    |001CD7;
                       LDA.L $7FCED8,X                    ;01A2DF|BFD8CE7F|7FCED8;
                       CMP.B $04                          ;01A2E3|C504    |001CDB;
                       BCC CODE_01A32E                     ;01A2E5|9047    |01A32E;
                       LDA.B #$00                         ;01A2E7|A900    |      ;
                       STA.L $7FCED8,X                    ;01A2E9|9FD8CE7F|7FCED8;
                       XBA                                 ;01A2ED|EB      |      ;
                       LDA.L $7FCED9,X                    ;01A2EE|BFD9CE7F|7FCED9;
                       REP #$30                           ;01A2F2|C230    |      ;
                       CLC                                 ;01A2F4|18      |      ;
                       ADC.B $02                          ;01A2F5|6502    |001CD9;
                       INC A                               ;01A2F7|1A      |      ;
                       INC A                               ;01A2F8|1A      |      ;
                       TAX                                 ;01A2F9|AA      |      ;
                       LDA.L DATA8_0CD694,X                ;01A2FA|BF94D60C|0CD694;
                       AND.W #$00FF                       ;01A2FE|29FF00  |      ;
                       ASL A                               ;01A301|0A      |      ;
                       TAX                                 ;01A302|AA      |      ;
                       LDA.L DATA8_058A80,X                ;01A303|BF808A05|058A80;
                       LDX.B $00                          ;01A307|A600    |001CD7;
                       STA.L $7FC5FA,X                    ;01A309|9FFAC57F|7FC5FA;
                       SEP #$20                           ;01A30D|E220    |      ;
                       REP #$10                           ;01A30F|C210    |      ;
                       LDX.B $00                          ;01A311|A600    |001CD7;
                       LDA.L $7FCED9,X                    ;01A313|BFD9CE7F|7FCED9;
                       INC A                               ;01A317|1A      |      ;
                       STA.B $04                          ;01A318|8504    |001CDB;
                       PHX                                 ;01A31A|DA      |      ;
                       LDX.B $02                          ;01A31B|A602    |001CD9;
                       LDA.L DATA8_0CD695,X                ;01A31D|BF95D60C|0CD695;
                       CMP.B $04                          ;01A321|C504    |001CDB;
                       BCS CODE_01A327                     ;01A323|B002    |01A327;
                       STZ.B $04                          ;01A325|6404    |001CDB;

CODE_01A327:
                       PLX                                 ;01A327|FA      |      ;
                       LDA.B $04                          ;01A328|A504    |001CDB;
                       STA.L $7FCED9,X                    ;01A32A|9FD9CE7F|7FCED9;

; ==============================================================================
; Audio Channel Iterator and Data Validation
; Advances to next sound channel and validates data integrity
; ==============================================================================

CODE_01A32E:
                       DEC.B $06                          ;01A32E|C606    |001CDD;
                       BNE CODE_01A335                     ;01A330|D003    |01A335;
                       JMP.W CODE_01A2C9                   ;01A332|4CC9A2  |01A2C9;

CODE_01A335:
                       LDX.B $00                          ;01A335|A600    |001CD7;
                       INX                                 ;01A337|E8      |      ;
                       INX                                 ;01A338|E8      |      ;
                       STX.B $00                          ;01A339|8600    |001CD7;
                       LDX.B $02                          ;01A33B|A602    |001CD9;

CODE_01A33D:
                       LDA.L DATA8_0CD694,X                ;01A33D|BF94D60C|0CD694;
                       INX                                 ;01A341|E8      |      ;
                       CMP.B #$FF                         ;01A342|C9FF    |      ;
                       BNE CODE_01A33D                     ;01A344|D0F7    |01A33D;
                       STX.B $02                          ;01A346|8602    |001CD9;
                       JMP.W CODE_01A2CD                   ;01A348|4CCDA2  |01A2CD;

; ==============================================================================
; Secondary Sound Effect Processing System
; Alternate sound channel processing for complex multi-layer audio
; ==============================================================================

CODE_01A34B:
                       PHB                                 ;01A34B|8B      |      ;
                       PHP                                 ;01A34C|08      |      ;
                       PHD                                 ;01A34D|0B      |      ;
                       SEP #$20                           ;01A34E|E220    |      ;
                       REP #$10                           ;01A350|C210    |      ;
                       LDA.W $19E1                        ;01A352|ADE119  |0119E1;
                       CMP.B #$FF                         ;01A355|C9FF    |      ;
                       BEQ CODE_01A36E                     ;01A357|F015    |01A36E;
                       PEA.W $1CD7                        ;01A359|F4D71C  |011CD7;
                       PLD                                 ;01A35C|2B      |      ;
                       LDY.W #$0007                       ;01A35D|A00700  |      ;
                       STY.B $06                          ;01A360|8406    |001CDD;
                       LDX.W #$0000                       ;01A362|A20000  |      ;
                       STX.B $00                          ;01A365|8600    |001CD7;
                       LDX.W $19E0                        ;01A367|AEE019  |0119E0;
                       STX.B $02                          ;01A36A|8602    |001CD9;
                       BPL CODE_01A372                     ;01A36C|1004    |01A372;

CODE_01A36E:
                       PLD                                 ;01A36E|2B      |      ;
                       PLP                                 ;01A36F|28      |      ;
                       PLB                                 ;01A370|AB      |      ;
                       RTS                                 ;01A371|60      |      ;

; ==============================================================================
; Secondary Audio Data Processing
; Mirror of primary system for layered audio effects during battle
; ==============================================================================

CODE_01A372:
                       SEP #$20                           ;01A372|E220    |      ;
                       REP #$10                           ;01A374|C210    |      ;
                       LDX.B $02                          ;01A376|A602    |001CD9;
                       LDA.L DATA8_0CD72F,X                ;01A378|BF2FD70C|0CD72F;
                       CMP.B #$FF                         ;01A37C|C9FF    |      ;
                       BEQ CODE_01A3D3                     ;01A37E|F053    |01A3D3;
                       STA.B $04                          ;01A380|8504    |001CDB;
                       LDX.B $00                          ;01A382|A600    |001CD7;
                       LDA.L $7FCEE6,X                    ;01A384|BFE6CE7F|7FCEE6;
                       CMP.B $04                          ;01A388|C504    |001CDB;
                       BCC CODE_01A3D3                     ;01A38A|9047    |01A3D3;
                       LDA.B #$00                         ;01A38C|A900    |      ;
                       STA.L $7FCEE6,X                    ;01A38E|9FE6CE7F|7FCEE6;
                       XBA                                 ;01A392|EB      |      ;
                       LDA.L $7FCEE7,X                    ;01A393|BFE7CE7F|7FCEE7;
                       REP #$30                           ;01A397|C230    |      ;
                       CLC                                 ;01A399|18      |      ;
                       ADC.B $02                          ;01A39A|6502    |001CD9;
                       INC A                               ;01A39C|1A      |      ;
                       INC A                               ;01A39D|1A      |      ;
                       TAX                                 ;01A39E|AA      |      ;
                       LDA.L DATA8_0CD72F,X                ;01A39F|BF2FD70C|0CD72F;
                       AND.W #$00FF                       ;01A3A3|29FF00  |      ;
                       ASL A                               ;01A3A6|0A      |      ;
                       TAX                                 ;01A3A7|AA      |      ;
                       LDA.L DATA8_058A80,X                ;01A3A8|BF808A05|058A80;
                       LDX.B $00                          ;01A3AC|A600    |001CD7;
                       STA.L $7FC52A,X                    ;01A3AE|9F2AC57F|7FC52A;
                       SEP #$20                           ;01A3B2|E220    |      ;
                       REP #$10                           ;01A3B4|C210    |      ;
                       LDX.B $00                          ;01A3B6|A600    |001CD7;
                       LDA.L $7FCEE7,X                    ;01A3B8|BFE7CE7F|7FCEE7;
                       INC A                               ;01A3BC|1A      |      ;
                       STA.B $04                          ;01A3BD|8504    |001CDB;
                       PHX                                 ;01A3BF|DA      |      ;
                       LDX.B $02                          ;01A3C0|A602    |001CD9;
                       LDA.L DATA8_0CD730,X                ;01A3C2|BF30D70C|0CD730;
                       CMP.B $04                          ;01A3C6|C504    |001CDB;
                       BCS CODE_01A3CC                     ;01A3C8|B002    |01A3CC;
                       STZ.B $04                          ;01A3CA|6404    |001CDB;

CODE_01A3CC:
                       PLX                                 ;01A3CC|FA      |      ;
                       LDA.B $04                          ;01A3CD|A504    |001CDB;
                       STA.L $7FCEE7,X                    ;01A3CF|9FE7CE7F|7FCEE7;

; ==============================================================================
; Secondary Audio Channel Processing
; Iterator and validation for second audio layer
; ==============================================================================

CODE_01A3D3:
                       DEC.B $06                          ;01A3D3|C606    |001CDD;
                       BNE CODE_01A3DA                     ;01A3D5|D003    |01A3DA;
                       JMP.W CODE_01A36E                   ;01A3D7|4C6EA3  |01A36E;

CODE_01A3DA:
                       LDX.B $00                          ;01A3DA|A600    |001CD7;
                       INX                                 ;01A3DC|E8      |      ;
                       INX                                 ;01A3DD|E8      |      ;
                       STX.B $00                          ;01A3DE|8600    |001CD7;
                       LDX.B $02                          ;01A3E0|A602    |001CD9;

CODE_01A3E2:
                       LDA.L DATA8_0CD72F,X                ;01A3E2|BF2FD70C|0CD72F;
                       INX                                 ;01A3E6|E8      |      ;
                       CMP.B #$FF                         ;01A3E7|C9FF    |      ;
                       BNE CODE_01A3E2                     ;01A3E9|D0F7    |01A3E2;
                       STX.B $02                          ;01A3EB|8602    |001CD9;
                       JMP.W CODE_01A372                   ;01A3ED|4C72A3  |01A372;

; ==============================================================================
; Main Battle Animation Controller
; Coordinates all sprite animation and graphics updates during battle
; ==============================================================================

CODE_01A3F0:
                       PHP                                 ;01A3F0|08      |      ;
                       PHB                                 ;01A3F1|8B      |      ;
                       REP #$30                           ;01A3F2|C230    |      ;
                       LDA.W $19B9                        ;01A3F4|ADB919  |0119B9;
                       BMI CODE_01A401                     ;01A3F7|3008    |01A401;
                       SEP #$20                           ;01A3F9|E220    |      ;
                       JSR.W CODE_01A423                   ;01A3FB|2023A4  |01A423;
                       JSR.W CODE_01A9EE                   ;01A3FE|20EEA9  |01A9EE;

CODE_01A401:
                       PLB                                 ;01A401|AB      |      ;
                       PLP                                 ;01A402|28      |      ;
                       RTS                                 ;01A403|60      |      ;

; ==============================================================================
; Extended Battle Animation Handler
; Enhanced animation processing with additional graphics coordination
; ==============================================================================

CODE_01A404:
                       PHP                                 ;01A404|08      |      ;
                       PHB                                 ;01A405|8B      |      ;
                       REP #$30                           ;01A406|C230    |      ;
                       LDA.W $19B9                        ;01A408|ADB919  |0119B9;
                       BMI CODE_01A420                     ;01A40B|3013    |01A420;
                       SEP #$20                           ;01A40D|E220    |      ;
                       JSR.W CODE_01A423                   ;01A40F|2023A4  |01A423;
                       JSR.W CODE_01A692                   ;01A412|2092A6  |01A692;
                       JSR.W CODE_01A947                   ;01A415|2047A9  |01A947;
                       JSR.W CODE_01A9EE                   ;01A418|20EEA9  |01A9EE;
                       SEP #$20                           ;01A41B|E220    |      ;
                       STZ.W $1A71                        ;01A41D|9C711A  |001A71;

CODE_01A420:
                       PLB                                 ;01A420|AB      |      ;
                       PLP                                 ;01A421|28      |      ;
                       RTS                                 ;01A422|60      |      ;

; ==============================================================================
; Graphics Preparation and Memory Management
; Major graphics loading system with memory initialization and data transfer
; ==============================================================================

CODE_01A423:
                       REP #$30                           ;01A423|C230    |      ;
                       PHD                                 ;01A425|0B      |      ;
                       PEA.W $192B                        ;01A426|F42B19  |01192B;
                       PLD                                 ;01A429|2B      |      ;
                       PHB                                 ;01A42A|8B      |      ;
                       LDA.W #$0000                       ;01A42B|A90000  |      ;
                       STA.L $7F0000                      ;01A42E|8F00007F|7F0000;
                       LDX.W #$0000                       ;01A432|A20000  |      ;
                       LDY.W #$0001                       ;01A435|A00100  |      ;
                       LDA.W #$3DFF                       ;01A438|A9FF3D  |      ;
                       MVN $7F,$7F                       ;01A43B|547F7F  |      ;
                       PLB                                 ;01A43E|AB      |      ;
                       SEP #$20                           ;01A43F|E220    |      ;
                       REP #$10                           ;01A441|C210    |      ;
                       LDA.B #$06                         ;01A443|A906    |      ;
                       STA.B $0A                          ;01A445|850A    |001935;
                       STZ.B $0C                          ;01A447|640C    |001937;
                       LDA.B #$0C                         ;01A449|A90C    |      ;
                       STA.B $0B                          ;01A44B|850B    |001936;
                       LDX.W #$C488                       ;01A44D|A288C4  |      ;
                       STX.B $00                          ;01A450|8600    |00192B;
                       LDY.W #$0006                       ;01A452|A00600  |      ;
                       LDX.W $19B9                        ;01A455|AEB919  |0119B9;
                       REP #$30                           ;01A458|C230    |      ;

; ==============================================================================
; Graphics Data Loading Loop
; Processes character graphics and transfers to VRAM with complex addressing
; ==============================================================================

CODE_01A45A:
                       LDA.L DATA8_0B88FC,X                ;01A45A|BFFC880B|0B88FC;
                       AND.W #$00FF                       ;01A45E|29FF00  |      ;
                       ASL A                               ;01A461|0A      |      ;
                       ASL A                               ;01A462|0A      |      ;
                       ASL A                               ;01A463|0A      |      ;
                       ASL A                               ;01A464|0A      |      ;
                       CLC                                 ;01A465|18      |      ;
                       ADC.W #$D824                       ;01A466|6924D8  |      ;
                       PHX                                 ;01A469|DA      |      ;
                       PHY                                 ;01A46A|5A      |      ;
                       PHB                                 ;01A46B|8B      |      ;
                       LDY.B $00                          ;01A46C|A400    |00192B;
                       TAX                                 ;01A46E|AA      |      ;
                       LDA.W #$000F                       ;01A46F|A90F00  |      ;
                       MVN $7F,$07                       ;01A472|547F07  |      ;
                       PLB                                 ;01A475|AB      |      ;
                       PLY                                 ;01A476|7A      |      ;
                       PLX                                 ;01A477|FA      |      ;
                       INX                                 ;01A478|E8      |      ;
                       LDA.B $00                          ;01A479|A500    |00192B;
                       CLC                                 ;01A47B|18      |      ;
                       ADC.W #$0020                       ;01A47C|692000  |      ;
                       STA.B $00                          ;01A47F|8500    |00192B;
                       DEY                                 ;01A481|88      |      ;
                       BNE CODE_01A45A                     ;01A482|D0D6    |01A45A;
                       REP #$30                           ;01A484|C230    |      ;
                       PEA.W $0004                        ;01A486|F40400  |010004;
                       PLB                                 ;01A489|AB      |      ;
                       LDA.W #$0010                       ;01A48A|A91000  |      ;
                       STA.B $14                          ;01A48D|8514    |00193F;
                       LDY.W #$E520                       ;01A48F|A020E5  |      ;
                       LDX.W #$0000                       ;01A492|A20000  |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 3)
; Advanced Graphics Memory Transfer and Animation Processing
; ==============================================================================

; ==============================================================================
; Main Graphics Memory Transfer Loop
; Large-scale graphics processing with dual memory bank coordination
; ==============================================================================

CODE_01A495:
                       REP #$30                           ;01A495|C230    |      ;
                       LDA.W #$0002                       ;01A497|A90200  |      ;
                       STA.B $16                          ;01A49A|8516    |001941;

; ==============================================================================
; Dual Memory Block Transfer Engine
; Processes 4x 16-byte blocks in parallel with complex bank switching
; ==============================================================================

CODE_01A49C:
                       LDA.W $0000,Y                      ;01A49C|B90000  |040000;
                       STA.L $7F0000,X                    ;01A49F|9F00007F|7F0000;
                       LDA.W $0002,Y                      ;01A4A3|B90200  |040002;
                       STA.L $7F0002,X                    ;01A4A6|9F02007F|7F0002;
                       LDA.W $0004,Y                      ;01A4AA|B90400  |040004;
                       STA.L $7F0004,X                    ;01A4AD|9F04007F|7F0004;
                       LDA.W $0006,Y                      ;01A4B1|B90600  |040006;
                       STA.L $7F0006,X                    ;01A4B4|9F06007F|7F0006;
                       TYA                                 ;01A4B8|98      |      ;
                       CLC                                 ;01A4B9|18      |      ;
                       ADC.W #$0008                       ;01A4BA|690800  |      ;
                       TAY                                 ;01A4BD|A8      |      ;
                       TXA                                 ;01A4BE|8A      |      ;
                       CLC                                 ;01A4BF|18      |      ;
                       ADC.W #$0008                       ;01A4C0|690800  |      ;
                       TAX                                 ;01A4C3|AA      |      ;
                       DEC.B $16                          ;01A4C4|C616    |001941;
                       BNE CODE_01A49C                     ;01A4C6|D0D4    |01A49C;
                       SEP #$20                           ;01A4C8|E220    |      ;
                       REP #$10                           ;01A4CA|C210    |      ;
                       LDA.B #$08                         ;01A4CC|A908    |      ;
                       STA.B $18                          ;01A4CE|8518    |001943;

; ==============================================================================
; Secondary Graphics Transfer with Format Conversion
; Single-byte transfer loop with automatic format conversion
; ==============================================================================

CODE_01A4D0:
                       LDA.W $0000,Y                      ;01A4D0|B90000  |040000;
                       STA.L $7F0000,X                    ;01A4D3|9F00007F|7F0000;
                       LDA.B #$00                         ;01A4D7|A900    |      ;
                       STA.L $7F0001,X                    ;01A4D9|9F01007F|7F0001;
                       INX                                 ;01A4DD|E8      |      ;
                       INX                                 ;01A4DE|E8      |      ;
                       INY                                 ;01A4DF|C8      |      ;
                       DEC.B $18                          ;01A4E0|C618    |001943;
                       BNE CODE_01A4D0                     ;01A4E2|D0EC    |01A4D0;
                       REP #$30                           ;01A4E4|C230    |      ;
                       DEC.B $14                          ;01A4E6|C614    |00193F;
                       BNE CODE_01A495                     ;01A4E8|D0AB    |01A495;
                       PLB                                 ;01A4EA|AB      |      ;

; ==============================================================================
; Character Graphics Processing Loop
; Complex sprite data processing with 16-tile character animation
; ==============================================================================

CODE_01A4EB:
                       SEP #$20                           ;01A4EB|E220    |      ;
                       REP #$10                           ;01A4ED|C210    |      ;
                       LDA.B #$80                         ;01A4EF|A980    |      ;
                       STA.B $0E                          ;01A4F1|850E    |001939;
                       LDY.W #$0008                       ;01A4F3|A00800  |      ;

CODE_01A4F6:
                       LDA.B #$00                         ;01A4F6|A900    |      ;
                       XBA                                 ;01A4F8|EB      |      ;
                       LDA.B $0A                          ;01A4F9|A50A    |001935;
                       REP #$30                           ;01A4FB|C230    |      ;
                       CLC                                 ;01A4FD|18      |      ;
                       ADC.W $19B9                        ;01A4FE|6DB919  |0119B9;
                       TAX                                 ;01A501|AA      |      ;
                       SEP #$20                           ;01A502|E220    |      ;
                       REP #$10                           ;01A504|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A506|BFFC880B|0B88FC;
                       STA.B $0D                          ;01A50A|850D    |001938;

; ==============================================================================
; Bit-Level Sprite Processing
; Processes individual sprite bits with complex masking and animation
; ==============================================================================

CODE_01A50C:
                       PHY                                 ;01A50C|5A      |      ;
                       LDA.B $0D                          ;01A50D|A50D    |001938;
                       AND.B $0E                          ;01A50F|250E    |001939;
                       BEQ CODE_01A52C                     ;01A511|F019    |01A52C;
                       LDA.B #$00                         ;01A513|A900    |      ;
                       XBA                                 ;01A515|EB      |      ;
                       LDA.B $0B                          ;01A516|A50B    |001936;
                       INC.B $0B                          ;01A518|E60B    |001936;
                       REP #$30                           ;01A51A|C230    |      ;
                       CLC                                 ;01A51C|18      |      ;
                       ADC.W $19B9                        ;01A51D|6DB919  |0119B9;
                       TAX                                 ;01A520|AA      |      ;
                       SEP #$20                           ;01A521|E220    |      ;
                       REP #$10                           ;01A523|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A525|BFFC880B|0B88FC;
                       JSR.W CODE_01A865                   ;01A529|2065A8  |01A865;

CODE_01A52C:
                       SEP #$20                           ;01A52C|E220    |      ;
                       REP #$10                           ;01A52E|C210    |      ;
                       INC.B $0C                          ;01A530|E60C    |001937;
                       LDA.B $0E                          ;01A532|A50E    |001939;
                       LSR A                               ;01A534|4A      |      ;
                       STA.B $0E                          ;01A535|850E    |001939;
                       PLY                                 ;01A537|7A      |      ;
                       DEY                                 ;01A538|88      |      ;
                       BNE CODE_01A50C                     ;01A539|D0D1    |01A50C;
                       INC.B $0A                          ;01A53B|E60A    |001935;
                       LDA.B $0A                          ;01A53D|A50A    |001935;
                       CMP.B #$0C                         ;01A53F|C90C    |      ;
                       BEQ CODE_01A550                     ;01A541|F00D    |01A550;
                       CMP.B #$0B                         ;01A543|C90B    |      ;
                       BNE CODE_01A4EB                     ;01A545|D0A4    |01A4EB;
                       LDA.B #$80                         ;01A547|A980    |      ;
                       STA.B $0E                          ;01A549|850E    |001939;
                       LDY.W #$0004                       ;01A54B|A00400  |      ;
                       BRA CODE_01A4F6                     ;01A54E|80A6    |01A4F6;

; ==============================================================================
; Final Graphics Processing and Validation
; Completes character processing with special effect integration
; ==============================================================================

CODE_01A550:
                       REP #$30                           ;01A550|C230    |      ;
                       LDA.W #$000B                       ;01A552|A90B00  |      ;
                       CLC                                 ;01A555|18      |      ;
                       ADC.W $19B9                        ;01A556|6DB919  |0119B9;
                       TAX                                 ;01A559|AA      |      ;
                       SEP #$20                           ;01A55A|E220    |      ;
                       REP #$10                           ;01A55C|C210    |      ;
                       LDA.L DATA8_0B88FC,X                ;01A55E|BFFC880B|0B88FC;
                       BIT.B #$01                         ;01A562|8901    |      ;
                       BEQ CODE_01A573                     ;01A564|F00D    |01A573;
                       LDA.B #$F2                         ;01A566|A9F2    |      ;
                       JSL.L CODE_009776                   ;01A568|22769700|009776;
                       BNE CODE_01A571                     ;01A56C|D003    |01A571;
                       JSR.W CODE_01A5AA                   ;01A56E|20AAA5  |01A5AA;

CODE_01A571:
                       BRA CODE_01A5A8                     ;01A571|8035    |01A5A8;

; ==============================================================================
; Standard Graphics Transfer Mode
; Handles normal character display without special effects
; ==============================================================================

CODE_01A573:
                       LDX.W #$ADA0                       ;01A573|A2A0AD  |      ;
                       STX.B $02                          ;01A576|8602    |00192D;
                       LDA.B #$04                         ;01A578|A904    |      ;
                       STA.B $06                          ;01A57A|8506    |001931;
                       LDA.B #$7F                         ;01A57C|A97F    |      ;
                       STA.B $07                          ;01A57E|8507    |001932;
                       LDA.B #$00                         ;01A580|A900    |      ;
                       XBA                                 ;01A582|EB      |      ;
                       LDA.B $0C                          ;01A583|A50C    |001937;
                       ASL A                               ;01A585|0A      |      ;
                       TAX                                 ;01A586|AA      |      ;
                       REP #$30                           ;01A587|C230    |      ;
                       LDA.L DATA8_01A5E0,X                ;01A589|BFE0A501|01A5E0;
                       STA.B $04                          ;01A58D|8504    |00192F;
                       LDY.W #$0060                       ;01A58F|A06000  |      ;

; ==============================================================================
; Graphics Transfer Coordination Loop
; Coordinates 96 transfer operations with memory management
; ==============================================================================

CODE_01A592:
                       JSR.W CODE_01A901                   ;01A592|2001A9  |01A901;
                       LDA.B $02                          ;01A595|A502    |00192D;
                       CLC                                 ;01A597|18      |      ;
                       ADC.W #$0018                       ;01A598|691800  |      ;
                       STA.B $02                          ;01A59B|8502    |00192D;
                       LDA.B $04                          ;01A59D|A504    |00192F;
                       CLC                                 ;01A59F|18      |      ;
                       ADC.W #$0020                       ;01A5A0|692000  |      ;
                       STA.B $04                          ;01A5A3|8504    |00192F;
                       DEY                                 ;01A5A5|88      |      ;
                       BNE CODE_01A592                     ;01A5A6|D0EA    |01A592;

CODE_01A5A8:
                       PLD                                 ;01A5A8|2B      |      ;
                       RTS                                 ;01A5A9|60      |      ;

; ==============================================================================
; Special Effects Graphics Handler
; Extended graphics processing for special battle effects
; ==============================================================================

CODE_01A5AA:
                       PHP                                 ;01A5AA|08      |      ;
                       PHD                                 ;01A5AB|0B      |      ;
                       PEA.W $192B                        ;01A5AC|F42B19  |00192B;
                       PLD                                 ;01A5AF|2B      |      ;
                       LDX.W #$BE20                       ;01A5B0|A220BE  |      ;
                       STX.B $02                          ;01A5B3|8602    |00192D;
                       LDA.B #$04                         ;01A5B5|A904    |      ;
                       STA.B $06                          ;01A5B7|8506    |001931;
                       LDA.B #$7F                         ;01A5B9|A97F    |      ;
                       STA.B $07                          ;01A5BB|8507    |001932;
                       REP #$30                           ;01A5BD|C230    |      ;
                       LDA.W #$1E00                       ;01A5BF|A9001E  |      ;
                       STA.B $04                          ;01A5C2|8504    |00192F;
                       LDY.W #$0080                       ;01A5C4|A08000  |      ;

; ==============================================================================
; Extended Graphics Transfer Loop (128 Operations)
; Larger transfer cycle for complex special effects
; ==============================================================================

CODE_01A5C7:
                       JSR.W CODE_01A901                   ;01A5C7|2001A9  |01A901;
                       LDA.B $02                          ;01A5CA|A502    |00192D;
                       CLC                                 ;01A5CC|18      |      ;
                       ADC.W #$0018                       ;01A5CD|691800  |      ;
                       STA.B $02                          ;01A5D0|8502    |00192D;
                       LDA.B $04                          ;01A5D2|A504    |00192F;
                       CLC                                 ;01A5D4|18      |      ;
                       ADC.W #$0020                       ;01A5D5|692000  |      ;
                       STA.B $04                          ;01A5D8|8504    |00192F;
                       DEY                                 ;01A5DA|88      |      ;
                       BNE CODE_01A5C7                     ;01A5DB|D0EA    |01A5C7;
                       PLD                                 ;01A5DD|2B      |      ;
                       PLP                                 ;01A5DE|28      |      ;
                       RTS                                 ;01A5DF|60      |      ;

; ==============================================================================
; Graphics Configuration Data Tables
; Complex addressing tables for multi-bank graphics coordination
; ==============================================================================

DATA8_01A5E0:
                       db $00,$02,$80,$02,$00,$03,$80,$03,$00,$04,$00,$06,$00,$0E,$00,$16 ; 01A5E0
                       db $00,$08,$80,$08,$00,$09,$80,$09,$00,$0A,$80,$0A,$00,$0B,$80,$0B ; 01A5F0
                       db $00,$0C                        ; 01A600
                       db $80,$0C,$00,$0D,$80,$0D    ; 01A602
                       db $00,$10,$80,$10,$00,$11,$80,$11,$00,$12,$80,$12,$00,$13,$80,$13 ; 01A608
                       db $00,$14                        ; 01A618
                       db $80,$14,$00,$15,$80,$15    ; 01A61A
                       db $00,$18,$80,$18,$00,$19,$80,$19,$00,$1A ; 01A620
                       db $80,$1A,$00,$1B              ; 01A62A
                       db $80,$1B,$00,$1C              ; 01A62E
                       db $80,$1C,$00,$1D,$80,$1D    ; 01A632
                       db $00,$1E                        ; 01A638

; ==============================================================================
; OAM Configuration Tables
; Sprite positioning and attribute data for battle system
; ==============================================================================

DATA8_01A63A:
                       db $80,$00                        ; 01A63A

DATA8_01A63C:
                       db $08,$02,$90,$00,$09,$02,$A0,$00,$0A,$02,$B0,$00,$0B,$02,$E0,$00 ; 01A63C
                       db $0E,$02,$F0,$00,$0F,$02,$00,$01,$10,$02,$10,$01,$11,$02,$20,$01 ; 01A64C
                       db $12,$02,$30,$01,$13,$02,$40,$01,$14,$02,$50,$01,$15,$02,$60,$01 ; 01A65C
                       db $16,$02,$70,$01,$17,$02,$80,$01,$18,$02,$90,$01,$19,$02,$A0,$01 ; 01A66C
                       db $1A,$02,$B0,$01,$1B,$02,$C0,$01,$1C,$02,$D0,$01,$1D,$02,$E0,$01 ; 01A67C
                       db $1E,$02,$F0,$01,$1F,$02    ; 01A68C

; ==============================================================================
; Main Sprite Engine Initialization
; Sets up sprite management system with memory allocation and coordination
; ==============================================================================

CODE_01A692:
                       SEP #$20                           ;01A692|E220    |      ;
                       REP #$10                           ;01A694|C210    |      ;
                       PHD                                 ;01A696|0B      |      ;
                       PEA.W $1A72                        ;01A697|F4721A  |001A72;
                       PLD                                 ;01A69A|2B      |      ;
                       LDX.W #$0000                       ;01A69B|A20000  |      ;
                       STX.W $1939                        ;01A69E|8E3919  |001939;
                       JSR.W CODE_01AF56                   ;01A6A1|2056AF  |01AF56;
                       SEP #$20                           ;01A6A4|E220    |      ;
                       REP #$10                           ;01A6A6|C210    |      ;
                       LDA.B #$FF                         ;01A6A8|A9FF    |      ;
                       STA.W $193B                        ;01A6AA|8D3B19  |00193B;
                       LDA.B #$08                         ;01A6AD|A908    |      ;
                       STA.W $1935                        ;01A6AF|8D3519  |001935;

; ==============================================================================
; Sprite Data Processing Loop
; Processes all active sprites with validation and coordinate processing
; ==============================================================================

CODE_01A6B2:
                       SEP #$20                           ;01A6B2|E220    |      ;
                       REP #$10                           ;01A6B4|C210    |      ;
                       INC.W $193B                        ;01A6B6|EE3B19  |00193B;
                       LDA.W $1935                        ;01A6B9|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A6BC|20DD90  |0190DD;
                       CMP.B #$FF                         ;01A6BF|C9FF    |      ;
                       BEQ CODE_01A6F0                     ;01A6C1|F02D    |01A6F0;
                       JSR.W CODE_01A6F2                   ;01A6C3|20F2A6  |01A6F2;
                       BCS CODE_01A6E1                     ;01A6C6|B019    |01A6E1;
                       REP #$30                           ;01A6C8|C230    |      ;
                       LDX.W $1939                        ;01A6CA|AE3919  |001939;
                       LDA.B $01,X                        ;01A6CD|B501    |001A73;
                       STA.B $03,X                        ;01A6CF|9503    |001A75;
                       STA.B $05,X                        ;01A6D1|9505    |001A77;
                       STA.B $07,X                        ;01A6D3|9507    |001A79;
                       LDA.W $1939                        ;01A6D5|AD3919  |001939;
                       CLC                                 ;01A6D8|18      |      ;
                       ADC.W #$001A                       ;01A6D9|691A00  |      ;
                       STA.W $1939                        ;01A6DC|8D3919  |001939;
                       BRA CODE_01A6B2                     ;01A6DF|80D1    |01A6B2;

CODE_01A6E1:
                       SEP #$20                           ;01A6E1|E220    |      ;
                       REP #$10                           ;01A6E3|C210    |      ;
                       LDA.W $1935                        ;01A6E5|AD3519  |001935;
                       CLC                                 ;01A6E8|18      |      ;
                       ADC.B #$07                         ;01A6E9|6907    |      ;
                       STA.W $1935                        ;01A6EB|8D3519  |001935;
                       BRA CODE_01A6B2                     ;01A6EE|80C2    |01A6B2;

CODE_01A6F0:
                       PLD                                 ;01A6F0|2B      |      ;
                       RTS                                 ;01A6F1|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 4)
; Complex Character Processing and Graphics Coordination
; ==============================================================================

; ==============================================================================
; Advanced Character Data Processing System
; Complex sprite validation and coordinate transformation
; ==============================================================================

CODE_01A6F2:
                       STZ.W $1948                        ;01A6F2|9C4819  |001948;
                       JSR.W CODE_01B078                   ;01A6F5|2078B0  |01B078;
                       BCC CODE_01A6FC                     ;01A6F8|9002    |01A6FC;
                       SEC                                 ;01A6FA|38      |      ;
                       RTS                                 ;01A6FB|60      |      ;

; ==============================================================================
; Character Sprite Initialization
; Sets up complete character data structures with coordinate processing
; ==============================================================================

CODE_01A6FC:
                       SEP #$20                           ;01A6FC|E220    |      ;
                       REP #$10                           ;01A6FE|C210    |      ;
                       LDX.W $1939                        ;01A700|AE3919  |001939;
                       STZ.B $00,X                        ;01A703|7400    |001A72;
                       LDA.W $193B                        ;01A705|AD3B19  |00193B;
                       STA.B $19,X                        ;01A708|9519    |001A8B;
                       INC.W $1935                        ;01A70A|EE3519  |001935;
                       LDA.W $1935                        ;01A70D|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A710|20DD90  |0190DD;
                       STA.B $0F,X                        ;01A713|950F    |001A81;
                       INC.W $1935                        ;01A715|EE3519  |001935;
                       LDA.W $1935                        ;01A718|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A71B|20DD90  |0190DD;
                       STA.W $193F                        ;01A71E|8D3F19  |00193F;
                       AND.B #$3F                         ;01A721|293F    |      ;
                       STA.B $0C,X                        ;01A723|950C    |001A7E;
                       INC.W $1935                        ;01A725|EE3519  |001935;
                       LDA.W $1935                        ;01A728|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A72B|20DD90  |0190DD;
                       STA.W $192B                        ;01A72E|8D2B19  |00192B;
                       AND.B #$3F                         ;01A731|293F    |      ;
                       STA.B $0B,X                        ;01A733|950B    |001A7D;
                       LDA.W $192B                        ;01A735|AD2B19  |00192B;
                       AND.B #$C0                         ;01A738|29C0    |      ;
                       LSR A                               ;01A73A|4A      |      ;
                       LSR A                               ;01A73B|4A      |      ;
                       PHA                                 ;01A73C|48      |      ;
                       LDA.W $1948                        ;01A73D|AD4819  |001948;
                       BEQ CODE_01A74A                     ;01A740|F008    |01A74A;
                       PLA                                 ;01A742|68      |      ;
                       CLC                                 ;01A743|18      |      ;
                       ADC.B #$10                         ;01A744|6910    |      ;
                       AND.B #$30                         ;01A746|2930    |      ;
                       BRA CODE_01A74B                     ;01A748|8001    |01A74B;

CODE_01A74A:
                       PLA                                 ;01A74A|68      |      ;

CODE_01A74B:
                       STA.B $0E,X                        ;01A74B|950E    |001A80;
                       INC.W $1935                        ;01A74D|EE3519  |001935;
                       LDA.W $1935                        ;01A750|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A753|20DD90  |0190DD;
                       STA.W $192B                        ;01A756|8D2B19  |00192B;
                       AND.B #$E0                         ;01A759|29E0    |      ;
                       LSR A                               ;01A75B|4A      |      ;
                       LSR A                               ;01A75C|4A      |      ;
                       LSR A                               ;01A75D|4A      |      ;
                       LSR A                               ;01A75E|4A      |      ;
                       STA.B $02,X                        ;01A75F|9502    |001A74;
                       STA.B $04,X                        ;01A761|9504    |001A76;
                       STA.B $06,X                        ;01A763|9506    |001A78;
                       STA.B $08,X                        ;01A765|9508    |001A7A;
                       LDA.B #$00                         ;01A767|A900    |      ;
                       XBA                                 ;01A769|EB      |      ;
                       LDA.W $192B                        ;01A76A|AD2B19  |00192B;
                       AND.B #$1F                         ;01A76D|291F    |      ;
                       STA.W $192B                        ;01A76F|8D2B19  |00192B;
                       LDA.W $193F                        ;01A772|AD3F19  |00193F;
                       AND.B #$C0                         ;01A775|29C0    |      ;
                       LSR A                               ;01A777|4A      |      ;
                       ORA.W $192B                        ;01A778|0D2B19  |00192B;
                       ASL A                               ;01A77B|0A      |      ;
                       PHX                                 ;01A77C|DA      |      ;
                       TAX                                 ;01A77D|AA      |      ;
                       LDA.L DATA8_0B87E4,X                ;01A77E|BFE4870B|0B87E4;
                       STA.W $192B                        ;01A782|8D2B19  |00192B;
                       LDA.L DATA8_0B87E5,X                ;01A785|BFE5870B|0B87E5;
                       STA.W $192C                        ;01A789|8D2C19  |00192C;
                       PLX                                 ;01A78C|FA      |      ;
                       LDA.W $192C                        ;01A78D|AD2C19  |00192C;
                       STA.B $18,X                        ;01A790|9518    |001A8A;
                       LDA.W $192B                        ;01A792|AD2B19  |00192B;
                       AND.B #$C0                         ;01A795|29C0    |      ;
                       ORA.B $0E,X                        ;01A797|150E    |001A80;
                       STA.B $0E,X                        ;01A799|950E    |001A80;
                       LDA.W $192B                        ;01A79B|AD2B19  |00192B;
                       AND.B #$3F                         ;01A79E|293F    |      ;
                       STA.B $10,X                        ;01A7A0|9510    |001A82;
                       INC.W $1935                        ;01A7A2|EE3519  |001935;
                       LDA.W $1935                        ;01A7A5|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A7A8|20DD90  |0190DD;
                       STA.W $192B                        ;01A7AB|8D2B19  |00192B;
                       AND.B #$F8                         ;01A7AE|29F8    |      ;
                       LSR A                               ;01A7B0|4A      |      ;
                       LSR A                               ;01A7B1|4A      |      ;
                       LSR A                               ;01A7B2|4A      |      ;
                       ORA.B $0D,X                        ;01A7B3|150D    |001A7F;
                       STA.B $0D,X                        ;01A7B5|950D    |001A7F;
                       LDA.W $192B                        ;01A7B7|AD2B19  |00192B;
                       AND.B #$07                         ;01A7BA|2907    |      ;
                       ORA.B $0E,X                        ;01A7BC|150E    |001A80;
                       STA.B $0E,X                        ;01A7BE|950E    |001A80;
                       INC.W $1935                        ;01A7C0|EE3519  |001935;
                       LDA.W $1935                        ;01A7C3|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A7C6|20DD90  |0190DD;
                       INC.W $1935                        ;01A7C9|EE3519  |001935;
                       STA.W $192B                        ;01A7CC|8D2B19  |00192B;
                       AND.B #$80                         ;01A7CF|2980    |      ;
                       LSR A                               ;01A7D1|4A      |      ;
                       LSR A                               ;01A7D2|4A      |      ;
                       ORA.B $0D,X                        ;01A7D3|150D    |001A7F;
                       STA.B $0D,X                        ;01A7D5|950D    |001A7F;
                       PHP                                 ;01A7D7|08      |      ;
                       REP #$30                           ;01A7D8|C230    |      ;
                       LDA.W $192B                        ;01A7DA|AD2B19  |00192B;
                       AND.W #$007F                       ;01A7DD|297F00  |      ;
                       ASL A                               ;01A7E0|0A      |      ;
                       ASL A                               ;01A7E1|0A      |      ;
                       STA.B $11,X                        ;01A7E2|9511    |001A83;
                       ORA.B $01,X                        ;01A7E4|1501    |001A73;
                       STA.B $01,X                        ;01A7E6|9501    |001A73;
                       PLP                                 ;01A7E8|28      |      ;
                       PHX                                 ;01A7E9|DA      |      ;
                       PHY                                 ;01A7EA|5A      |      ;
                       TXY                                 ;01A7EB|9B      |      ;
                       LDA.W $193B                        ;01A7EC|AD3B19  |00193B;
                       JSR.W CODE_01E1D3                   ;01A7EF|20D3E1  |01E1D3;
                       PHY                                 ;01A7F2|5A      |      ;
                       TXY                                 ;01A7F3|9B      |      ;
                       PLX                                 ;01A7F4|FA      |      ;
                       LDA.W $0F28,Y                      ;01A7F5|B9280F  |000F28;
                       BEQ CODE_01A804                     ;01A7F8|F00A    |01A804;
                       LDA.W $0F2A,Y                      ;01A7FA|B92A0F  |000F2A;
                       STA.B $0B,X                        ;01A7FD|950B    |001A7D;
                       LDA.W $0F2B,Y                      ;01A7FF|B92B0F  |000F2B;
                       STA.B $0C,X                        ;01A802|950C    |001A7E;

CODE_01A804:
                       PLY                                 ;01A804|7A      |      ;
                       PLX                                 ;01A805|FA      |      ;
                       CLC                                 ;01A806|18      |      ;
                       RTS                                 ;01A807|60      |      ;

; ==============================================================================
; Dynamic Sprite Creation System
; Creates new sprite entries dynamically during battle
; ==============================================================================

CODE_01A808:
                       PHP                                 ;01A808|08      |      ;
                       SEP #$20                           ;01A809|E220    |      ;
                       REP #$10                           ;01A80B|C210    |      ;
                       STZ.W $1948                        ;01A80D|9C4819  |011948;
                       PHP                                 ;01A810|08      |      ;
                       PEA.W $1A72                        ;01A811|F4721A  |011A72;
                       PLD                                 ;01A814|2B      |      ;
                       PHY                                 ;01A815|5A      |      ;
                       JSR.W CODE_01A6FC                   ;01A816|20FCA6  |01A6FC;
                       JSR.W CODE_01A988                   ;01A819|2088A9  |01A988;
                       PLY                                 ;01A81C|7A      |      ;
                       LDA.W #$EB00                       ;01A81D|A900EB  |      ;
                       TYA                                 ;01A820|98      |      ;
                       ASL A                               ;01A821|0A      |      ;
                       ASL A                               ;01A822|0A      |      ;
                       TAY                                 ;01A823|A8      |      ;
                       STY.W $193B                        ;01A824|8C3B19  |01193B;
                       JSR.W CODE_01AA3B                   ;01A827|203BAA  |01AA3B;
                       PLP                                 ;01A82A|28      |      ;
                       LDX.W $1939                        ;01A82B|AE3919  |011939;
                       LDA.B #$02                         ;01A82E|A902    |      ;
                       STA.W $1A72,X                      ;01A830|9D721A  |011A72;
                       PLP                                 ;01A833|28      |      ;
                       RTS                                 ;01A834|60      |      ;

; ==============================================================================
; DMA Transfer Setup and Initialization
; Configures SNES DMA channels for graphics transfer
; ==============================================================================

                       db $E2,$20,$C2,$10,$A9,$80,$8D,$15,$21,$A2,$00,$69,$8E,$16,$21,$A9 ; 01A835
                       db $01,$8D,$00,$43,$A9,$18,$8D,$01,$43,$A2,$00,$00,$8E,$02,$43,$A9 ; 01A845
                       db $7F,$8D,$04,$43,$A2,$00,$2E,$8E,$05,$43,$A9,$01,$8D,$0B,$42,$60 ; 01A855

; ==============================================================================
; Character Graphics Loader and Processor
; Complex character sprite loading with bank coordination
; ==============================================================================

CODE_01A865:
                       PHB                                 ;01A865|8B      |      ;
                       PHD                                 ;01A866|0B      |      ;
                       PEA.W $192B                        ;01A867|F42B19  |00192B;
                       PLD                                 ;01A86A|2B      |      ;
                       SEP #$20                           ;01A86B|E220    |      ;
                       REP #$10                           ;01A86D|C210    |      ;
                       STA.B $00                          ;01A86F|8500    |00192B;
                       BIT.B #$80                         ;01A871|8980    |      ;
                       BNE CODE_01A89D                     ;01A873|D028    |01A89D;
                       REP #$30                           ;01A875|C230    |      ;
                       AND.W #$007F                       ;01A877|297F00  |      ;
                       ASL A                               ;01A87A|0A      |      ;
                       ASL A                               ;01A87B|0A      |      ;
                       ASL A                               ;01A87C|0A      |      ;
                       ASL A                               ;01A87D|0A      |      ;
                       ASL A                               ;01A87E|0A      |      ;
                       ASL A                               ;01A87F|0A      |      ;
                       ASL A                               ;01A880|0A      |      ;
                       LDX.B $00                          ;01A881|A600    |00192B;
                       PHX                                 ;01A883|DA      |      ;
                       STA.B $00                          ;01A884|8500    |00192B;
                       ASL A                               ;01A886|0A      |      ;
                       CLC                                 ;01A887|18      |      ;
                       ADC.B $00                          ;01A888|6500    |00192B;
                       PLX                                 ;01A88A|FA      |      ;
                       STX.B $00                          ;01A88B|8600    |00192B;
                       CLC                                 ;01A88D|18      |      ;
                       ADC.W #$9A20                       ;01A88E|69209A  |      ;
                       STA.B $02                          ;01A891|8502    |00192D;
                       SEP #$20                           ;01A893|E220    |      ;
                       REP #$10                           ;01A895|C210    |      ;
                       LDA.B #$10                         ;01A897|A910    |      ;
                       STA.B $08                          ;01A899|8508    |001933;
                       BRA CODE_01A8BB                     ;01A89B|801E    |01A8BB;

; ==============================================================================
; Alternate Graphics Loading Path
; Handles compressed or special format character graphics
; ==============================================================================

CODE_01A89D:
                       REP #$30                           ;01A89D|C230    |      ;
                       AND.W #$007F                       ;01A89F|297F00  |      ;
                       ASL A                               ;01A8A2|0A      |      ;
                       ASL A                               ;01A8A3|0A      |      ;
                       ASL A                               ;01A8A4|0A      |      ;
                       ASL A                               ;01A8A5|0A      |      ;
                       ASL A                               ;01A8A6|0A      |      ;
                       STA.B $02                          ;01A8A7|8502    |00192D;
                       ASL A                               ;01A8A9|0A      |      ;
                       CLC                                 ;01A8AA|18      |      ;
                       ADC.B $02                          ;01A8AB|6502    |00192D;
                       CLC                                 ;01A8AD|18      |      ;
                       ADC.W #$D7A0                       ;01A8AE|69A0D7  |      ;
                       STA.B $02                          ;01A8B1|8502    |00192D;
                       SEP #$20                           ;01A8B3|E220    |      ;
                       REP #$10                           ;01A8B5|C210    |      ;
                       LDA.B #$08                         ;01A8B7|A908    |      ;
                       STA.B $08                          ;01A8B9|8508    |001933;

; ==============================================================================
; Graphics Data Transfer Coordination
; Main transfer loop with memory management and format handling
; ==============================================================================

CODE_01A8BB:
                       SEP #$20                           ;01A8BB|E220    |      ;
                       REP #$10                           ;01A8BD|C210    |      ;
                       LDA.B #$04                         ;01A8BF|A904    |      ;
                       STA.B $06                          ;01A8C1|8506    |001931;
                       LDA.B #$7F                         ;01A8C3|A97F    |      ;
                       STA.B $07                          ;01A8C5|8507    |001932;
                       LDA.B #$00                         ;01A8C7|A900    |      ;
                       XBA                                 ;01A8C9|EB      |      ;
                       LDA.B $0C                          ;01A8CA|A50C    |001937;
                       ASL A                               ;01A8CC|0A      |      ;
                       TAX                                 ;01A8CD|AA      |      ;
                       REP #$30                           ;01A8CE|C230    |      ;
                       LDA.L DATA8_01A5E0,X                ;01A8D0|BFE0A501|01A5E0;
                       STA.B $04                          ;01A8D4|8504    |00192F;

; ==============================================================================
; Iterative Graphics Transfer Loop
; Processes multiple graphics blocks with address management
; ==============================================================================

CODE_01A8D6:
                       SEP #$20                           ;01A8D6|E220    |      ;
                       REP #$10                           ;01A8D8|C210    |      ;
                       JSR.W CODE_01A901                   ;01A8DA|2001A9  |01A901;
                       LDA.B $08                          ;01A8DD|A508    |001933;
                       DEC A                               ;01A8DF|3A      |      ;
                       STA.B $08                          ;01A8E0|8508    |001933;
                       BEQ CODE_01A8FE                     ;01A8E2|F01A    |01A8FE;
                       PHA                                 ;01A8E4|48      |      ;
                       REP #$30                           ;01A8E5|C230    |      ;
                       LDA.B $02                          ;01A8E7|A502    |00192D;
                       CLC                                 ;01A8E9|18      |      ;
                       ADC.W #$0018                       ;01A8EA|691800  |      ;
                       STA.B $02                          ;01A8ED|8502    |00192D;
                       LDA.B $04                          ;01A8EF|A504    |00192F;
                       CLC                                 ;01A8F1|18      |      ;
                       ADC.W #$0020                       ;01A8F2|692000  |      ;
                       STA.B $04                          ;01A8F5|8504    |00192F;
                       SEP #$20                           ;01A8F7|E220    |      ;
                       REP #$10                           ;01A8F9|C210    |      ;
                       PLA                                 ;01A8FB|68      |      ;
                       BRA CODE_01A8D6                     ;01A8FC|80D8    |01A8D6;

CODE_01A8FE:
                       PLD                                 ;01A8FE|2B      |      ;
                       PLB                                 ;01A8FF|AB      |      ;
                       RTS                                 ;01A900|60      |      ;

; ==============================================================================
; Low-Level Graphics Transfer Engine
; Direct memory transfer with bank coordination and timing
; ==============================================================================

CODE_01A901:
                       PHB                                 ;01A901|8B      |      ;
                       PHY                                 ;01A902|5A      |      ;
                       PHP                                 ;01A903|08      |      ;
                       PHD                                 ;01A904|0B      |      ;
                       PEA.W $192B                        ;01A905|F42B19  |00192B;
                       PLD                                 ;01A908|2B      |      ;
                       REP #$30                           ;01A909|C230    |      ;
                       PHB                                 ;01A90B|8B      |      ;
                       LDX.B $02                          ;01A90C|A602    |00192D;
                       LDY.B $04                          ;01A90E|A404    |00192F;
                       LDA.W #$000F                       ;01A910|A90F00  |      ;
                       MVN $7F,$04                       ;01A913|547F04  |      ;
                       PLB                                 ;01A916|AB      |      ;
                       SEP #$20                           ;01A917|E220    |      ;
                       REP #$10                           ;01A919|C210    |      ;
                       LDA.B #$08                         ;01A91B|A908    |      ;
                       STA.B $01                          ;01A91D|8501    |00192C;

; ==============================================================================
; Byte-Level Transfer with Bank Switching
; Processes individual bytes with complex bank management
; ==============================================================================

CODE_01A91F:
                       PHB                                 ;01A91F|8B      |      ;
                       LDA.B $06                          ;01A920|A506    |001931;
                       PHA                                 ;01A922|48      |      ;
                       PLB                                 ;01A923|AB      |      ;
                       LDA.W $0000,X                      ;01A924|BD0000  |040000;
                       INX                                 ;01A927|E8      |      ;
                       PHA                                 ;01A928|48      |      ;
                       LDA.B $07                          ;01A929|A507    |001932;
                       PHA                                 ;01A92B|48      |      ;
                       PLB                                 ;01A92C|AB      |      ;
                       PLA                                 ;01A92D|68      |      ;
                       XBA                                 ;01A92E|EB      |      ;
                       LDA.B #$00                         ;01A92F|A900    |      ;
                       XBA                                 ;01A931|EB      |      ;
                       REP #$30                           ;01A932|C230    |      ;
                       STA.W $0000,Y                      ;01A934|990000  |7F0000;
                       INY                                 ;01A937|C8      |      ;
                       INY                                 ;01A938|C8      |      ;
                       SEP #$20                           ;01A939|E220    |      ;
                       REP #$10                           ;01A93B|C210    |      ;
                       PLB                                 ;01A93D|AB      |      ;
                       DEC.B $01                          ;01A93E|C601    |00192C;
                       BNE CODE_01A91F                     ;01A940|D0DD    |01A91F;
                       PLD                                 ;01A942|2B      |      ;
                       PLP                                 ;01A943|28      |      ;
                       PLY                                 ;01A944|7A      |      ;
                       PLB                                 ;01A945|AB      |      ;
                       RTS                                 ;01A946|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 3, Part 1)
; Advanced Battle Menu and Data Management Systems
; ==============================================================================

; ==============================================================================
; Character Data Verification System
; Validates character structures and sprite data integrity
; ==============================================================================

CODE_01A947:
                       PHP                                 ;01A947|08      |      ;
                       SEP #$20                           ;01A948|E220    |      ;
                       REP #$10                           ;01A94A|C210    |      ;
                       LDA.W $1948                        ;01A94C|AD4819  |001948;
                       BNE CODE_01A957                     ;01A94F|D006    |01A957;
                       JSR.W CODE_019168                   ;01A951|206891  |019168;
                       JMP.W CODE_01A95A                   ;01A954|4C5AA9  |01A95A;

CODE_01A957:
                       JSR.W CODE_0192AC                   ;01A957|20AC92  |0192AC;

CODE_01A95A:
                       PLP                                 ;01A95A|28      |      ;
                       RTS                                 ;01A95B|60      |      ;

; ==============================================================================
; Sprite Data Block Validation
; Ensures sprite data integrity across memory banks
; ==============================================================================

CODE_01A95C:
                       PHB                                 ;01A95C|8B      |      ;
                       PHY                                 ;01A95D|5A      |      ;
                       PHP                                 ;01A95E|08      |      ;
                       PHD                                 ;01A95F|0B      |      ;
                       PEA.W $192B                        ;01A960|F42B19  |00192B;
                       PLD                                 ;01A963|2B      |      ;
                       REP #$30                           ;01A964|C230    |      ;
                       PHB                                 ;01A966|8B      |      ;
                       LDX.B $02                          ;01A967|A602    |00192D;
                       LDY.B $04                          ;01A969|A404    |00192F;
                       LDA.W #$000F                       ;01A96B|A90F00  |      ;
                       MVN $7F,$04                       ;01A96E|547F04  |      ;
                       PLB                                 ;01A971|AB      |      ;
                       SEP #$20                           ;01A972|E220    |      ;
                       REP #$10                           ;01A974|C210    |      ;
                       LDA.B #$08                         ;01A976|A908    |      ;
                       STA.B $01                          ;01A978|8501    |00192C;

; ==============================================================================
; Byte-Level Data Validation Loop
; Validates individual sprite data bytes with format checking
; ==============================================================================

CODE_01A97A:
                       PHB                                 ;01A97A|8B      |      ;
                       LDA.B $06                          ;01A97B|A506    |001931;
                       PHA                                 ;01A97D|48      |      ;
                       PLB                                 ;01A97E|AB      |      ;
                       LDA.W $0000,X                      ;01A97F|BD0000  |040000;
                       INX                                 ;01A982|E8      |      ;
                       PHA                                 ;01A983|48      |      ;
                       LDA.B $07                          ;01A984|A507    |001932;
                       PHA                                 ;01A986|48      |      ;
                       PLB                                 ;01A987|AB      |      ;
                       PLA                                 ;01A988|68      |      ;
                       XBA                                 ;01A989|EB      |      ;
                       LDA.B #$00                         ;01A98A|A900    |      ;
                       XBA                                 ;01A98C|EB      |      ;
                       REP #$30                           ;01A98D|C230    |      ;
                       STA.W $0000,Y                      ;01A98F|990000  |7F0000;
                       INY                                 ;01A992|C8      |      ;
                       INY                                 ;01A993|C8      |      ;
                       SEP #$20                           ;01A994|E220    |      ;
                       REP #$10                           ;01A996|C210    |      ;
                       PLB                                 ;01A998|AB      |      ;
                       DEC.B $01                          ;01A999|C601    |00192C;
                       BNE CODE_01A97A                     ;01A99B|D0DD    |01A97A;
                       PLD                                 ;01A99D|2B      |      ;
                       PLP                                 ;01A99E|28      |      ;
                       PLY                                 ;01A99F|7A      |      ;
                       PLB                                 ;01A9A0|AB      |      ;
                       RTS                                 ;01A9A1|60      |      ;

; ==============================================================================
; Character Graphics Validation Engine
; Advanced validation of character sprite and animation data
; ==============================================================================

CODE_01A988:
                       PHP                                 ;01A988|08      |      ;
                       SEP #$20                           ;01A989|E220    |      ;
                       REP #$10                           ;01A98B|C210    |      ;
                       LDX.W $1939                        ;01A98D|AE3919  |001939;
                       LDA.B #$00                         ;01A990|A900    |      ;
                       STA.B $00,X                        ;01A992|7400    |001A72;
                       STA.B $01,X                        ;01A994|7401    |001A73;
                       STA.B $02,X                        ;01A996|7402    |001A74;
                       STA.B $03,X                        ;01A998|7403    |001A75;
                       STA.B $04,X                        ;01A99A|7404    |001A76;
                       STA.B $05,X                        ;01A99C|7405    |001A77;
                       STA.B $06,X                        ;01A99E|7406    |001A78;
                       STA.B $07,X                        ;01A9A0|7407    |001A79;
                       STA.B $08,X                        ;01A9A2|7408    |001A7A;
                       STA.B $09,X                        ;01A9A4|7409    |001A7B;
                       STA.B $0A,X                        ;01A9A6|740A    |001A7C;
                       STA.B $0B,X                        ;01A9A8|740B    |001A7D;
                       STA.B $0C,X                        ;01A9AA|740C    |001A7E;
                       STA.B $0D,X                        ;01A9AC|740D    |001A7F;
                       STA.B $0E,X                        ;01A9AE|740E    |001A80;
                       STA.B $0F,X                        ;01A9B0|740F    |001A81;
                       STA.B $10,X                        ;01A9B2|7410    |001A82;
                       STA.B $11,X                        ;01A9B4|7411    |001A83;
                       STA.B $12,X                        ;01A9B6|7412    |001A84;
                       STA.B $13,X                        ;01A9B8|7413    |001A85;
                       STA.B $14,X                        ;01A9BA|7414    |001A86;
                       STA.B $15,X                        ;01A9BC|7415    |001A87;
                       STA.B $16,X                        ;01A9BE|7416    |001A88;
                       STA.B $17,X                        ;01A9C0|7417    |001A89;
                       STA.B $18,X                        ;01A9C2|7418    |001A8A;
                       STA.B $19,X                        ;01A9C4|7419    |001A8B;
                       PLP                                 ;01A9C6|28      |      ;
                       RTS                                 ;01A9C7|60      |      ;

; ==============================================================================
; Character State Initialization
; Sets up initial character states for battle system
; ==============================================================================

CODE_01A9C8:
                       PHP                                 ;01A9C8|08      |      ;
                       SEP #$20                           ;01A9C9|E220    |      ;
                       REP #$10                           ;01A9CB|C210    |      ;
                       LDA.W $1935                        ;01A9CD|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9D0|20DD90  |0190DD;
                       LDX.W $1939                        ;01A9D3|AE3919  |001939;
                       STA.B $00,X                        ;01A9D6|7400    |001A72;
                       INC.W $1935                        ;01A9D8|EE3519  |001935;
                       LDA.W $1935                        ;01A9DB|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9DE|20DD90  |0190DD;
                       STA.B $01,X                        ;01A9E1|7401    |001A73;
                       INC.W $1935                        ;01A9E3|EE3519  |001935;
                       LDA.W $1935                        ;01A9E6|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9E9|20DD90  |0190DD;
                       STA.B $02,X                        ;01A9EC|7402    |001A74;
                       INC.W $1935                        ;01A9EE|EE3519  |001935;
                       LDA.W $1935                        ;01A9F1|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A9F4|20DD90  |0190DD;
                       STA.B $03,X                        ;01A9F7|7403    |001A75;
                       INC.W $1935                        ;01A9F9|EE3519  |001935;
                       PLP                                 ;01A9FC|28      |      ;
                       RTS                                 ;01A9FD|60      |      ;

; ==============================================================================
; Character Animation Data Setup
; Configures animation parameters for battle characters
; ==============================================================================

CODE_01A9FE:
                       PHP                                 ;01A9FE|08      |      ;
                       SEP #$20                           ;01A9FF|E220    |      ;
                       REP #$10                           ;01AA01|C210    |      ;
                       LDA.W $1935                        ;01AA03|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA06|20DD90  |0190DD;
                       LDX.W $1939                        ;01AA09|AE3919  |001939;
                       STA.B $04,X                        ;01AA0C|7404    |001A76;
                       INC.W $1935                        ;01AA0E|EE3519  |001935;
                       LDA.W $1935                        ;01AA11|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA14|20DD90  |0190DD;
                       STA.B $05,X                        ;01AA17|7405    |001A77;
                       INC.W $1935                        ;01AA19|EE3519  |001935;
                       LDA.W $1935                        ;01AA1C|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA1F|20DD90  |0190DD;
                       STA.B $06,X                        ;01AA22|7406    |001A78;
                       INC.W $1935                        ;01AA24|EE3519  |001935;
                       LDA.W $1935                        ;01AA27|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA2A|20DD90  |0190DD;
                       STA.B $07,X                        ;01AA2D|7407    |001A79;
                       INC.W $1935                        ;01AA2F|EE3519  |001935;
                       LDA.W $1935                        ;01AA32|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA35|20DD90  |0190DD;
                       STA.B $08,X                        ;01AA38|7408    |001A7A;
                       INC.W $1935                        ;01AA3A|EE3519  |001935;
                       PLP                                 ;01AA3D|28      |      ;
                       RTS                                 ;01AA3E|60      |      ;

; ==============================================================================
; Advanced Character Parameter Setup
; Complex character data initialization with multiple parameter blocks
; ==============================================================================

CODE_01AA3B:
                       PHP                                 ;01AA3B|08      |      ;
                       SEP #$20                           ;01AA3C|E220    |      ;
                       REP #$10                           ;01AA3E|C210    |      ;
                       LDX.W $1939                        ;01AA40|AE3919  |001939;
                       LDA.W $193B                        ;01AA43|AD3B19  |00193B;
                       STA.B $19,X                        ;01AA46|9519    |001A8B;
                       LDA.B #$02                         ;01AA48|A902    |      ;
                       STA.B $00,X                        ;01AA4A|7400    |001A72;
                       LDA.B #$FF                         ;01AA4C|A9FF    |      ;
                       STA.B $01,X                        ;01AA4E|7401    |001A73;
                       STA.B $02,X                        ;01AA50|7402    |001A74;
                       STA.B $03,X                        ;01AA52|7403    |001A75;
                       STA.B $04,X                        ;01AA54|7404    |001A76;
                       STA.B $05,X                        ;01AA56|7405    |001A77;
                       STA.B $06,X                        ;01AA58|7406    |001A78;
                       STA.B $07,X                        ;01AA5A|7407    |001A79;
                       STA.B $08,X                        ;01AA5C|7408    |001A7A;
                       STA.B $09,X                        ;01AA5E|7409    |001A7B;
                       STA.B $0A,X                        ;01AA60|740A    |001A7C;
                       STA.B $0B,X                        ;01AA62|740B    |001A7D;
                       STA.B $0C,X                        ;01AA64|740C    |001A7E;
                       STA.B $0D,X                        ;01AA66|740D    |001A7F;
                       STA.B $0E,X                        ;01AA68|740E    |001A80;
                       STA.B $0F,X                        ;01AA6A|740F    |001A81;
                       STA.B $10,X                        ;01AA6C|7410    |001A82;
                       STA.B $11,X                        ;01AA6E|7411    |001A83;
                       STA.B $12,X                        ;01AA70|7412    |001A84;
                       STA.B $13,X                        ;01AA72|7413    |001A85;
                       STA.B $14,X                        ;01AA74|7414    |001A86;
                       STA.B $15,X                        ;01AA76|7415    |001A87;
                       STA.B $16,X                        ;01AA78|7416    |001A88;
                       STA.B $17,X                        ;01AA7A|7417    |001A89;
                       STA.B $18,X                        ;01AA7C|7418    |001A8A;
                       PLP                                 ;01AA7E|28      |      ;
                       RTS                                 ;01AA7F|60      |      ;

; ==============================================================================
; Sprite Coordinate Transformation Engine
; Complex coordinate mapping for battle sprite positioning
; ==============================================================================

CODE_01AA80:
                       PHP                                 ;01AA80|08      |      ;
                       SEP #$20                           ;01AA81|E220    |      ;
                       REP #$10                           ;01AA83|C210    |      ;
                       LDA.B #$00                         ;01AA85|A900    |      ;
                       XBA                                 ;01AA87|EB      |      ;
                       LDA.W $1935                        ;01AA88|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA8B|20DD90  |0190DD;
                       TAY                                 ;01AA8E|A8      |      ;
                       INC.W $1935                        ;01AA8F|EE3519  |001935;
                       LDA.W $1935                        ;01AA92|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AA95|20DD90  |0190DD;
                       XBA                                 ;01AA98|EB      |      ;
                       REP #$30                           ;01AA99|C230    |      ;
                       TYA                                 ;01AA9B|98      |      ;
                       AND.W #$00FF                       ;01AA9C|29FF00  |      ;
                       ORA.W #$7F00                       ;01AA9F|097F00  |      ;
                       STA.W $192B                        ;01AAA2|8D2B19  |00192B;
                       INC.W $1935                        ;01AAA5|EE3519  |001935;
                       LDA.W $1935                        ;01AAA8|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAAB|20DD90  |0190DD;
                       AND.W #$00FF                       ;01AAAE|29FF00  |      ;
                       ASL A                               ;01AAB1|0A      |      ;
                       TAY                                 ;01AAB2|A8      |      ;
                       LDA.W $192B                        ;01AAB3|AD2B19  |00192B;
                       STA.W $0000,Y                      ;01AAB6|990000  |7F0000;
                       INC.W $1935                        ;01AAB9|EE3519  |001935;
                       PLP                                 ;01AABC|28      |      ;
                       RTS                                 ;01AABD|60      |      ;

; ==============================================================================
; Character Battle Data Loading
; Comprehensive character data loading with validation and setup
; ==============================================================================

CODE_01AABE:
                       PHP                                 ;01AABE|08      |      ;
                       SEP #$20                           ;01AABF|E220    |      ;
                       REP #$10                           ;01AAC1|C210    |      ;
                       LDA.W $1935                        ;01AAC3|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAC6|20DD90  |0190DD;
                       LDX.W $1939                        ;01AAC9|AE3919  |001939;
                       STA.B $09,X                        ;01AACC|7409    |001A7B;
                       INC.W $1935                        ;01AACE|EE3519  |001935;
                       LDA.W $1935                        ;01AAD1|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAD4|20DD90  |0190DD;
                       STA.B $0A,X                        ;01AAD7|740A    |001A7C;
                       INC.W $1935                        ;01AAD9|EE3519  |001935;
                       LDA.W $1935                        ;01AADC|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AADF|20DD90  |0190DD;
                       STA.B $0B,X                        ;01AAE2|740B    |001A7D;
                       INC.W $1935                        ;01AAE4|EE3519  |001935;
                       LDA.W $1935                        ;01AAE7|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAEA|20DD90  |0190DD;
                       STA.B $0C,X                        ;01AAED|740C    |001A7E;
                       INC.W $1935                        ;01AAEF|EE3519  |001935;
                       LDA.W $1935                        ;01AAF2|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AAF5|20DD90  |0190DD;
                       STA.B $0D,X                        ;01AAF8|740D    |001A7F;
                       INC.W $1935                        ;01AAFA|EE3519  |001935;
                       LDA.W $1935                        ;01AAFD|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB00|20DD90  |0190DD;
                       STA.B $0E,X                        ;01AB03|740E    |001A80;
                       INC.W $1935                        ;01AB05|EE3519  |001935;
                       LDA.W $1935                        ;01AB08|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB0B|20DD90  |0190DD;
                       STA.B $0F,X                        ;01AB0E|740F    |001A81;
                       INC.W $1935                        ;01AB10|EE3519  |001935;
                       LDA.W $1935                        ;01AB13|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB16|20DD90  |0190DD;
                       STA.B $10,X                        ;01AB19|7410    |001A82;
                       INC.W $1935                        ;01AB1B|EE3519  |001935;
                       LDA.W $1935                        ;01AB1E|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB21|20DD90  |0190DD;
                       STA.B $11,X                        ;01AB24|7411    |001A83;
                       INC.W $1935                        ;01AB26|EE3519  |001935;
                       LDA.W $1935                        ;01AB29|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB2C|20DD90  |0190DD;
                       STA.B $12,X                        ;01AB2F|7412    |001A84;
                       INC.W $1935                        ;01AB31|EE3519  |001935;
                       LDA.W $1935                        ;01AB34|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB37|20DD90  |0190DD;
                       STA.B $13,X                        ;01AB3A|7413    |001A85;
                       INC.W $1935                        ;01AB3C|EE3519  |001935;
                       LDA.W $1935                        ;01AB3F|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB42|20DD90  |0190DD;
                       STA.B $14,X                        ;01AB45|7414    |001A86;
                       INC.W $1935                        ;01AB47|EE3519  |001935;
                       LDA.W $1935                        ;01AB4A|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB4D|20DD90  |0190DD;
                       STA.B $15,X                        ;01AB50|7415    |001A87;
                       INC.W $1935                        ;01AB52|EE3519  |001935;
                       LDA.W $1935                        ;01AB55|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB58|20DD90  |0190DD;
                       STA.B $16,X                        ;01AB5B|7416    |001A88;
                       INC.W $1935                        ;01AB5D|EE3519  |001935;
                       LDA.W $1935                        ;01AB60|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB63|20DD90  |0190DD;
                       STA.B $17,X                        ;01AB66|7417    |001A89;
                       INC.W $1935                        ;01AB68|EE3519  |001935;
                       LDA.W $1935                        ;01AB6B|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01AB6E|20DD90  |0190DD;
                       STA.B $18,X                        ;01AB71|7418    |001A8A;
                       INC.W $1935                        ;01AB73|EE3519  |001935;
                       PLP                                 ;01AB76|28      |      ;
                       RTS                                 ;01AB77|60      |      ;

; ==============================================================================
; Battle System Coordination Hub
; Main coordination point for battle system data management
; ==============================================================================

CODE_01AB78:
                       PHP                                 ;01AB78|08      |      ;
                       SEP #$20                           ;01AB79|E220    |      ;
                       REP #$10                           ;01AB7B|C210    |      ;
                       LDY.W $193B                        ;01AB7D|AC3B19  |00193B;
                       LDA.W $F0F0,Y                      ;01AB80|B9F0F0  |00F0F0;
                       BEQ CODE_01AB89                     ;01AB83|F004    |01AB89;
                       STA.W $1948                        ;01AB85|8D4819  |001948;
                       BRA CODE_01AB8C                     ;01AB88|8002    |01AB8C;

CODE_01AB89:
                       STZ.W $1948                        ;01AB89|9C4819  |001948;

CODE_01AB8C:
                       JSR.W CODE_01A6FC                   ;01AB8C|20FCA6  |01A6FC;
                       BCS CODE_01AB93                     ;01AB8F|B002    |01AB93;
                       PLP                                 ;01AB91|28      |      ;
                       RTS                                 ;01AB92|60      |      ;

CODE_01AB93:
                       JSR.W CODE_01A988                   ;01AB93|2088A9  |01A988;
                       JSR.W CODE_01A9C8                   ;01AB96|20C8A9  |01A9C8;
                       JSR.W CODE_01A9FE                   ;01AB99|20FEA9  |01A9FE;
                       JSR.W CODE_01AABE                   ;01AB9C|20BEAA  |01AABE;
                       JSR.W CODE_01AA80                   ;01AB9F|2080AA  |01AA80;
                       LDX.W $1939                        ;01ABA2|AE3919  |001939;
                       LDA.B #$01                         ;01ABA5|A901    |      ;
                       STA.B $00,X                        ;01ABA7|7400    |001A72;
                       PLP                                 ;01ABA9|28      |      ;
                       RTS                                 ;01ABAA|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 3, Part 2)  
; Battle Menu Management and Advanced Data Processing
; ==============================================================================

; ==============================================================================
; Battle Menu Control System
; Advanced menu handling for battle interface
; ==============================================================================

CODE_01ABAB:
                       PHP                                 ;01ABAB|08      |      ;
                       SEP #$20                           ;01ABAC|E220    |      ;
                       REP #$10                           ;01ABAE|C210    |      ;
                       LDX.W $1939                        ;01ABB0|AE3919  |001939;
                       LDA.B #$00                         ;01ABB3|A900    |      ;
                       STA.B $00,X                        ;01ABB5|7400    |001A72;
                       STA.B $01,X                        ;01ABB7|7401    |001A73;
                       STA.B $02,X                        ;01ABB9|7402    |001A74;
                       STA.B $03,X                        ;01ABBB|7403    |001A75;
                       STA.B $04,X                        ;01ABBD|7404    |001A76;
                       STA.B $05,X                        ;01ABBF|7405    |001A77;
                       STA.B $06,X                        ;01ABC1|7406    |001A78;
                       STA.B $07,X                        ;01ABC3|7407    |001A79;
                       STA.B $08,X                        ;01ABC5|7408    |001A7A;
                       STA.B $09,X                        ;01ABC7|7409    |001A7B;
                       STA.B $0A,X                        ;01ABC9|740A    |001A7C;
                       STA.B $0B,X                        ;01ABCB|740B    |001A7D;
                       STA.B $0C,X                        ;01ABCD|740C    |001A7E;
                       STA.B $0D,X                        ;01ABCF|740D    |001A7F;
                       STA.B $0E,X                        ;01ABD1|740E    |001A80;
                       STA.B $0F,X                        ;01ABD3|740F    |001A81;
                       STA.B $10,X                        ;01ABD5|7410    |001A82;
                       STA.B $11,X                        ;01ABD7|7411    |001A83;
                       STA.B $12,X                        ;01ABD9|7412    |001A84;
                       STA.B $13,X                        ;01ABDB|7413    |001A85;
                       STA.B $14,X                        ;01ABDD|7414    |001A86;
                       STA.B $15,X                        ;01ABDF|7415    |001A87;
                       STA.B $16,X                        ;01ABE1|7416    |001A88;
                       STA.B $17,X                        ;01ABE3|7417    |001A89;
                       STA.B $18,X                        ;01ABE5|7418    |001A8A;
                       STA.B $19,X                        ;01ABE7|7419    |001A8B;
                       PLP                                 ;01ABE9|28      |      ;
                       RTS                                 ;01ABEA|60      |      ;

; ==============================================================================
; Character Data Table Management
; Manages character data tables for battle system
; ==============================================================================

                       db $FE,$FF,$02,$00,$00,$00,$00,$00,$02,$00,$FE,$FF,$00,$00 ; 01ABEB

DATA8_01ABF9:
                       db $10                              ;01ABF9|        |      ;

CODE_01ABFA:
                       LDA.B #$1C                         ;01ABFA|A91C    |      ;
                       JSR.W CODE_01D0BB                   ;01ABFC|20BBD0  |01D0BB;
                       RTS                                 ;01ABFF|60      |      ;

; ==============================================================================  
; Battle Character Validation System
; Validates and processes battle character data structures
; ==============================================================================

CODE_01AC00:
                       LDA.W $19EE                        ;01AC00|ADEE19  |0119EE;
                       JSR.W CODE_01C589                   ;01AC03|2089C5  |01C589;
                       RTS                                 ;01AC06|60      |      ;

; ==============================================================================
; Battle Character Data Loading Engine  
; Complex character data loading with bank switching and validation
; ==============================================================================

CODE_01AC07:
                       PHB                                 ;01AC07|8B      |      ;
                       LDA.W $19EE                        ;01AC08|ADEE19  |0119EE;
                       AND.W #$00FF                       ;01AC0B|29FF00  |      ;
                       ASL A                               ;01AC0E|0A      |      ;
                       TAX                                 ;01AC0F|AA      |      ;
                       LDA.L DATA8_06BD62,X                ;01AC10|BF62BD06|06BD62;
                       TAX                                 ;01AC14|AA      |      ;
                       PHP                                 ;01AC15|08      |      ;
                       SEP #$20                           ;01AC16|E220    |      ;
                       REP #$10                           ;01AC18|C210    |      ;
                       PEA.W $7F00                        ;01AC1A|F4007F  |017F00;
                       PLB                                 ;01AC1D|AB      |      ;
                       PLB                                 ;01AC1E|AB      |      ;

; ==============================================================================
; Character Data Processing Loop
; Iterates through character data with complex validation
; ==============================================================================

CODE_01AC1F:
                       PHX                                 ;01AC1F|DA      |      ;
                       LDA.B #$00                         ;01AC20|A900    |      ;
                       XBA                                 ;01AC22|EB      |      ;
                       LDA.L DATA8_06BD78,X                ;01AC23|BF78BD06|06BD78;
                       CMP.B #$FF                         ;01AC27|C9FF    |      ;
                       BEQ CODE_01AC58                     ;01AC29|F02D    |01AC58;
                       TAY                                 ;01AC2B|A8      |      ;
                       LDA.L DATA8_06BD79,X                ;01AC2C|BF79BD06|06BD79;
                       TAX                                 ;01AC30|AA      |      ;
                       LDA.W $D0F4,X                      ;01AC31|BDF4D0  |7FD0F4;
                       STA.W $D0F4,Y                      ;01AC34|99F4D0  |7FD0F4;
                       PHP                                 ;01AC37|08      |      ;
                       REP #$30                           ;01AC38|C230    |      ;
                       JSR.W CODE_01AC5C                   ;01AC3A|205CAC  |01AC5C;
                       LDA.W $D174,X                      ;01AC3D|BD74D1  |7FD174;
                       STA.W $D174,Y                      ;01AC40|9974D1  |7FD174;
                       JSR.W CODE_01AC5C                   ;01AC43|205CAC  |01AC5C;
                       LDA.W $CEF4,X                      ;01AC46|BDF4CE  |7FCEF4;
                       STA.W $CEF4,Y                      ;01AC49|99F4CE  |7FCEF4;
                       LDA.W $CEF6,X                      ;01AC4C|BDF6CE  |7FCEF6;
                       STA.W $CEF6,Y                      ;01AC4F|99F6CE  |7FCEF6;
                       PLP                                 ;01AC52|28      |      ;
                       PLX                                 ;01AC53|FA      |      ;
                       INX                                 ;01AC54|E8      |      ;
                       INX                                 ;01AC55|E8      |      ;
                       BRA CODE_01AC1F                     ;01AC56|80C7    |01AC1F;

CODE_01AC58:
                       PLX                                 ;01AC58|FA      |      ;
                       PLP                                 ;01AC59|28      |      ;
                       PLB                                 ;01AC5A|AB      |      ;
                       RTS                                 ;01AC5B|60      |      ;

; ==============================================================================
; Character Index Transformation
; Transforms character indices for data table access
; ==============================================================================

CODE_01AC5C:
                       TYA                                 ;01AC5C|98      |      ;
                       ASL A                               ;01AC5D|0A      |      ;
                       TAY                                 ;01AC5E|A8      |      ;
                       TXA                                 ;01AC5F|8A      |      ;
                       ASL A                               ;01AC60|0A      |      ;
                       TAX                                 ;01AC61|AA      |      ;
                       RTS                                 ;01AC62|60      |      ;

; ==============================================================================
; Advanced Character System Dispatcher
; Central dispatcher for character-based battle operations
; ==============================================================================

                       db $AD,$EE,$19,$29,$FF,$00,$E2,$20,$C2,$10,$8D,$19,$19,$60 ; 01AC63

CODE_01AC71:
                       LDA.W $19EE                        ;01AC71|ADEE19  |0119EE;
                       AND.W #$00FF                       ;01AC74|29FF00  |      ;
                       ASL A                               ;01AC77|0A      |      ;
                       TAX                                 ;01AC78|AA      |      ;
                       JSR.W (UNREACH_01AC7D,X)            ;01AC79|FC7DAC  |01AC7D;
                       RTS                                 ;01AC7C|60      |      ;

; ==============================================================================
; Character System Jump Table
; Jump table for various character-based operations
; ==============================================================================

UNREACH_01AC7D:
                       db $15,$F6,$4A,$F8,$17,$B8,$29,$B8,$A5,$C3,$A5,$C3,$A5,$C3,$7D,$DA ; 01AC7D
                       db $D6,$D6,$A5,$C3,$A5,$C3,$A5,$C3,$A5,$C3,$A5,$C3,$E1,$D6,$A5,$C3 ; 01AC8D
                       db $A5,$C3,$A5,$C3,$4A,$B8,$2D,$D8,$C6,$B8,$A5,$D9,$DC,$B8,$A5,$C3 ; 01AC9D
                       db $95,$D9,$3B,$DC,$A5,$C3,$36,$F9,$0A,$F7,$E5,$B8,$0D,$B9,$35,$B9 ; 01ACAD
                       db $5D,$B9,$22,$DA,$85,$B9,$94,$B9,$A3,$B9,$B2,$B9,$1B,$D9,$86,$F6 ; 01ACBD
                       db $CE,$F7,$A5,$C3,$46,$F6,$C1,$B9,$71,$BA,$95,$F5,$D5,$F5          ; 01ACCD

; ==============================================================================
; Special Battle System Handler
; Handles special battle operations and state management
; ==============================================================================

CODE_01ACDB:
                       SEP #$20                           ;01ACDB|E220    |      ;
                       REP #$10                           ;01ACDD|C210    |      ;
                       LDA.B #$03                         ;01ACDF|A903    |      ;
                       STA.W $19F6                        ;01ACE1|8DF619  |0119F6;
                       STA.W $050B                        ;01ACE4|8D0B05  |01050B;
                       LDA.B #$F5                         ;01ACE7|A9F5    |      ;
                       STA.W $050A                        ;01ACE9|8D0A05  |01050A;
                       RTS                                 ;01ACEC|60      |      ;

; ==============================================================================
; Battle Graphics Loading System
; Complex graphics loading for battle scenes and characters
; ==============================================================================

CODE_01ACED:
                       PHB                                 ;01ACED|8B      |      ;
                       LDX.W #$02F0                       ;01ACEE|A2F002  |      ;
                       LDY.W #$C508                       ;01ACF1|A008C5  |      ;
                       PEA.W $7F00                        ;01ACF4|F4007F  |017F00;
                       PLB                                 ;01ACF7|AB      |      ;
                       PLB                                 ;01ACF8|AB      |      ;
                       LDA.W #$0008                       ;01ACF9|A90800  |      ;

; ==============================================================================
; Graphics Data Transfer Loop
; Transfers graphics data blocks with address management
; ==============================================================================

CODE_01ACFC:
                       PHA                                 ;01ACFC|48      |      ;
                       LDA.L DATA8_07D824,X                ;01ACFD|BF24D807|07D824;
                       STA.W $0000,Y                      ;01AD01|990000  |7F0000;
                       INX                                 ;01AD04|E8      |      ;
                       INX                                 ;01AD05|E8      |      ;
                       INY                                 ;01AD06|C8      |      ;
                       INY                                 ;01AD07|C8      |      ;
                       PLA                                 ;01AD08|68      |      ;
                       DEC A                               ;01AD09|3A      |      ;
                       BNE CODE_01ACFC                     ;01AD0A|D0F0    |01ACFC;
                       PLB                                 ;01AD0C|AB      |      ;
                       RTS                                 ;01AD0D|60      |      ;

; ==============================================================================
; Battle Scene Setup and Management
; Coordinates battle scene initialization and state management
; ==============================================================================

CODE_01AD0E:
                       LDX.W #$0005                       ;01AD0E|A20500  |      ;
                       STX.W $192B                        ;01AD11|8E2B19  |01192B;

CODE_01AD14:
                       JSR.W CODE_01ACED                   ;01AD14|20EDAC  |01ACED;
                       JSR.W CODE_01AD78                   ;01AD17|2078AD  |01AD78;
                       LDA.W #$0004                       ;01AD1A|A90400  |      ;
                       JSR.W CODE_01D6C4                   ;01AD1D|20C4D6  |01D6C4;
                       LDY.W #$0008                       ;01AD20|A00800  |      ;
                       LDX.W #$0000                       ;01AD23|A20000  |      ;
                       LDA.W #$FFFF                       ;01AD26|A9FFFF  |      ;

; ==============================================================================
; Memory Initialization Loop
; Initializes memory regions for battle data
; ==============================================================================

CODE_01AD29:
                       STA.L $7FC508,X                    ;01AD29|9F08C57F|7FC508;
                       INX                                 ;01AD2D|E8      |      ;
                       INX                                 ;01AD2E|E8      |      ;
                       DEY                                 ;01AD2F|88      |      ;
                       BNE CODE_01AD29                     ;01AD30|D0F7    |01AD29;
                       JSR.W CODE_01AD78                   ;01AD32|2078AD  |01AD78;
                       LDA.W #$0004                       ;01AD35|A90400  |      ;
                       JSR.W CODE_01D6C4                   ;01AD38|20C4D6  |01D6C4;
                       DEC.W $192B                        ;01AD3B|CE2B19  |01192B;
                       BNE CODE_01AD14                     ;01AD3E|D0D4    |01AD14;
                       LDX.W #$001F                       ;01AD40|A21F00  |      ;
                       STX.W $1935                        ;01AD43|8E3519  |011935;

; ==============================================================================
; Advanced Data Processing Loop
; Complex data processing with mathematical operations
; ==============================================================================

CODE_01AD46:
                       LDX.W #$0000                       ;01AD46|A20000  |      ;
                       LDY.W #$0008                       ;01AD49|A00800  |      ;

CODE_01AD4C:
                       LDA.L $7FC508,X                    ;01AD4C|BF08C57F|7FC508;
                       STA.W $192B                        ;01AD50|8D2B19  |01192B;
                       LDA.L DATA8_07DB14,X                ;01AD53|BF14DB07|07DB14;
                       STA.W $192D                        ;01AD57|8D2D19  |01192D;
                       JSR.W CODE_01D23C                   ;01AD5A|203CD2  |01D23C;
                       LDA.W $192F                        ;01AD5D|AD2F19  |01192F;
                       STA.L $7FC508,X                    ;01AD60|9F08C57F|7FC508;
                       INX                                 ;01AD64|E8      |      ;
                       INX                                 ;01AD65|E8      |      ;
                       DEY                                 ;01AD66|88      |      ;
                       BNE CODE_01AD4C                     ;01AD67|D0E3    |01AD4C;
                       JSR.W CODE_01AD78                   ;01AD69|2078AD  |01AD78;
                       LDA.W #$0004                       ;01AD6C|A90400  |      ;
                       JSR.W CODE_01D6BD                   ;01AD6F|20BDD6  |01D6BD;
                       DEC.W $1935                        ;01AD72|CE3519  |011935;
                       BNE CODE_01AD46                     ;01AD75|D0CF    |01AD46;
                       RTS                                 ;01AD77|60      |      ;

; ==============================================================================
; Battle System State Handler
; Manages battle system state transitions and timing
; ==============================================================================

CODE_01AD78:
                       PHP                                 ;01AD78|08      |      ;
                       SEP #$20                           ;01AD79|E220    |      ;
                       REP #$10                           ;01AD7B|C210    |      ;
                       JSR.W CODE_018DF3                   ;01AD7D|20F38D  |018DF3;
                       LDA.B #$01                         ;01AD80|A901    |      ;
                       STA.W $1A46                        ;01AD82|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01AD85|20F38D  |018DF3;
                       PLP                                 ;01AD88|28      |      ;
                       RTS                                 ;01AD89|60      |      ;

; ==============================================================================
; Special Effect Coordination System
; Coordinates special effects and timing for battle scenes
; ==============================================================================

CODE_01AD8A:
                       PHP                                 ;01AD8A|08      |      ;
                       SEP #$20                           ;01AD8B|E220    |      ;
                       REP #$10                           ;01AD8D|C210    |      ;
                       LDA.B #$80                         ;01AD8F|A980    |      ;
                       STA.W $050B                        ;01AD91|8D0B05  |01050B;
                       LDA.B #$81                         ;01AD94|A981    |      ;
                       STA.W $050A                        ;01AD96|8D0A05  |01050A;
                       LDA.B #$14                         ;01AD99|A914    |      ;
                       JSR.W CODE_01D6BD                   ;01AD9B|20BDD6  |01D6BD;
                       PLP                                 ;01AD9E|28      |      ;
                       RTS                                 ;01AD9F|60      |      ;

; ==============================================================================
; Battle Command Processing Hub  
; Central hub for processing battle commands and actions
; ==============================================================================

                       db $AD,$09,$06,$8D,$EE,$19,$4C,$92,$BA          ; 01ADA0

CODE_01ADA9:
                       SEP #$20                           ;01ADA9|E220    |      ;
                       REP #$10                           ;01ADAB|C210    |      ;
                       JSR.W CODE_01D2DF                   ;01ADAD|20DFD2  |01D2DF;
                       JSR.W CODE_01D35D                   ;01ADB0|205DD3  |01D35D;
                       JSR.W CODE_01D3A6                   ;01ADB3|20A6D3  |01D3A6;
                       LDX.W #$463C                       ;01ADB6|A23C46  |      ;
                       STX.W $19EE                        ;01ADB9|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADBC|20B2BE  |01BEB2;
                       LDX.W #$463D                       ;01ADBF|A23D46  |      ;
                       STX.W $19EE                        ;01ADC2|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADC5|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01ADC8|20CDD3  |01D3CD;
                       LDA.B #$0C                         ;01ADCB|A90C    |      ;
                       JSR.W CODE_01D49B                   ;01ADCD|209BD4  |01D49B;
                       RTS                                 ;01ADD0|60      |      ;

; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 4, Part 1)
; Advanced Battle UI and Special Effects Management
; ==============================================================================

; ==============================================================================
; Battle UI State Management System
; Manages battle interface states and user input processing
; ==============================================================================

CODE_01ADD1:
                       SEP #$20                           ;01ADD1|E220    |      ;
                       REP #$10                           ;01ADD3|C210    |      ;
                       JSR.W CODE_01D2DF                   ;01ADD5|20DFD2  |01D2DF;
                       JSR.W CODE_01D35D                   ;01ADD8|205DD3  |01D35D;
                       JSR.W CODE_01D3C2                   ;01ADDB|20C2D3  |01D3C2;
                       LDX.W #$4636                       ;01ADDE|A23646  |      ;
                       STX.W $19EE                        ;01ADE1|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADE4|20B2BE  |01BEB2;
                       LDX.W #$4637                       ;01ADE7|A23746  |      ;
                       STX.W $19EE                        ;01ADEA|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01ADED|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01ADF0|20CDD3  |01D3CD;
                       LDA.B #$06                         ;01ADF3|A906    |      ;
                       JSR.W CODE_01D49B                   ;01ADF5|209BD4  |01D49B;
                       RTS                                 ;01ADF8|60      |      ;

; ==============================================================================
; Special Battle Effects Coordinator
; Coordinates special visual effects and animations for battle
; ==============================================================================

CODE_01ADF9:
                       SEP #$20                           ;01ADF9|E220    |      ;
                       REP #$10                           ;01ADFB|C210    |      ;
                       JSR.W CODE_01D2DF                   ;01ADFD|20DFD2  |01D2DF;
                       JSR.W CODE_01D35D                   ;01AE00|205DD3  |01D35D;
                       JSR.W CODE_01D3C2                   ;01AE03|20C2D3  |01D3C2;
                       LDX.W #$4635                       ;01AE06|A23546  |      ;
                       STX.W $19EE                        ;01AE09|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE0C|20B2BE  |01BEB2;
                       LDX.W #$4636                       ;01AE0F|A23646  |      ;
                       STX.W $19EE                        ;01AE12|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE15|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01AE18|20CDD3  |01D3CD;
                       LDA.B #$05                         ;01AE1B|A905    |      ;
                       JSR.W CODE_01D49B                   ;01AE1D|209BD4  |01D49B;
                       RTS                                 ;01AE20|60      |      ;

; ==============================================================================
; Battle Victory Sequence Manager
; Handles victory animations and state transitions
; ==============================================================================

                       db $E2,$20,$C2,$10,$20,$DF,$D2,$20,$5D,$D3,$20,$A6,$D3,$A2,$34,$46 ; 01AE21

CODE_01AE31:
                       STX.W $19EE                        ;01AE31|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE34|20B2BE  |01BEB2;
                       LDX.W #$4635                       ;01AE37|A23546  |      ;
                       STX.W $19EE                        ;01AE3A|8EEE19  |0119EE;
                       JSR.W CODE_01BEB2                   ;01AE3D|20B2BE  |01BEB2;
                       JSR.W CODE_01D3CD                   ;01AE40|20CDD3  |01D3CD;
                       LDA.B #$04                         ;01AE43|A904    |      ;
                       JSR.W CODE_01D49B                   ;01AE45|209BD4  |01D49B;
                       RTS                                 ;01AE48|60      |      ;

; ==============================================================================
; Battle Scene Transition System
; Complex scene transition management for battle flow
; ==============================================================================

CODE_01AE49:
                       LDX.W #$0004                       ;01AE49|A20400  |      ;
                       STX.W $1935                        ;01AE4C|8E3519  |011935;
                       LDA.W #$0005                       ;01AE4F|A90500  |      ;
                       STA.W $1937                        ;01AE52|8D3719  |011937;
                       JMP.W CODE_01CCE8                   ;01AE55|4CE8CC  |01CCE8;

CODE_01AE58:
                       LDX.W #$0602                       ;01AE58|A20206  |      ;
                       STX.W $1935                        ;01AE5B|8E3519  |011935;
                       LDA.W #$0003                       ;01AE5E|A90300  |      ;
                       STA.W $1937                        ;01AE61|8D3719  |011937;
                       JMP.W CODE_01CCE8                   ;01AE64|4CE8CC  |01CCE8;

                       db $A2,$03,$07,$8E,$35,$19,$A9,$05,$00,$8D,$37,$19,$4C,$E8,$CC ; 01AE67

; ==============================================================================
; Battle Animation Control Hub
; Central hub for coordinating battle animations and timing
; ==============================================================================

CODE_01AE76:
                       SEP #$20                           ;01AE76|E220    |      ;
                       REP #$10                           ;01AE78|C210    |      ;
                       JSR.W CODE_01D120                   ;01AE7A|2020D1  |01D120;
                       BCC CODE_01AE9F                     ;01AE7D|9020    |01AE9F;
                       STZ.W $192B                        ;01AE7F|9C2B19  |01192B;
                       LDY.W #$000C                       ;01AE82|A00C00  |      ;
                       JSR.W CODE_01AEB3                   ;01AE85|20B3AE  |01AEB3;
                       LDA.B #$01                         ;01AE88|A901    |      ;
                       STA.W $192B                        ;01AE8A|8D2B19  |01192B;
                       LDY.W #$0004                       ;01AE8D|A00400  |      ;
                       JSR.W CODE_01AEB3                   ;01AE90|20B3AE  |01AEB3;
                       JSR.W CODE_01AEA0                   ;01AE93|20A0AE  |01AEA0;
                       LDX.W #$4420                       ;01AE96|A22044  |      ;
                       STX.W $19EE                        ;01AE99|8EEE19  |0119EE;
                       JSR.W CODE_01BC1B                   ;01AE9C|201BBC  |01BC1B;

CODE_01AE9F:
                       RTS                                 ;01AE9F|60      |      ;

; ==============================================================================
; Battle State Synchronization
; Synchronizes battle states between different systems
; ==============================================================================

CODE_01AEA0:
                       LDX.W $1935                        ;01AEA0|AE3519  |001935;
                       LDA.W $1938                        ;01AEA3|AD3819  |001938;
                       STA.W $1A72,X                      ;01AEA6|9D721A  |001A72;
                       LDX.W $1939                        ;01AEA9|AE3919  |001939;
                       LDA.W $193C                        ;01AEAC|AD3C19  |00193C;
                       STA.W $1A72,X                      ;01AEAF|9D721A  |001A72;
                       RTS                                 ;01AEB2|60      |      ;

; ==============================================================================
; Advanced Animation Sequence Handler
; Handles complex animation sequences with timing control
; ==============================================================================

CODE_01AEB3:
                       PHY                                 ;01AEB3|5A      |      ;
                       LDX.W $1935                        ;01AEB4|AE3519  |001935;
                       LDA.B #$10                         ;01AEB7|A910    |      ;
                       STA.W $1A72,X                      ;01AEB9|9D721A  |001A72;
                       STA.W $193D                        ;01AEBC|8D3D19  |00193D;
                       LDA.W $1A80,X                      ;01AEBF|BD801A  |001A80;
                       AND.B #$CF                         ;01AEC2|29CF    |      ;
                       STA.W $1A80,X                      ;01AEC4|9D801A  |001A80;
                       LDA.W $192B                        ;01AEC7|AD2B19  |01192B;
                       ASL A                               ;01AECA|0A      |      ;
                       ASL A                               ;01AECB|0A      |      ;
                       ASL A                               ;01AECC|0A      |      ;
                       ASL A                               ;01AECD|0A      |      ;
                       ORA.W $1A80,X                      ;01AECE|1D801A  |001A80;
                       STA.W $1A80,X                      ;01AED1|9D801A  |001A80;
                       JSR.W CODE_01CC82                   ;01AED4|2082CC  |01CC82;
                       LDX.W $1939                        ;01AED7|AE3919  |001939;
                       LDA.W $192B                        ;01AEDA|AD2B19  |01192B;
                       ORA.B #$90                         ;01AEDD|0990    |      ;
                       STA.W $1A72,X                      ;01AEDF|9D721A  |001A72;
                       STA.W $193E                        ;01AEE2|8D3E19  |00193E;
                       JSR.W CODE_01CC82                   ;01AEE5|2082CC  |01CC82;
                       PLY                                 ;01AEE8|7A      |      ;
                       LDX.W $1935                        ;01AEE9|AE3519  |001935;
                       JSR.W CODE_01AEF0                   ;01AEEC|20F0AE  |01AEF0;
                       RTS                                 ;01AEEF|60      |      ;

; ==============================================================================
; Complex Animation Loop Control
; Manages complex animation loops with frame timing
; ==============================================================================

CODE_01AEF0:
                       PHY                                 ;01AEF0|5A      |      ;
                       INC.W $19F7                        ;01AEF1|EEF719  |0119F7;

CODE_01AEF4:
                       PHX                                 ;01AEF4|DA      |      ;
                       PHP                                 ;01AEF5|08      |      ;
                       JSR.W CODE_01CAED                   ;01AEF6|20EDCA  |01CAED;
                       JSR.W CODE_0182D0                   ;01AEF9|20D082  |0182D0;
                       PLP                                 ;01AEFC|28      |      ;
                       PLX                                 ;01AEFD|FA      |      ;
                       LDA.W $1A72,X                      ;01AEFE|BD721A  |001A72;
                       BNE CODE_01AEF4                     ;01AF01|D0F1    |01AEF4;
                       PLY                                 ;01AF03|7A      |      ;
                       DEY                                 ;01AF04|88      |      ;
                       BEQ CODE_01AF25                     ;01AF05|F01E    |01AF25;
                       PHY                                 ;01AF07|5A      |      ;
                       LDX.W $1935                        ;01AF08|AE3519  |001935;
                       LDA.W $193D                        ;01AF0B|AD3D19  |00193D;
                       STA.W $1A72,X                      ;01AF0E|9D721A  |001A72;
                       JSR.W CODE_01CC82                   ;01AF11|2082CC  |01CC82;
                       LDX.W $1939                        ;01AF14|AE3919  |001939;
                       LDA.W $193E                        ;01AF17|AD3E19  |00193E;
                       STA.W $1A72,X                      ;01AF1A|9D721A  |001A72;
                       JSR.W CODE_01CC82                   ;01AF1D|2082CC  |01CC82;
                       INC.W $19F7                        ;01AF20|EEF719  |0119F7;
                       BRA CODE_01AEF4                     ;01AF23|80CF    |01AEF4;

CODE_01AF25:
                       RTS                                 ;01AF25|60      |      ;

; ==============================================================================
; Battle Input Processing System
; Advanced input processing for battle commands and navigation
; ==============================================================================

CODE_01AF26:
                       SEP #$20                           ;01AF26|E220    |      ;
                       REP #$10                           ;01AF28|C210    |      ;
                       JSR.W CODE_01D120                   ;01AF2A|2020D1  |01D120;
                       BCC CODE_01AF46                     ;01AF2D|9017    |01AF46;
                       LDA.B #$01                         ;01AF2F|A901    |      ;
                       STA.W $192B                        ;01AF31|8D2B19  |01192B;
                       LDY.W #$0003                       ;01AF34|A00300  |      ;
                       JSR.W CODE_01AEB3                   ;01AF37|20B3AE  |01AEB3;
                       STZ.W $192B                        ;01AF3A|9C2B19  |01192B;
                       LDY.W #$0002                       ;01AF3D|A00200  |      ;
                       JSR.W CODE_01AEB3                   ;01AF40|20B3AE  |01AEB3;
                       JSR.W CODE_01AEA0                   ;01AF43|20A0AE  |01AEA0;

CODE_01AF46:
                       RTS                                 ;01AF46|60      |      ;

; ==============================================================================
; Sound Effect Integration System  
; Integrates sound effects with battle events and animations
; ==============================================================================

CODE_01AF47:
                       LDA.W #$0F08                       ;01AF47|A9080F  |      ;
                       STA.W $0501                        ;01AF4A|8D0105  |010501;
                       PHP                                 ;01AF4D|08      |      ;
                       SEP #$20                           ;01AF4E|E220    |      ;
                       REP #$10                           ;01AF50|C210    |      ;
                       LDA.W $19EE                        ;01AF52|ADEE19  |0119EE;
                       AND.B #$1F                         ;01AF55|291F    |      ;
                       STA.W $0500                        ;01AF57|8D0005  |010500;
                       PLP                                 ;01AF5A|28      |      ;
                       RTS                                 ;01AF5B|60      |      ;

; ==============================================================================
; Advanced Audio Management System
; Complex audio management for battle scenes and effects
; ==============================================================================

CODE_01AF5C:
                       LDA.W $19EE                        ;01AF5C|ADEE19  |0119EE;
                       AND.W #$00FF                       ;01AF5F|29FF00  |      ;

CODE_01AF62:
                       PHX                                 ;01AF62|DA      |      ;
                       PHP                                 ;01AF63|08      |      ;
                       SEP #$20                           ;01AF64|E220    |      ;
                       REP #$10                           ;01AF66|C210    |      ;
                       LDX.W #$880F                       ;01AF68|A20F88  |      ;
                       STX.W $0506                        ;01AF6B|8E0605  |010506;
                       STA.W $0505                        ;01AF6E|8D0505  |010505;
                       PLP                                 ;01AF71|28      |      ;
                       PLX                                 ;01AF72|FA      |      ;
                       RTS                                 ;01AF73|60      |      ;

; ==============================================================================
; Battle State Control Registry
; Central registry for battle state management and coordination
; ==============================================================================

                       db $E2,$20,$C2,$10,$AD,$EE,$19,$8D,$15,$19,$60 ; 01AF74

CODE_01AF7F:
                       PHP                                 ;01AF7F|08      |      ;
                       SEP #$20                           ;01AF80|E220    |      ;
                       REP #$10                           ;01AF82|C210    |      ;
                       LDA.W $19EE                        ;01AF84|ADEE19  |0119EE;
                       STA.W $0E88                        ;01AF87|8D880E  |010E88;
                       PLP                                 ;01AF8A|28      |      ;
                       RTS                                 ;01AF8B|60      |      ;

; ==============================================================================
; Special Battle Event Handler
; Handles special battle events like critical hits and status effects
; ==============================================================================

CODE_01AF8C:
                       SEP #$20                           ;01AF8C|E220    |      ;
                       REP #$10                           ;01AF8E|C210    |      ;
                       LDA.B #$22                         ;01AF90|A922    |      ;
                       STA.W $19EF                        ;01AF92|8DEF19  |0119EF;
                       JSR.W CODE_01B73C                   ;01AF95|203CB7  |01B73C;
                       JSR.W CODE_01C6A1                   ;01AF98|20A1C6  |01C6A1;
                       RTS                                 ;01AF9B|60      |      ;

; ==============================================================================
; Advanced Battle Victory Processing
; Complex victory processing with rewards and experience calculation
; ==============================================================================

                       db $AD,$EE,$19,$29,$FF,$00,$09,$00,$23,$8D,$EE,$19,$20,$43,$B7,$20 ; 01AF9C
                       db $A1,$C6,$60                   ; 01AFAC

; ==============================================================================
; Character Validation and Setup Engine
; Comprehensive character validation with battle setup
; ==============================================================================

CODE_01AFAF:
                       SEP #$20                           ;01AFAF|E220    |      ;
                       REP #$10                           ;01AFB1|C210    |      ;
                       LDA.W $19EE                        ;01AFB3|ADEE19  |0119EE;
                       JSR.W CODE_01B1EB                   ;01AFB6|20EBB1  |01B1EB;
                       BCC CODE_01B008                     ;01AFB9|904D    |01B008;
                       STA.W $192D                        ;01AFBB|8D2D19  |01192D;
                       LDA.W $1A80,X                      ;01AFBE|BD801A  |001A80;
                       AND.B #$CF                         ;01AFC1|29CF    |      ;
                       ORA.B #$10                         ;01AFC3|0910    |      ;
                       STA.W $1A80,X                      ;01AFC5|9D801A  |001A80;
                       LDA.W $1A82,X                      ;01AFC8|BD821A  |001A82;
                       REP #$30                           ;01AFCB|C230    |      ;
                       AND.W #$00FF                       ;01AFCD|29FF00  |      ;
                       ASL A                               ;01AFD0|0A      |      ;
                       PHX                                 ;01AFD1|DA      |      ;
                       TAX                                 ;01AFD2|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01AFD3|BFCAFD00|00FDCA;
                       CLC                                 ;01AFD7|18      |      ;
                       ADC.W #$0008                       ;01AFD8|690800  |      ;
                       TAY                                 ;01AFDB|A8      |      ;
                       PLX                                 ;01AFDC|FA      |      ;
                       JSR.W CODE_01AE8A                   ;01AFDD|208AAE  |01AE8A;
                       LDA.W $192D                        ;01AFE0|AD2D19  |01192D;
                       AND.W #$00FF                       ;01AFE3|29FF00  |      ;
                       ASL A                               ;01AFE6|0A      |      ;
                       ASL A                               ;01AFE7|0A      |      ;
                       PHX                                 ;01AFE8|DA      |      ;
                       TAX                                 ;01AFE9|AA      |      ;
                       LDA.L DATA8_01A63A,X                ;01AFEA|BF3AA601|01A63A;
                       TAY                                 ;01AFEE|A8      |      ;
                       PLX                                 ;01AFEF|FA      |      ;
                       LDA.W $1A73,X                      ;01AFF0|BD731A  |001A73;
                       STA.W $0C02,Y                      ;01AFF3|99020C  |010C02;
                       LDA.W $1A75,X                      ;01AFF6|BD751A  |001A75;
                       STA.W $0C06,Y                      ;01AFF9|99060C  |010C06;
                       LDA.W $1A77,X                      ;01AFFC|BD771A  |001A77;
                       STA.W $0C0A,Y                      ;01AFFF|990A0C  |010C0A;
                       LDA.W $1A79,X                      ;01B002|BD791A  |001A79;
                       STA.W $0C0E,Y                      ;01B005|990E0C  |010C0E;

CODE_01B008:
                       RTS                                 ;01B008|60      |      ;

; ==============================================================================
; Battle Status Effect Manager
; Advanced status effect management with duration tracking
; ==============================================================================

CODE_01B009:
                       SEP #$20                           ;01B009|E220    |      ;
                       REP #$10                           ;01B00B|C210    |      ;
                       LDA.W $1916                        ;01B00D|AD1619  |001916;
                       AND.B #$E0                         ;01B010|29E0    |      ;
                       STA.W $1916                        ;01B012|8D1619  |001916;
                       LDA.W $19EE                        ;01B015|ADEE19  |0119EE;
                       AND.B #$1F                         ;01B018|291F    |      ;
                       STA.W $1916                        ;01B01A|8D1619  |001916;
                       RTS                                 ;01B01D|60      |      ;


; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 4, Part 2)
; Battle Data Processing and Coordinate Systems
; ==============================================================================

; ==============================================================================
; Battle Command Processing Hub
; Central hub for processing battle commands and coordinating actions
; ==============================================================================

CODE_01B01E:
                       SEP #$20                           ;01B01E|E220    |      ;
                       REP #$10                           ;01B020|C210    |      ;
                       LDA.W $19EE                        ;01B022|ADEE19  |0119EE;
                       JSR.W CODE_01B1EB                   ;01B025|20EBB1  |01B1EB;
                       BCC CODE_01B081                     ;01B028|9057    |01B081;
                       STA.W $192D                        ;01B02A|8D2D19  |01192D;
                       LDA.W $1A80,X                      ;01B02D|BD801A  |001A80;
                       AND.B #$CF                         ;01B030|29CF    |      ;
                       ORA.B #$20                         ;01B032|0920    |      ;
                       STA.W $1A80,X                      ;01B034|9D801A  |001A80;
                       LDA.W $1A82,X                      ;01B037|BD821A  |001A82;
                       REP #$30                           ;01B03A|C230    |      ;
                       AND.W #$00FF                       ;01B03C|29FF00  |      ;
                       ASL A                               ;01B03F|0A      |      ;
                       PHX                                 ;01B040|DA      |      ;
                       TAX                                 ;01B041|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01B042|BFCAFD00|00FDCA;
                       CLC                                 ;01B046|18      |      ;
                       ADC.W #$0010                       ;01B047|691000  |      ;
                       TAY                                 ;01B04A|A8      |      ;
                       PLX                                 ;01B04B|FA      |      ;
                       JSR.W CODE_01AE8A                   ;01B04C|208AAE  |01AE8A;
                       LDA.W $192D                        ;01B04F|AD2D19  |01192D;
                       AND.W #$00FF                       ;01B052|29FF00  |      ;
                       ASL A                               ;01B055|0A      |      ;
                       ASL A                               ;01B056|0A      |      ;
                       PHX                                 ;01B057|DA      |      ;
                       TAX                                 ;01B058|AA      |      ;
                       LDA.L DATA8_01A63A,X                ;01B059|BF3AA601|01A63A;
                       TAY                                 ;01B05D|A8      |      ;
                       PLX                                 ;01B05E|FA      |      ;
                       LDA.W $1A73,X                      ;01B05F|BD731A  |001A73;
                       STA.W $0C10,Y                      ;01B062|99100C  |010C10;
                       LDA.W $1A75,X                      ;01B065|BD751A  |001A75;
                       STA.W $0C14,Y                      ;01B068|99140C  |010C14;
                       LDA.W $1A77,X                      ;01B06B|BD771A  |001A77;
                       STA.W $0C18,Y                      ;01B06E|99180C  |010C18;
                       LDA.W $1A79,X                      ;01B071|BD791A  |001A79;
                       STA.W $0C1C,Y                      ;01B074|991C0C  |010C1C;
                       LDA.W $1A7B,X                      ;01B077|BD7B1A  |001A7B;
                       STA.W $0C20,Y                      ;01B07A|99200C  |010C20;
                       LDA.W $1A7D,X                      ;01B07D|BD7D1A  |001A7D;
                       STA.W $0C24,Y                      ;01B080|99240C  |010C24;

CODE_01B081:
                       RTS                                 ;01B081|60      |      ;

; ==============================================================================
; Advanced Character Restoration System
; Handles character restoration with complex data management
; ==============================================================================

CODE_01B082:
                       SEP #$20                           ;01B082|E220    |      ;
                       REP #$10                           ;01B084|C210    |      ;
                       LDA.W $19EE                        ;01B086|ADEE19  |0119EE;
                       AND.B #$1F                         ;01B089|291F    |      ;
                       STA.W $19EE                        ;01B08B|8DEE19  |0119EE;
                       LDA.W $19EF                        ;01B08E|ADEF19  |0119EF;
                       AND.B #$E0                         ;01B091|29E0    |      ;
                       ORA.W $19EE                        ;01B093|0DEE19  |0119EE;
                       STA.W $19EF                        ;01B096|8DEF19  |0119EF;
                       LDA.W $19EE                        ;01B099|ADEE19  |0119EE;
                       JSR.W CODE_01B1EB                   ;01B09C|20EBB1  |01B1EB;
                       BCC CODE_01B104                     ;01B09F|9063    |01B104;
                       STA.W $192D                        ;01B0A1|8D2D19  |01192D;
                       LDA.W $1A80,X                      ;01B0A4|BD801A  |001A80;
                       AND.B #$CF                         ;01B0A7|29CF    |      ;
                       ORA.B #$30                         ;01B0A9|0930    |      ;
                       STA.W $1A80,X                      ;01B0AB|9D801A  |001A80;
                       LDA.W $1A82,X                      ;01B0AE|BD821A  |001A82;
                       REP #$30                           ;01B0B1|C230    |      ;
                       AND.W #$00FF                       ;01B0B3|29FF00  |      ;
                       ASL A                               ;01B0B6|0A      |      ;
                       PHX                                 ;01B0B7|DA      |      ;
                       TAX                                 ;01B0B8|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01B0B9|BFCAFD00|00FDCA;
                       CLC                                 ;01B0BD|18      |      ;
                       ADC.W #$0018                       ;01B0BE|691800  |      ;
                       TAY                                 ;01B0C1|A8      |      ;
                       PLX                                 ;01B0C2|FA      |      ;
                       JSR.W CODE_01AE8A                   ;01B0C3|208AAE  |01AE8A;
                       LDA.W $192D                        ;01B0C6|AD2D19  |01192D;
                       AND.W #$00FF                       ;01B0C9|29FF00  |      ;
                       ASL A                               ;01B0CC|0A      |      ;
                       ASL A                               ;01B0CD|0A      |      ;
                       PHX                                 ;01B0CE|DA      |      ;
                       TAX                                 ;01B0CF|AA      |      ;
                       LDA.L DATA8_01A63A,X                ;01B0D0|BF3AA601|01A63A;
                       TAY                                 ;01B0D4|A8      |      ;
                       PLX                                 ;01B0D5|FA      |      ;
                       LDA.W $1A73,X                      ;01B0D6|BD731A  |001A73;
                       STA.W $0C28,Y                      ;01B0D9|99280C  |010C28;
                       LDA.W $1A75,X                      ;01B0DC|BD751A  |001A75;
                       STA.W $0C2C,Y                      ;01B0DF|992C0C  |010C2C;
                       LDA.W $1A77,X                      ;01B0E2|BD771A  |001A77;
                       STA.W $0C30,Y                      ;01B0E5|99300C  |010C30;
                       LDA.W $1A79,X                      ;01B0E8|BD791A  |001A79;
                       STA.W $0C34,Y                      ;01B0EB|99340C  |010C34;
                       LDA.W $1A7B,X                      ;01B0EE|BD7B1A  |001A7B;
                       STA.W $0C38,Y                      ;01B0F1|99380C  |010C38;
                       LDA.W $1A7D,X                      ;01B0F4|BD7D1A  |001A7D;
                       STA.W $0C3C,Y                      ;01B0F7|993C0C  |010C3C;
                       LDA.W $1A7F,X                      ;01B0FA|BD7F1A  |001A7F;
                       STA.W $0C40,Y                      ;01B0FD|99400C  |010C40;
                       LDA.W $1A81,X                      ;01B100|BD811A  |001A81;
                       STA.W $0C44,Y                      ;01B103|99440C  |010C44;

CODE_01B104:
                       RTS                                 ;01B104|60      |      ;

; ==============================================================================
; Graphics Coordinate System Manager
; Manages complex graphics coordinate systems for battle display
; ==============================================================================

CODE_01B105:
                       REP #$30                           ;01B105|C230    |      ;
                       LDA.W $192A                        ;01B107|AD2A19  |01192A;
                       ASL A                               ;01B10A|0A      |      ;
                       ASL A                               ;01B10B|0A      |      ;
                       ASL A                               ;01B10C|0A      |      ;
                       TAX                                 ;01B10D|AA      |      ;
                       LDA.W $1A73,X                      ;01B10E|BD731A  |001A73;
                       STA.W $193A                        ;01B111|8D3A19  |00193A;
                       LDA.W $1A75,X                      ;01B114|BD751A  |001A75;
                       STA.W $193C                        ;01B117|8D3C19  |00193C;
                       LDA.W $1A77,X                      ;01B11A|BD771A  |001A77;
                       STA.W $193E                        ;01B11D|8D3E19  |00193E;
                       LDA.W $1A79,X                      ;01B120|BD791A  |001A79;
                       STA.W $1940                        ;01B123|8D4019  |001940;
                       LDA.W $1A7B,X                      ;01B126|BD7B1A  |001A7B;
                       STA.W $1942                        ;01B129|8D4219  |001942;
                       LDA.W $1A7D,X                      ;01B12C|BD7D1A  |001A7D;
                       STA.W $1944                        ;01B12F|8D4419  |001944;
                       LDA.W $1A7F,X                      ;01B132|BD7F1A  |001A7F;
                       STA.W $1946                        ;01B135|8D4619  |001946;
                       LDA.W $1A81,X                      ;01B138|BD811A  |001A81;
                       STA.W $1948                        ;01B13B|8D4819  |001948;
                       RTS                                 ;01B13E|60      |      ;

; ==============================================================================
; Character Data Loading and Management
; Complex character data loading with battle scene management
; ==============================================================================

CODE_01B13F:
                       SEP #$20                           ;01B13F|E220    |      ;
                       REP #$10                           ;01B141|C210    |      ;
                       LDA.B #$00                         ;01B143|A900    |      ;
                       STA.W $193F                        ;01B145|8D3F19  |00193F;
                       LDA.B #$C0                         ;01B148|A9C0    |      ;
                       STA.W $1941                        ;01B14A|8D4119  |001941;
                       LDA.B #$00                         ;01B14D|A900    |      ;
                       STA.W $1943                        ;01B14F|8D4319  |001943;
                       LDA.B #$90                         ;01B152|A990    |      ;
                       STA.W $1945                        ;01B154|8D4519  |001945;
                       LDA.B #$FF                         ;01B157|A9FF    |      ;
                       STA.W $1947                        ;01B159|8D4719  |001947;
                       STA.W $1949                        ;01B15C|8D4919  |001949;
                       STA.W $194B                        ;01B15F|8D4B19  |00194B;
                       STA.W $194D                        ;01B162|8D4D19  |00194D;
                       STZ.W $1935                        ;01B165|9C3519  |001935;
                       STZ.W $1937                        ;01B168|9C3719  |001937;
                       STZ.W $1939                        ;01B16B|9C3919  |001939;
                       STZ.W $193B                        ;01B16E|9C3B19  |00193B;
                       STZ.W $193D                        ;01B171|9C3D19  |00193D;

CODE_01B174:
                       LDA.W $192A                        ;01B174|AD2A19  |01192A;
                       CMP.B #$04                         ;01B177|C904    |      ;
                       BCS CODE_01B1E9                     ;01B179|B06E    |01B1E9;
                       JSR.W CODE_01B105                   ;01B17B|2005B1  |01B105;
                       JSR.W CODE_01B18E                   ;01B17E|208EB1  |01B18E;
                       INC.W $192A                        ;01B181|EE2A19  |01192A;
                       LDA.W $1935                        ;01B184|AD3519  |001935;
                       CLC                                 ;01B187|18      |      ;
                       ADC.B #$08                         ;01B188|6908    |      ;
                       STA.W $1935                        ;01B18A|8D3519  |001935;
                       BRA CODE_01B174                     ;01B18D|80E5    |01B174;

; ==============================================================================
; Advanced Data Transfer and Coordination
; Handles advanced data transfer with multi-system coordination
; ==============================================================================

CODE_01B18E:
                       LDX.W $1935                        ;01B18E|AE3519  |001935;
                       LDA.W $193A                        ;01B191|AD3A19  |00193A;
                       STA.W $1A72,X                      ;01B194|9D721A  |001A72;
                       LDA.W $193B                        ;01B197|AD3B19  |00193B;
                       STA.W $1A73,X                      ;01B19A|9D731A  |001A73;
                       LDA.W $193C                        ;01B19D|AD3C19  |00193C;
                       STA.W $1A74,X                      ;01B1A0|9D741A  |001A74;
                       LDA.W $193D                        ;01B1A3|AD3D19  |00193D;
                       STA.W $1A75,X                      ;01B1A6|9D751A  |001A75;
                       LDA.W $193E                        ;01B1A9|AD3E19  |00193E;
                       STA.W $1A76,X                      ;01B1AC|9D761A  |001A76;
                       LDA.W $193F                        ;01B1AF|AD3F19  |00193F;
                       STA.W $1A77,X                      ;01B1B2|9D771A  |001A77;
                       LDA.W $1940                        ;01B1B5|AD4019  |001940;
                       STA.W $1A78,X                      ;01B1B8|9D781A  |001A78;
                       LDA.W $1941                        ;01B1BB|AD4119  |001941;
                       STA.W $1A79,X                      ;01B1BE|9D791A  |001A79;
                       RTS                                 ;01B1C1|60      |      ;

; ==============================================================================
; Memory Initialization Loops
; Advanced memory initialization with loop control
; ==============================================================================

CODE_01B1C2:
                       LDX.W #$0000                       ;01B1C2|A20000  |      ;

CODE_01B1C5:
                       LDA.W #$00FF                       ;01B1C5|A9FF00  |      ;
                       STA.W $1A72,X                      ;01B1C8|9D721A  |001A72;
                       INX                                 ;01B1CB|E8      |      ;
                       INX                                 ;01B1CC|E8      |      ;
                       CPX.W #$0020                       ;01B1CD|E02000  |      ;
                       BNE CODE_01B1C5                     ;01B1D0|D0F3    |01B1C5;
                       STZ.W $192A                        ;01B1D2|9C2A19  |01192A;
                       JSR.W CODE_01B13F                   ;01B1D5|203FB1  |01B13F;
                       LDX.W #$0000                       ;01B1D8|A20000  |      ;

CODE_01B1DB:
                       LDA.W #$00F0                       ;01B1DB|A9F000  |      ;
                       STA.W $1A80,X                      ;01B1DE|9D801A  |001A80;
                       INX                                 ;01B1E1|E8      |      ;
                       CPX.W #$0010                       ;01B1E2|E01000  |      ;
                       BNE CODE_01B1DB                     ;01B1E5|D0F4    |01B1DB;
                       CLC                                 ;01B1E7|18      |      ;
                       RTS                                 ;01B1E8|60      |      ;

CODE_01B1E9:
                       CLC                                 ;01B1E9|18      |      ;
                       RTS                                 ;01B1EA|60      |      ;

; ==============================================================================
; Character Validation Engine
; Advanced character validation with coordinate processing
; ==============================================================================

CODE_01B1EB:
                       AND.B #$1F                         ;01B1EB|291F    |      ;
                       CMP.B #$04                         ;01B1ED|C904    |      ;
                       BCS CODE_01B1F9                     ;01B1EF|B008    |01B1F9;
                       ASL A                               ;01B1F1|0A      |      ;
                       ASL A                               ;01B1F2|0A      |      ;
                       ASL A                               ;01B1F3|0A      |      ;
                       TAX                                 ;01B1F4|AA      |      ;
                       ORA.B #$01                         ;01B1F5|0901    |      ;
                       SEC                                 ;01B1F7|38      |      ;
                       RTS                                 ;01B1F8|60      |      ;

CODE_01B1F9:
                       CLC                                 ;01B1F9|18      |      ;
                       RTS                                 ;01B1FA|60      |      ;

; ==============================================================================
; Jump Tables and System Dispatchers
; Complex system dispatchers with jump table management
; ==============================================================================

DATA8_01B1FB:
                       dw CODE_01B20B                      ;01B1FB|0BB2    |01B20B;
                       dw CODE_01B259                      ;01B1FD|59B2    |01B259;
                       dw CODE_01B2A4                      ;01B1FF|A4B2    |01B2A4;
                       dw CODE_01B2F3                      ;01B201|F3B2    |01B2F3;
                       dw CODE_01B347                      ;01B203|47B3    |01B347;
                       dw CODE_01B39A                      ;01B205|9AB3    |01B39A;
                       dw CODE_01B3F0                      ;01B207|F0B3    |01B3F0;
                       dw CODE_01B444                      ;01B209|44B4    |01B444;

CODE_01B20B:
                       SEP #$20                           ;01B20B|E220    |      ;
                       REP #$10                           ;01B20D|C210    |      ;
                       LDA.W $19EE                        ;01B20F|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B212|290F    |      ;
                       ASL A                               ;01B214|0A      |      ;
                       TAX                                 ;01B215|AA      |      ;
                       JSR.W (DATA8_01B1FB,X)              ;01B216|FCFBB1  |01B1FB;
                       RTS                                 ;01B219|60      |      ;


; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 4, Part 3)
; Advanced Graphics Loading and System Management
; ==============================================================================

; ==============================================================================
; System Control and Event Management
; Advanced system control with complex event handling
; ==============================================================================

CODE_01B21A:
                       LDA.W $19EE                        ;01B21A|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B21D|29F0    |      ;
                       LSR A                               ;01B21F|4A      |      ;
                       LSR A                               ;01B220|4A      |      ;
                       LSR A                               ;01B221|4A      |      ;
                       TAX                                 ;01B222|AA      |      ;
                       LDA.W DATA8_01B23B,X                ;01B223|BD3BB2  |01B23B;
                       BEQ CODE_01B258                     ;01B226|F030    |01B258;
                       LDA.W $19EE                        ;01B228|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B22B|290F    |      ;
                       CMP.B #$04                         ;01B22D|C904    |      ;
                       BCS CODE_01B258                     ;01B22F|B027    |01B258;
                       ASL A                               ;01B231|0A      |      ;
                       ASL A                               ;01B232|0A      |      ;
                       ASL A                               ;01B233|0A      |      ;
                       TAX                                 ;01B234|AA      |      ;
                       LDA.W $19EE                        ;01B235|ADEE19  |0119EE;
                       STA.W $1A80,X                      ;01B238|9D801A  |001A80;

DATA8_01B23B:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B23B
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B24B

CODE_01B258:
                       RTS                                 ;01B258|60      |      ;

; ==============================================================================
; Battle Graphics Loading Engine
; Advanced graphics loading with coordinate transformation
; ==============================================================================

CODE_01B259:
                       LDA.W $19EE                        ;01B259|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B25C|29F0    |      ;
                       LSR A                               ;01B25E|4A      |      ;
                       LSR A                               ;01B25F|4A      |      ;
                       LSR A                               ;01B260|4A      |      ;
                       TAX                                 ;01B261|AA      |      ;
                       LDA.W DATA8_01B277,X                ;01B262|BD77B2  |01B277;
                       BEQ CODE_01B2A3                     ;01B265|F03C    |01B2A3;
                       LDA.W $19EE                        ;01B267|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B26A|290F    |      ;
                       CMP.B #$04                         ;01B26C|C904    |      ;
                       BCS CODE_01B2A3                     ;01B26E|B033    |01B2A3;
                       ASL A                               ;01B270|0A      |      ;
                       ASL A                               ;01B271|0A      |      ;
                       ASL A                               ;01B272|0A      |      ;
                       TAX                                 ;01B273|AA      |      ;
                       LDA.W $19EF                        ;01B274|ADEF19  |0119EF;

DATA8_01B277:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B277
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B287
                       db $9D,$81,$1A,$60             ; 01B297

; ==============================================================================
; Scene Management and State Transitions
; Complex scene management with state validation
; ==============================================================================

CODE_01B29B:
                       LDA.W $19EF                        ;01B29B|ADEF19  |0119EF;
                       STA.W $1A81,X                      ;01B29E|9D811A  |001A81;
                       INC.W $19F8                        ;01B2A1|EEF819  |0119F8;

CODE_01B2A3:
                       RTS                                 ;01B2A3|60      |      ;

CODE_01B2A4:
                       LDA.W $19EE                        ;01B2A4|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B2A7|29F0    |      ;
                       LSR A                               ;01B2A9|4A      |      ;
                       LSR A                               ;01B2AA|4A      |      ;
                       LSR A                               ;01B2AB|4A      |      ;
                       TAX                                 ;01B2AC|AA      |      ;
                       LDA.W DATA8_01B2C2,X                ;01B2AD|BDC2B2  |01B2C2;
                       BEQ CODE_01B2F2                     ;01B2B0|F040    |01B2F2;
                       LDA.W $19EE                        ;01B2B2|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B2B5|290F    |      ;
                       CMP.B #$04                         ;01B2B7|C904    |      ;
                       BCS CODE_01B2F2                     ;01B2B9|B037    |01B2F2;
                       ASL A                               ;01B2BB|0A      |      ;
                       ASL A                               ;01B2BC|0A      |      ;
                       ASL A                               ;01B2BD|0A      |      ;
                       TAX                                 ;01B2BE|AA      |      ;
                       LDA.W $19EE                        ;01B2BF|ADEE19  |0119EE;

DATA8_01B2C2:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B2C2
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B2D2
                       db $9D,$82,$1A,$A9,$01,$8D,$EB,$19,$60 ; 01B2E2

; ==============================================================================
; Advanced Battle Command Processing
; Handles complex battle command processing and state management
; ==============================================================================

CODE_01B2EB:
                       LDA.B #$01                         ;01B2EB|A901    |      ;
                       STA.W $19EB                        ;01B2ED|8DEB19  |0119EB;
                       JMP.W CODE_01B37B                   ;01B2F0|4C7BB3  |01B37B;

CODE_01B2F2:
                       RTS                                 ;01B2F2|60      |      ;

CODE_01B2F3:
                       LDA.W $19EE                        ;01B2F3|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B2F6|29F0    |      ;
                       LSR A                               ;01B2F8|4A      |      ;
                       LSR A                               ;01B2F9|4A      |      ;
                       LSR A                               ;01B2FA|4A      |      ;
                       TAX                                 ;01B2FB|AA      |      ;
                       LDA.W DATA8_01B311,X                ;01B2FC|BD11B3  |01B311;
                       BEQ CODE_01B346                     ;01B2FF|F045    |01B346;
                       LDA.W $19EE                        ;01B301|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B304|290F    |      ;
                       CMP.B #$04                         ;01B306|C904    |      ;
                       BCS CODE_01B346                     ;01B308|B03C    |01B346;
                       ASL A                               ;01B30A|0A      |      ;
                       ASL A                               ;01B30B|0A      |      ;
                       ASL A                               ;01B30C|0A      |      ;
                       TAX                                 ;01B30D|AA      |      ;
                       LDA.W $19EE                        ;01B30E|ADEE19  |0119EE;

DATA8_01B311:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B311
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B321
                       db $9D,$83,$1A,$A9,$02,$8D,$EB,$19,$4C,$7B,$B3 ; 01B331

; ==============================================================================
; System State Transitions and Effect Coordination
; Complex state transitions with effect coordination systems
; ==============================================================================

CODE_01B33C:
                       LDA.B #$02                         ;01B33C|A902    |      ;
                       STA.W $19EB                        ;01B33E|8DEB19  |0119EB;
                       JMP.W CODE_01B37B                   ;01B341|4C7BB3  |01B37B;

CODE_01B344:
                       JMP.W CODE_01B37B                   ;01B344|4C7BB3  |01B37B;

CODE_01B346:
                       RTS                                 ;01B346|60      |      ;

CODE_01B347:
                       LDA.W $19EE                        ;01B347|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B34A|29F0    |      ;
                       LSR A                               ;01B34C|4A      |      ;
                       LSR A                               ;01B34D|4A      |      ;
                       LSR A                               ;01B34E|4A      |      ;
                       TAX                                 ;01B34F|AA      |      ;
                       LDA.W DATA8_01B365,X                ;01B350|BD65B3  |01B365;
                       BEQ CODE_01B399                     ;01B353|F044    |01B399;
                       LDA.W $19EE                        ;01B355|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B358|290F    |      ;
                       CMP.B #$04                         ;01B35A|C904    |      ;
                       BCS CODE_01B399                     ;01B35C|B03B    |01B399;
                       ASL A                               ;01B35E|0A      |      ;
                       ASL A                               ;01B35F|0A      |      ;
                       ASL A                               ;01B360|0A      |      ;
                       TAX                                 ;01B361|AA      |      ;
                       LDA.W $19EE                        ;01B362|ADEE19  |0119EE;

DATA8_01B365:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B365
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B375
                       db $9D,$84,$1A,$A9,$03,$8D,$EB,$19,$4C,$7B,$B3 ; 01B385

; ==============================================================================
; Advanced Effect Processing Hub
; Central hub for advanced effect processing and coordination
; ==============================================================================

CODE_01B390:
                       LDA.B #$03                         ;01B390|A903    |      ;
                       STA.W $19EB                        ;01B392|8DEB19  |0119EB;
                       JMP.W CODE_01B37B                   ;01B395|4C7BB3  |01B37B;

CODE_01B398:
                       JMP.W CODE_01B37B                   ;01B398|4C7BB3  |01B37B;

CODE_01B399:
                       RTS                                 ;01B399|60      |      ;

CODE_01B39A:
                       LDA.W $19EE                        ;01B39A|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B39D|29F0    |      ;
                       LSR A                               ;01B39F|4A      |      ;
                       LSR A                               ;01B3A0|4A      |      ;
                       LSR A                               ;01B3A1|4A      |      ;
                       TAX                                 ;01B3A2|AA      |      ;
                       LDA.W DATA8_01B3B8,X                ;01B3A3|BDB8B3  |01B3B8;
                       BEQ CODE_01B3EF                     ;01B3A6|F047    |01B3EF;
                       LDA.W $19EE                        ;01B3A8|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B3AB|290F    |      ;
                       CMP.B #$04                         ;01B3AD|C904    |      ;
                       BCS CODE_01B3EF                     ;01B3AF|B03E    |01B3EF;
                       ASL A                               ;01B3B1|0A      |      ;
                       ASL A                               ;01B3B2|0A      |      ;
                       ASL A                               ;01B3B3|0A      |      ;
                       TAX                                 ;01B3B4|AA      |      ;
                       LDA.W $19EE                        ;01B3B5|ADEE19  |0119EE;

DATA8_01B3B8:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B3B8
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B3C8
                       db $9D,$85,$1A,$A9,$04,$8D,$EB,$19,$4C,$7B,$B3 ; 01B3D8

; ==============================================================================
; Graphics and Scene Coordination System
; Advanced graphics and scene coordination with complex processing
; ==============================================================================

CODE_01B3E3:
                       LDA.B #$04                         ;01B3E3|A904    |      ;
                       STA.W $19EB                        ;01B3E5|8DEB19  |0119EB;
                       JMP.W CODE_01B37B                   ;01B3E8|4C7BB3  |01B37B;

CODE_01B3EB:
                       JMP.W CODE_01B37B                   ;01B3EB|4C7BB3  |01B37B;

CODE_01B3EE:
                       JMP.W CODE_01B37B                   ;01B3EE|4C7BB3  |01B37B;

CODE_01B3EF:
                       RTS                                 ;01B3EF|60      |      ;

; ==============================================================================
; Final Effect Processing and System Integration
; Completes effect processing with system integration
; ==============================================================================

CODE_01B3F0:
                       LDA.W $19EE                        ;01B3F0|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B3F3|29F0    |      ;
                       LSR A                               ;01B3F5|4A      |      ;
                       LSR A                               ;01B3F6|4A      |      ;
                       LSR A                               ;01B3F7|4A      |      ;
                       TAX                                 ;01B3F8|AA      |      ;
                       LDA.W DATA8_01B40E,X                ;01B3F9|BD0EB4  |01B40E;
                       BEQ CODE_01B443                     ;01B3FC|F045    |01B443;
                       LDA.W $19EE                        ;01B3FE|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B401|290F    |      ;
                       CMP.B #$04                         ;01B403|C904    |      ;
                       BCS CODE_01B443                     ;01B405|B03C    |01B443;
                       ASL A                               ;01B407|0A      |      ;
                       ASL A                               ;01B408|0A      |      ;
                       ASL A                               ;01B409|0A      |      ;
                       TAX                                 ;01B40A|AA      |      ;
                       LDA.W $19EE                        ;01B40B|ADEE19  |0119EE;

DATA8_01B40E:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B40E
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B41E
                       db $9D,$86,$1A,$A9,$05,$8D,$EB,$19,$4C,$7B,$B3 ; 01B42E

CODE_01B439:
                       LDA.B #$05                         ;01B439|A905    |      ;
                       STA.W $19EB                        ;01B43B|8DEB19  |0119EB;
                       JMP.W CODE_01B37B                   ;01B43E|4C7BB3  |01B37B;

CODE_01B441:
                       JMP.W CODE_01B37B                   ;01B441|4C7BB3  |01B37B;

CODE_01B443:
                       RTS                                 ;01B443|60      |      ;

CODE_01B444:
                       LDA.W $19EE                        ;01B444|ADEE19  |0119EE;
                       AND.B #$F0                         ;01B447|29F0    |      ;
                       LSR A                               ;01B449|4A      |      ;
                       LSR A                               ;01B44A|4A      |      ;
                       LSR A                               ;01B44B|4A      |      ;
                       TAX                                 ;01B44C|AA      |      ;
                       LDA.W DATA8_01B462,X                ;01B44D|BD62B4  |01B462;
                       BEQ CODE_01B497                     ;01B450|F045    |01B497;
                       LDA.W $19EE                        ;01B452|ADEE19  |0119EE;
                       AND.B #$0F                         ;01B455|290F    |      ;
                       CMP.B #$04                         ;01B457|C904    |      ;
                       BCS CODE_01B497                     ;01B459|B03C    |01B497;
                       ASL A                               ;01B45B|0A      |      ;
                       ASL A                               ;01B45C|0A      |      ;
                       ASL A                               ;01B45D|0A      |      ;
                       TAX                                 ;01B45E|AA      |      ;
                       LDA.W $19EE                        ;01B45F|ADEE19  |0119EE;

DATA8_01B462:
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B462
                       db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 01B472
                       db $9D,$87,$1A,$A9,$06,$8D,$EB,$19,$4C,$7B,$B3 ; 01B482

CODE_01B48D:
                       LDA.B #$06                         ;01B48D|A906    |      ;
                       STA.W $19EB                        ;01B48F|8DEB19  |0119EB;
                       JMP.W CODE_01B37B                   ;01B492|4C7BB3  |01B37B;

CODE_01B495:
                       JMP.W CODE_01B37B                   ;01B495|4C7BB3  |01B37B;

CODE_01B497:
                       RTS                                 ;01B497|60      |      ;

; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 5, Part 1)
; Advanced Battle Engine Coordination and DMA Management
; ==============================================================================

; ==============================================================================
; Battle Engine Coordination Hub
; Central coordination hub for advanced battle engine systems
; ==============================================================================

CODE_01B498:
                       PHP                                 ;01B498|08      |      ;
                       SEP #$20                           ;01B499|E220    |      ;
                       REP #$10                           ;01B49B|C210    |      ;
                       PHX                                 ;01B49D|DA      |      ;
                       PHY                                 ;01B49E|5A      |      ;
                       JSR.W CODE_01C807                   ;01B49F|2007C8  |01C807;
                       PLY                                 ;01B4A2|7A      |      ;
                       PLX                                 ;01B4A3|FA      |      ;
                       STX.W $192B                        ;01B4A4|8E2B19  |01192B;
                       PLB                                 ;01B4A7|AB      |      ;
                       PLY                                 ;01B4A8|7A      |      ;
                       PLX                                 ;01B4A9|FA      |      ;
                       PLP                                 ;01B4AA|28      |      ;
                       RTS                                 ;01B4AB|60      |      ;

; ==============================================================================
; Advanced DMA Transfer System
; Handles advanced DMA transfer operations with coordination
; ==============================================================================

CODE_01B4AC:
                       LDX.W #$B8AD                       ;01B4AC|A2ADB8  |      ;
                       BRA CODE_01B4B4                     ;01B4AF|8003    |01B4B4;

CODE_01B4B1:
                       LDX.W #$B8B9                       ;01B4B1|A2B9B8  |      ;

CODE_01B4B4:
                       PEA.W $0006                        ;01B4B4|F40600  |010006;
                       PLB                                 ;01B4B7|AB      |      ;
                       PLA                                 ;01B4B8|68      |      ;

CODE_01B4B9:
                       LDA.W $0000,X                      ;01B4B9|BD0000  |060000;
                       CMP.B #$FF                         ;01B4BC|C9FF    |      ;
                       BEQ CODE_01B4E3                     ;01B4BE|F023    |01B4E3;
                       STA.W $19EE                        ;01B4C0|8DEE19  |0619EE;
                       LDA.B #$22                         ;01B4C3|A922    |      ;
                       STA.W $19EF                        ;01B4C5|8DEF19  |0619EF;
                       PHX                                 ;01B4C8|DA      |      ;
                       PHP                                 ;01B4C9|08      |      ;
                       PHB                                 ;01B4CA|8B      |      ;
                       PHK                                 ;01B4CB|4B      |      ;
                       PLB                                 ;01B4CC|AB      |      ;
                       JSR.W CODE_01B73C                   ;01B4CD|203CB7  |01B73C;
                       PLB                                 ;01B4D0|AB      |      ;
                       PLP                                 ;01B4D1|28      |      ;
                       PLX                                 ;01B4D2|FA      |      ;
                       INX                                 ;01B4D3|E8      |      ;
                       BRA CODE_01B4B9                     ;01B4D4|80E3    |01B4B9;

; ==============================================================================
; Complex Memory Management Engine
; Advanced memory management with complex allocation systems
; ==============================================================================

CODE_01B4D6:
                       LDA.B #$00                         ;01B4D6|A900    |      ;
                       XBA                                 ;01B4D8|EB      |      ;
                       LDA.W $0E91                        ;01B4D9|AD910E  |010E91;
                       TAX                                 ;01B4DC|AA      |      ;
                       LDA.L DATA8_06BE77,X                ;01B4DD|BF77BE06|06BE77;
                       BMI CODE_01B4E3                     ;01B4E1|301C    |01B4E3;

CODE_01B4E3:
                       ASL A                               ;01B4E3|0A      |      ;
                       TAX                                 ;01B4E4|AA      |      ;
                       PHP                                 ;01B4E5|08      |      ;
                       REP #$30                           ;01B4E6|C230    |      ;
                       LDA.L DATA8_06BEE3,X                ;01B4E8|BFE3BE06|06BEE3;
                       TAX                                 ;01B4EC|AA      |      ;
                       PLP                                 ;01B4ED|28      |      ;

CODE_01B4EE:
                       LDA.L DATA8_06BF15,X                ;01B4EE|BF15BF06|06BF15;
                       CMP.B #$FF                         ;01B4F2|C9FF    |      ;
                       BEQ CODE_01B51F                     ;01B4F4|F029    |01B51F;
                       JSL.L CODE_009776                   ;01B4F6|22769700|009776;
                       BEQ CODE_01B51A                     ;01B4FA|F01E    |01B51A;
                       LDA.L DATA8_06BF16,X                ;01B4FC|BF16BF06|06BF16;
                       STA.W $19EE                        ;01B500|8DEE19  |0119EE;
                       LDA.L DATA8_06BF17,X                ;01B503|BF17BF06|06BF17;
                       STA.W $19EF                        ;01B507|8DEF19  |0119EF;
                       CMP.B #$24                         ;01B50A|C924    |      ;
                       BEQ CODE_01B520                     ;01B50C|F012    |01B520;
                       CMP.B #$28                         ;01B50E|C928    |      ;
                       BEQ CODE_01B528                     ;01B510|F016    |01B528;
                       LDY.W $19EE                        ;01B512|ACEE19  |0119EE;
                       CPY.W #$2500                       ;01B515|C00025  |      ;
                       BEQ UNREACH_01B53F                  ;01B518|F025    |01B53F;

CODE_01B51A:
                       INX                                 ;01B51A|E8      |      ;
                       INX                                 ;01B51B|E8      |      ;
                       INX                                 ;01B51C|E8      |      ;
                       BRA CODE_01B4EE                     ;01B51D|80CF    |01B4EE;

CODE_01B51F:
                       RTS                                 ;01B51F|60      |      ;

; ==============================================================================
; Animation Control Loop System
; Advanced animation control with complex loop management
; ==============================================================================

CODE_01B520:
                       LDA.W $19EE                        ;01B520|ADEE19  |0119EE;
                       STA.W $1919                        ;01B523|8D1919  |011919;
                       BRA CODE_01B51A                     ;01B526|80F2    |01B51A;

CODE_01B528:
                       LDA.W $19EE                        ;01B528|ADEE19  |0119EE;
                       ASL A                               ;01B52B|0A      |      ;
                       ASL A                               ;01B52C|0A      |      ;
                       ASL A                               ;01B52D|0A      |      ;
                       ASL A                               ;01B52E|0A      |      ;
                       STA.W $19EE                        ;01B52F|8DEE19  |0119EE;
                       LDA.W $1913                        ;01B532|AD1319  |011913;
                       AND.B #$0F                         ;01B535|290F    |      ;
                       ORA.W $19EE                        ;01B537|0DEE19  |0119EE;
                       STA.W $1913                        ;01B53A|8D1319  |011913;
                       BRA CODE_01B51A                     ;01B53D|80DB    |01B51A;

UNREACH_01B53F:
                       db $22,$4C,$B2,$01,$80,$D5   ;01B53F

; ==============================================================================
; Advanced Effect Processing Engine
; Handles advanced effect processing with state management
; ==============================================================================

CODE_01B545:
                       LDA.B #$00                         ;01B545|A900    |      ;
                       STA.W $19F6                        ;01B547|8DF619  |0119F6;
                       XBA                                 ;01B54A|EB      |      ;
                       LDA.W $0E91                        ;01B54B|AD910E  |010E91;
                       TAX                                 ;01B54E|AA      |      ;
                       LDA.L DATA8_06BE77,X                ;01B54F|BF77BE06|06BE77;
                       BMI CODE_01B58F                     ;01B553|303A    |01B58F;
                       ASL A                               ;01B555|0A      |      ;
                       TAX                                 ;01B556|AA      |      ;
                       PHP                                 ;01B557|08      |      ;
                       REP #$30                           ;01B558|C230    |      ;
                       LDA.L DATA8_06BEE3,X                ;01B55A|BFE3BE06|06BEE3;
                       TAX                                 ;01B55E|AA      |      ;
                       PLP                                 ;01B55F|28      |      ;

CODE_01B560:
                       LDA.L DATA8_06BF15,X                ;01B560|BF15BF06|06BF15;
                       CMP.B #$FF                         ;01B564|C9FF    |      ;
                       BEQ CODE_01B58F                     ;01B566|F027    |01B58F;
                       JSL.L CODE_009776                   ;01B568|22769700|009776;
                       BEQ CODE_01B58A                     ;01B56C|F01C    |01B58A;
                       LDA.L DATA8_06BF16,X                ;01B56E|BF16BF06|06BF16;
                       STA.W $19EE                        ;01B572|8DEE19  |0119EE;
                       LDA.L DATA8_06BF17,X                ;01B575|BF17BF06|06BF17;
                       STA.W $19EF                        ;01B579|8DEF19  |0119EF;
                       CMP.B #$24                         ;01B57C|C924    |      ;
                       BEQ CODE_01B58A                     ;01B57E|F00A    |01B58A;
                       CMP.B #$28                         ;01B580|C928    |      ;
                       BEQ CODE_01B58A                     ;01B582|F006    |01B58A;
                       PHX                                 ;01B584|DA      |      ;
                       JSL.L CODE_01B24C                   ;01B585|224CB201|01B24C;
                       PLX                                 ;01B589|FA      |      ;

CODE_01B58A:
                       INX                                 ;01B58A|E8      |      ;
                       INX                                 ;01B58B|E8      |      ;
                       INX                                 ;01B58C|E8      |      ;
                       BRA CODE_01B560                     ;01B58D|80D1    |01B560;

CODE_01B58F:
                       RTS                                 ;01B58F|60      |      ;

; ==============================================================================
; Graphics Processing and Memory Transfer
; Advanced graphics processing with memory transfer coordination
; ==============================================================================

                       db $A2,$00,$00,$8E,$50,$0C,$8E,$52,$0C,$8E,$54,$0C,$8E,$56,$0C,$A9 ; 01B590
                       db $55,$8D,$05,$0E,$A9,$3D,$8D,$52,$0C,$8D,$56,$0C,$A9,$0C,$0D,$54 ; 01B5A0
                       db $1A,$8D,$57,$0C,$09,$40,$8D,$53,$0C,$AD,$2B,$19,$38,$E9,$04,$8D ; 01B5B0
                       db $50,$0C,$AD,$2B,$19,$18,$69,$0C,$8D,$54,$0C,$AD,$2D,$19,$38,$E9 ; 01B5C0
                       db $04,$8D,$51,$0C,$8D,$55,$0C,$A9,$50,$8D,$05,$0E,$A9,$14,$20,$A9 ; 01B5D0
                       db $D6,$A9,$55,$8D,$05,$0E,$A9,$14,$20,$A9,$D6,$A9,$50,$8D,$05,$0E ; 01B5E0
                       db $A9,$14,$20,$A9,$D6,$A9,$55,$8D,$05,$0E,$60                           ; 01B5F0

; ==============================================================================
; Battle State Machine Controller
; Advanced battle state machine with complex state transitions
; ==============================================================================

CODE_01B5FB:
                       PHP                                 ;01B5FB|08      |      ;
                       SEP #$20                           ;01B5FC|E220    |      ;
                       REP #$10                           ;01B5FE|C210    |      ;
                       LDA.B #$01                         ;01B600|A901    |      ;
                       STA.W $194B                        ;01B602|8D4B19  |01194B;
                       STZ.W $1951                        ;01B605|9C5119  |011951;
                       INC.W $19D3                        ;01B608|EED319  |0119D3;
                       LDX.W $0E89                        ;01B60B|AE890E  |010E89;
                       STX.W $192D                        ;01B60E|8E2D19  |01192D;
                       JSR.W CODE_01880C                   ;01B611|200C88  |01880C;
                       LDA.B #$00                         ;01B614|A900    |      ;
                       XBA                                 ;01B616|EB      |      ;
                       LDA.L $7F8000,X                    ;01B617|BF00807F|7F8000;
                       INC A                               ;01B61B|1A      |      ;
                       STA.L $7F8000,X                    ;01B61C|9F00807F|7F8000;
                       AND.B #$7F                         ;01B620|297F    |      ;
                       TAX                                 ;01B622|AA      |      ;
                       LDA.L $7FD0F4,X                    ;01B623|BFF4D07F|7FD0F4;
                       STA.W $19C9                        ;01B627|8DC919  |0119C9;
                       PHP                                 ;01B62A|08      |      ;
                       REP #$30                           ;01B62B|C230    |      ;
                       TXA                                 ;01B62D|8A      |      ;
                       ASL A                               ;01B62E|0A      |      ;
                       ASL A                               ;01B62F|0A      |      ;
                       TAX                                 ;01B630|AA      |      ;
                       LDA.L $7FCEF4,X                    ;01B631|BFF4CE7F|7FCEF4;
                       STA.W $19C5                        ;01B635|8DC519  |0119C5;
                       LDA.L $7FCEF6,X                    ;01B638|BFF6CE7F|7FCEF6;
                       STA.W $19C7                        ;01B63C|8DC719  |0119C7;
                       JSR.W CODE_0196D3                   ;01B63F|20D396  |0196D3;
                       JSR.W CODE_019058                   ;01B642|205890  |019058;
                       LDA.W $19BD                        ;01B645|ADBD19  |0119BD;
                       CLC                                 ;01B648|18      |      ;
                       ADC.W #$0008                       ;01B649|690800  |      ;
                       AND.W #$001F                       ;01B64C|291F00  |      ;
                       STA.W $19BD                        ;01B64F|8DBD19  |0119BD;
                       LDA.W $19BF                        ;01B652|ADBF19  |0119BF;
                       CLC                                 ;01B655|18      |      ;
                       ADC.W #$0004                       ;01B656|690400  |      ;
                       AND.W #$000F                       ;01B659|290F00  |      ;
                       STA.W $19BF                        ;01B65C|8DBF19  |0119BF;
                       JSR.W CODE_0188CD                   ;01B65F|20CD88  |0188CD;
                       PLP                                 ;01B662|28      |      ;
                       LDX.W $192B                        ;01B663|AE2B19  |01192B;
                       STX.W $195F                        ;01B666|8E5F19  |01195F;
                       JSR.W CODE_0182D0                   ;01B669|20D082  |0182D0;
                       PLP                                 ;01B66C|28      |      ;
                       RTS                                 ;01B66D|60      |      ;

; ==============================================================================
; Enhanced Random Number Generation
; Advanced random number generation with enhanced algorithms
; ==============================================================================

                       db $E2,$20,$C2,$10,$A9,$01,$8D,$4B,$19,$9C,$51,$19,$AD,$D3,$19,$18 ; 01B66E
                       db $69,$10,$8D,$D3,$19,$AE,$89,$0E,$8E,$2D,$19,$20,$0C,$88,$A9,$00 ; 01B67E
                       db $EB,$BF,$00,$80,$7F,$18,$69,$10,$9F,$00,$80,$7F,$29,$7F,$AA,$BF ; 01B68E
                       db $F4,$D0,$7F,$8D,$C9,$19,$08,$C2,$30,$8A,$0A,$0A,$AA,$BF,$F4,$CE ; 01B69E
                       db $7F,$8D,$C5,$19,$BF,$F6,$CE,$7F,$8D,$C7,$19,$20,$D3,$96,$20,$58 ; 01B6AE
                       db $90,$AD,$BD,$19,$18,$69,$08,$00,$29,$1F,$00,$8D,$BD,$19,$AD,$BF ; 01B6BE
                       db $19,$18,$69,$05,$00,$29,$0F,$00,$8D,$BF,$19,$20,$CD,$88,$28,$AE ; 01B6CE
                       db $2B,$19,$8E,$5F,$19,$20,$D0,$82,$60                                     ; 01B6DE

; ==============================================================================
; Sound Effect and Audio Coordination
; Advanced sound effect processing with audio coordination
; ==============================================================================

CODE_01B6E7:
                       PHP                                 ;01B6E7|08      |      ;
                       SEP #$20                           ;01B6E8|E220    |      ;
                       REP #$10                           ;01B6EA|C210    |      ;
                       LDA.B #$0E                         ;01B6EC|A90E    |      ;
                       ORA.W $1A54                        ;01B6EE|0D541A  |011A54;
                       STA.W $0C57                        ;01B6F1|8D570C  |010C57;
                       ORA.B #$40                         ;01B6F4|0940    |      ;
                       STA.W $0C53                        ;01B6F6|8D530C  |010C53;
                       LDA.B #$68                         ;01B6F9|A968    |      ;
                       STA.W $0C52                        ;01B6FB|8D520C  |010C52;
                       STA.W $0C56                        ;01B6FE|8D560C  |010C56;
                       LDA.W $192D                        ;01B701|AD2D19  |01192D;
                       SEC                                 ;01B704|38      |      ;
                       SBC.B #$08                         ;01B705|E908    |      ;
                       STA.W $0C50                        ;01B707|8D500C  |010C50;
                       CLC                                 ;01B70A|18      |      ;
                       ADC.B #$18                         ;01B70B|6918    |      ;
                       STA.W $0C54                        ;01B70D|8D540C  |010C54;
                       LDA.W $192E                        ;01B710|AD2E19  |01192E;
                       CLC                                 ;01B713|18      |      ;
                       ADC.B #$08                         ;01B714|6908    |      ;
                       STA.W $0C51                        ;01B716|8D510C  |010C51;
                       STA.W $0C55                        ;01B719|8D550C  |010C55;
                       LDA.B #$50                         ;01B71C|A950    |      ;
                       STA.W $0E05                        ;01B71E|8D050E  |010E05;
                       JSR.W CODE_0182D0                   ;01B721|20D082  |0182D0;
                       LDA.B #$2C                         ;01B724|A92C    |      ;
                       JSR.W CODE_01D6A9                   ;01B726|20A9D6  |01D6A9;
                       LDA.W $0C51                        ;01B729|AD510C  |010C51;
                       DEC A                               ;01B72C|3A      |      ;
                       STA.W $0C51                        ;01B72D|8D510C  |010C51;
                       STA.W $0C55                        ;01B730|8D550C  |010C55;
                       JSR.W CODE_0182D0                   ;01B733|20D082  |0182D0;
                       LDA.B #$2C                         ;01B736|A92C    |      ;
                       JSR.W CODE_01D6A9                   ;01B738|20A9D6  |01D6A9;
                       PLP                                 ;01B73B|28      |      ;
                       RTS                                 ;01B73C|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 5, Part 2)
; Advanced Pattern Management and Complex Battle Logic
; ==============================================================================

; ==============================================================================
; Advanced Pattern Management System
; Handles complex pattern management with advanced battle logic
; ==============================================================================

CODE_01B73D:
                       PHP                                 ;01B73D|08      |      ;
                       SEP #$20                           ;01B73E|E220    |      ;
                       REP #$10                           ;01B740|C210    |      ;
                       LDA.W $0E91                        ;01B742|AD910E  |010E91;
                       BEQ CODE_01B752                     ;01B745|F00B    |01B752;
                       LDA.B #$55                         ;01B747|A955    |      ;
                       STA.W $0E04                        ;01B749|8D040E  |010E04;
                       STA.W $0E0C                        ;01B74C|8D0C0E  |010E0C;
                       JSR.W CODE_0182D0                   ;01B74F|20D082  |0182D0;

CODE_01B752:
                       PLP                                 ;01B752|28      |      ;
                       RTS                                 ;01B753|60      |      ;

; ==============================================================================
; Complex Animation and Sprite Coordination
; Advanced animation coordination with sprite management
; ==============================================================================

CODE_01B754:
                       PHP                                 ;01B754|08      |      ;
                       PHX                                 ;01B755|DA      |      ;
                       PHY                                 ;01B756|5A      |      ;
                       REP #$30                           ;01B757|C230    |      ;
                       PHX                                 ;01B759|DA      |      ;
                       AND.W #$00FF                       ;01B75A|29FF00  |      ;
                       ASL A                               ;01B75D|0A      |      ;
                       TAX                                 ;01B75E|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01B75F|BFCAFD00|00FDCA;
                       TAY                                 ;01B763|A8      |      ;
                       PLX                                 ;01B764|FA      |      ;
                       JSR.W CODE_01AE8A                   ;01B765|208AAE  |01AE8A;
                       LDA.W $19E7                        ;01B768|ADE719  |0119E7;
                       JSR.W CODE_01B119                   ;01B76B|2019B1  |01B119;
                       PLY                                 ;01B76E|7A      |      ;
                       PLX                                 ;01B76F|FA      |      ;
                       PLP                                 ;01B770|28      |      ;
                       RTS                                 ;01B771|60      |      ;

; ==============================================================================
; Advanced Sprite Processing Engine
; Complex sprite processing with multi-layer coordination
; ==============================================================================

CODE_01B772:
                       PHP                                 ;01B772|08      |      ;
                       PHD                                 ;01B773|0B      |      ;
                       SEP #$20                           ;01B774|E220    |      ;
                       REP #$10                           ;01B776|C210    |      ;
                       PEA.W $1A72                        ;01B778|F4721A  |011A72;
                       PLD                                 ;01B77B|2B      |      ;
                       LDX.W #$0000                       ;01B77C|A20000  |      ;
                       STX.W $1975                        ;01B77F|8E7519  |011975;
                       STX.W $1973                        ;01B782|8E7319  |011973;

CODE_01B785:
                       SEP #$20                           ;01B785|E220    |      ;
                       REP #$10                           ;01B787|C210    |      ;
                       LDX.W $1975                        ;01B789|AE7519  |011975;
                       LDA.B $00,X                        ;01B78C|B500    |001A72;
                       BIT.B #$10                         ;01B78E|8910    |      ;
                       BEQ CODE_01B7BC                     ;01B790|F02A    |01B7BC;
                       CMP.B #$FF                         ;01B792|C9FF    |      ;
                       BEQ CODE_01B7BC                     ;01B794|F026    |01B7BC;
                       JSR.W CODE_01B7D8                   ;01B796|20D8B7  |01B7D8;
                       REP #$30                           ;01B799|C230    |      ;
                       PHX                                 ;01B79B|DA      |      ;
                       LDA.W $1973                        ;01B79C|AD7319  |011973;
                       ASL A                               ;01B79F|0A      |      ;
                       ASL A                               ;01B7A0|0A      |      ;
                       TAX                                 ;01B7A1|AA      |      ;
                       LDA.L DATA8_01A63A,X                ;01B7A2|BF3AA601|01A63A;
                       TAY                                 ;01B7A6|A8      |      ;
                       PLX                                 ;01B7A7|FA      |      ;
                       LDA.B $01,X                        ;01B7A8|B501    |001A73;
                       STA.W $0C02,Y                      ;01B7AA|99020C  |010C02;
                       LDA.B $03,X                        ;01B7AD|B503    |001A75;
                       STA.W $0C06,Y                      ;01B7AF|99060C  |010C06;
                       LDA.B $05,X                        ;01B7B2|B505    |001A77;
                       STA.W $0C0A,Y                      ;01B7B4|990A0C  |010C0A;
                       LDA.B $07,X                        ;01B7B7|B507    |001A79;
                       STA.W $0C0E,Y                      ;01B7B9|990E0C  |010C0E;

CODE_01B7BC:
                       REP #$30                           ;01B7BC|C230    |      ;
                       INC.W $1973                        ;01B7BE|EE7319  |011973;
                       LDA.W $1973                        ;01B7C1|AD7319  |011973;
                       CMP.W #$0016                       ;01B7C4|C91600  |      ;
                       BEQ CODE_01B7D5                     ;01B7C7|F00C    |01B7D5;
                       LDA.W $1975                        ;01B7C9|AD7519  |011975;
                       CLC                                 ;01B7CC|18      |      ;
                       ADC.W #$001A                       ;01B7CD|691A00  |      ;
                       STA.W $1975                        ;01B7D0|8D7519  |011975;
                       BRA CODE_01B785                     ;01B7D3|80B0    |01B785;

CODE_01B7D5:
                       PLD                                 ;01B7D5|2B      |      ;
                       PLP                                 ;01B7D6|28      |      ;
                       RTS                                 ;01B7D7|60      |      ;

; ==============================================================================
; Complex Animation Frame Processing
; Handles complex animation frame processing with timing control
; ==============================================================================

CODE_01B7D8:
                       SEP #$20                           ;01B7D8|E220    |      ;
                       REP #$10                           ;01B7DA|C210    |      ;
                       LDA.B $0E,X                        ;01B7DC|B50E    |001A80;
                       ROL A                               ;01B7DE|2A      |      ;
                       ROL A                               ;01B7DF|2A      |      ;
                       ROL A                               ;01B7E0|2A      |      ;
                       AND.B #$03                         ;01B7E1|2903    |      ;
                       STA.W $197D                        ;01B7E3|8D7D19  |01197D;
                       STA.W $197F                        ;01B7E6|8D7F19  |01197F;
                       CMP.B #$00                         ;01B7E9|C900    |      ;
                       BNE CODE_01B804                     ;01B7EB|D017    |01B804;
                       INC.W $197F                        ;01B7ED|EE7F19  |01197F;
                       LDA.B $17,X                        ;01B7F0|B517    |001A89;
                       PHA                                 ;01B7F2|48      |      ;
                       LSR A                               ;01B7F3|4A      |      ;
                       STA.W $197E                        ;01B7F4|8D7E19  |01197E;
                       PLA                                 ;01B7F7|68      |      ;
                       DEC A                               ;01B7F8|3A      |      ;
                       STA.B $17,X                        ;01B7F9|9517    |001A89;
                       LSR A                               ;01B7FB|4A      |      ;
                       CMP.W $197E                        ;01B7FC|CD7E19  |01197E;
                       BNE CODE_01B804                     ;01B7FF|D003    |01B804;
                       JMP.W CODE_01CC81                   ;01B801|4C81CC  |01CC81;

CODE_01B804:
                       LDA.B $0E,X                        ;01B804|B50E    |001A80;
                       LSR A                               ;01B806|4A      |      ;
                       LSR A                               ;01B807|4A      |      ;
                       LSR A                               ;01B808|4A      |      ;
                       LSR A                               ;01B809|4A      |      ;
                       AND.B #$03                         ;01B80A|2903    |      ;
                       STA.W $197E                        ;01B80C|8D7E19  |01197E;
                       STA.W $1980                        ;01B80F|8D8019  |011980;
                       LDA.B $00,X                        ;01B812|B500    |001A72;
                       BPL CODE_01B81B                     ;01B814|1005    |01B81B;
                       AND.B #$03                         ;01B816|2903    |      ;
                       STA.W $197E                        ;01B818|8D7E19  |01197E;

CODE_01B81B:
                       LDA.B #$00                         ;01B81B|A900    |      ;
                       XBA                                 ;01B81D|EB      |      ;
                       LDA.B $10,X                        ;01B81E|B510    |001A82;
                       REP #$30                           ;01B820|C230    |      ;
                       ASL A                               ;01B822|0A      |      ;
                       PHX                                 ;01B823|DA      |      ;
                       TAX                                 ;01B824|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01B825|BFCAFD00|00FDCA;
                       STA.W $1977                        ;01B829|8D7719  |011977;
                       PLX                                 ;01B82C|FA      |      ;
                       SEP #$20                           ;01B82D|E220    |      ;
                       REP #$10                           ;01B82F|C210    |      ;
                       LDA.W $197D                        ;01B831|AD7D19  |01197D;
                       BNE CODE_01B83B                     ;01B834|D005    |01B83B;
                       LDA.B $17,X                        ;01B836|B517    |001A89;
                       LSR A                               ;01B838|4A      |      ;
                       BRA CODE_01B845                     ;01B839|800A    |01B845;

CODE_01B83B:
                       LDA.B $17,X                        ;01B83B|B517    |001A89;
                       SEC                                 ;01B83D|38      |      ;
                       SBC.W $197F                        ;01B83E|ED7F19  |01197F;
                       STA.B $17,X                        ;01B841|9517    |001A89;
                       LDA.B $17,X                        ;01B843|B517    |001A89;

CODE_01B845:
                       AND.B #$08                         ;01B845|2908    |      ;
                       LSR A                               ;01B847|4A      |      ;
                       LSR A                               ;01B848|4A      |      ;
                       LSR A                               ;01B849|4A      |      ;
                       STA.W $1979                        ;01B84A|8D7919  |011979;
                       LDA.B $00,X                        ;01B84D|B500    |001A72;
                       AND.B #$B0                         ;01B84F|29B0    |      ;
                       CMP.B #$B0                         ;01B851|C9B0    |      ;
                       BEQ CODE_01B87F                     ;01B853|F02A    |01B87F;
                       LDA.B $10,X                        ;01B855|B510    |001A82;
                       CMP.B #$3E                         ;01B857|C93E    |      ;
                       BNE CODE_01B860                     ;01B859|D005    |01B860;
                       LDA.W $1979                        ;01B85B|AD7919  |011979;
                       BRA CODE_01B868                     ;01B85E|8008    |01B868;

CODE_01B860:
                       LDA.W $1980                        ;01B860|AD8019  |011980;
                       ASL A                               ;01B863|0A      |      ;
                       CLC                                 ;01B864|18      |      ;
                       ADC.W $1979                        ;01B865|6D7919  |011979;

CODE_01B868:
                       REP #$30                           ;01B868|C230    |      ;
                       AND.W #$00FF                       ;01B86A|29FF00  |      ;
                       ASL A                               ;01B86D|0A      |      ;
                       ASL A                               ;01B86E|0A      |      ;
                       ASL A                               ;01B86F|0A      |      ;
                       CLC                                 ;01B870|18      |      ;
                       ADC.W $1977                        ;01B871|6D7719  |011977;
                       STA.W $1977                        ;01B874|8D7719  |011977;
                       TAY                                 ;01B877|A8      |      ;
                       SEP #$20                           ;01B878|E220    |      ;
                       REP #$10                           ;01B87A|C210    |      ;
                       JSR.W CODE_01AE8A                   ;01B87C|208AAE  |01AE8A;

CODE_01B87F:
                       SEP #$20                           ;01B87F|E220    |      ;
                       REP #$10                           ;01B881|C210    |      ;
                       LDA.B #$00                         ;01B883|A900    |      ;
                       XBA                                 ;01B885|EB      |      ;
                       LDA.W $197E                        ;01B886|AD7E19  |01197E;
                       ASL A                               ;01B889|0A      |      ;
                       REP #$30                           ;01B88A|C230    |      ;
                       AND.W #$00FF                       ;01B88C|29FF00  |      ;
                       PHX                                 ;01B88F|DA      |      ;
                       TAX                                 ;01B890|AA      |      ;
                       LDA.L DATA8_0190D5,X                ;01B891|BFD59001|0190D5;
                       STA.W $1977                        ;01B895|8D7719  |011977;
                       PLX                                 ;01B898|FA      |      ;
                       SEP #$20                           ;01B899|E220    |      ;
                       REP #$10                           ;01B89B|C210    |      ;
                       LDA.W $197D                        ;01B89D|AD7D19  |01197D;
                       CMP.B #$02                         ;01B8A0|C902    |      ;
                       BNE CODE_01B8B2                     ;01B8A2|D00E    |01B8B2;
                       LDA.W $1977                        ;01B8A4|AD7719  |011977;
                       ASL A                               ;01B8A7|0A      |      ;
                       STA.W $1977                        ;01B8A8|8D7719  |011977;
                       LDA.W $1978                        ;01B8AB|AD7819  |011978;
                       ASL A                               ;01B8AE|0A      |      ;
                       STA.W $1978                        ;01B8AF|8D7819  |011978;

CODE_01B8B2:
                       LDA.B #$00                         ;01B8B2|A900    |      ;
                       XBA                                 ;01B8B4|EB      |      ;
                       LDA.W $1977                        ;01B8B5|AD7719  |011977;
                       BEQ CODE_01B8D5                     ;01B8B8|F01B    |01B8D5;
                       BPL CODE_01B8C8                     ;01B8BA|100C    |01B8C8;
                       LDA.W $197F                        ;01B8BC|AD7F19  |01197F;
                       EOR.B #$FF                         ;01B8BF|49FF    |      ;
                       INC A                               ;01B8C1|1A      |      ;
                       XBA                                 ;01B8C2|EB      |      ;
                       LDA.B #$FF                         ;01B8C3|A9FF    |      ;
                       XBA                                 ;01B8C5|EB      |      ;
                       BRA CODE_01B8CB                     ;01B8C6|8003    |01B8CB;

CODE_01B8C8:
                       LDA.W $197F                        ;01B8C8|AD7F19  |01197F;

CODE_01B8CB:
                       REP #$30                           ;01B8CB|C230    |      ;
                       CLC                                 ;01B8CD|18      |      ;
                       ADC.B $13,X                        ;01B8CE|7513    |001A85;
                       AND.W #$03FF                       ;01B8D0|29FF03  |      ;
                       STA.B $13,X                        ;01B8D3|9513    |001A85;

CODE_01B8D5:
                       SEP #$20                           ;01B8D5|E220    |      ;
                       REP #$10                           ;01B8D7|C210    |      ;
                       LDA.B #$00                         ;01B8D9|A900    |      ;
                       XBA                                 ;01B8DB|EB      |      ;
                       LDA.W $1978                        ;01B8DC|AD7819  |011978;
                       BEQ CODE_01B8FC                     ;01B8DF|F01B    |01B8FC;
                       BPL CODE_01B8EF                     ;01B8E1|100C    |01B8EF;
                       LDA.W $197F                        ;01B8E3|AD7F19  |01197F;
                       EOR.B #$FF                         ;01B8E6|49FF    |      ;
                       INC A                               ;01B8E8|1A      |      ;
                       XBA                                 ;01B8E9|EB      |      ;
                       LDA.B #$FF                         ;01B8EA|A9FF    |      ;
                       XBA                                 ;01B8EC|EB      |      ;
                       BRA CODE_01B8F2                     ;01B8ED|8003    |01B8F2;

CODE_01B8EF:
                       LDA.W $197F                        ;01B8EF|AD7F19  |01197F;

CODE_01B8F2:
                       REP #$30                           ;01B8F2|C230    |      ;
                       CLC                                 ;01B8F4|18      |      ;
                       ADC.B $15,X                        ;01B8F5|7515    |001A87;
                       AND.W #$03FF                       ;01B8F7|29FF03  |      ;
                       STA.B $15,X                        ;01B8FA|9515    |001A87;

CODE_01B8FC:
                       SEP #$20                           ;01B8FC|E220    |      ;
                       REP #$10                           ;01B8FE|C210    |      ;
                       LDA.B $17,X                        ;01B900|B517    |001A89;
                       BPL CODE_01B906                     ;01B902|1002    |01B906;
                       STZ.B $00,X                        ;01B904|7400    |001A72;

CODE_01B906:
                       RTS                                 ;01B906|60      |      ;

; ==============================================================================
; Advanced System State Control
; Complex system state control with coordination
; ==============================================================================

CODE_01B907:
                       PHP                                 ;01B907|08      |      ;
                       PHD                                 ;01B908|0B      |      ;
                       SEP #$20                           ;01B909|E220    |      ;
                       REP #$10                           ;01B90B|C210    |      ;
                       PEA.W $1A72                        ;01B90D|F4721A  |011A72;
                       PLD                                 ;01B910|2B      |      ;
                       LDA.B $0E,X                        ;01B911|B50E    |001A80;
                       AND.B #$C0                         ;01B913|29C0    |      ;
                       BNE CODE_01B91B                     ;01B915|D004    |01B91B;
                       LDA.B #$1F                         ;01B917|A91F    |      ;
                       BRA CODE_01B91D                     ;01B919|8002    |01B91D;

CODE_01B91B:
                       LDA.B #$0F                         ;01B91B|A90F    |      ;

CODE_01B91D:
                       STA.B $17,X                        ;01B91D|9517    |001A89;
                       LDA.W $192B                        ;01B91F|AD2B19  |01192B;
                       STA.W $1979                        ;01B922|8D7919  |011979;
                       STA.W $1981                        ;01B925|8D8119  |011981;
                       LDA.B $0B,X                        ;01B928|B50B    |001A7D;
                       STA.W $197F                        ;01B92A|8D7F19  |01197F;
                       LDA.B $0C,X                        ;01B92D|B50C    |001A7E;
                       STA.W $1980                        ;01B92F|8D8019  |011980;
                       PHX                                 ;01B932|DA      |      ;
                       JSR.W CODE_01AEE7                   ;01B933|20E7AE  |01AEE7;
                       PLX                                 ;01B936|FA      |      ;
                       LDA.W $197F                        ;01B937|AD7F19  |01197F;
                       STA.B $0B,X                        ;01B93A|950B    |001A7D;
                       LDA.W $1980                        ;01B93C|AD8019  |011980;
                       STA.B $0C,X                        ;01B93F|950C    |001A7E;
                       JSR.W CODE_01AFF0                   ;01B941|20F0AF  |01AFF0;
                       PLD                                 ;01B944|2B      |      ;
                       PLP                                 ;01B945|28      |      ;
                       RTS                                 ;01B946|60      |      ;

; ==============================================================================
; Advanced Memory Clear and Initialization
; Complex memory clear with advanced initialization routines
; ==============================================================================

                       db $A9,$80,$8D,$15,$21,$A9,$00,$EB,$AD,$2B,$19,$C2,$30,$18,$6D,$2D ; 01B947
                       db $19,$AA,$8E,$16,$21,$AC,$2F,$19,$9C,$18,$21,$18,$69,$10,$00,$8D ; 01B957
                       db $16,$21,$88,$D0,$F3,$60                                                     ; 01B967

; ==============================================================================
; Scene Transition and State Management
; Advanced scene transition with complex state management
; ==============================================================================

CODE_01B96D:
                       LDA.W $19CB                        ;01B96D|ADCB19  |0119CB;
                       AND.W #$FFF8                       ;01B970|29F8FF  |      ;
                       ORA.W #$0001                       ;01B973|090100  |      ;
                       STA.W $19CB                        ;01B976|8DCB19  |0119CB;
                       SEP #$20                           ;01B979|E220    |      ;
                       REP #$10                           ;01B97B|C210    |      ;
                       LDA.W $19B4                        ;01B97D|ADB419  |0119B4;
                       AND.B #$F8                         ;01B980|29F8    |      ;
                       ORA.B #$01                         ;01B982|0901    |      ;
                       STA.W $19B4                        ;01B984|8DB419  |0119B4;
                       LDA.B #$01                         ;01B987|A901    |      ;
                       STA.W $1928                        ;01B989|8D2819  |011928;
                       LDA.B #$02                         ;01B98C|A902    |      ;
                       STA.W $19D7                        ;01B98E|8DD719  |0119D7;
                       JSR.W CODE_01CECA                   ;01B991|20CACE  |01CECA;
                       JSR.W CODE_01935D                   ;01B994|205D93  |01935D;
                       LDA.W $1935                        ;01B997|AD3519  |011935;
                       JSR.W CODE_01B1EB                   ;01B99A|20EBB1  |01B1EB;
                       STA.W $1939                        ;01B99D|8D3919  |011939;
                       STX.W $193B                        ;01B9A0|8E3B19  |01193B;
                       LDA.W $1A72,X                      ;01B9A3|BD721A  |011A72;
                       STA.W $193A                        ;01B9A6|8D3A19  |01193A;
                       LDA.B #$04                         ;01B9A9|A904    |      ;
                       STA.W $1A72,X                      ;01B9AB|9D721A  |011A72;
                       LDA.W $1A7D,X                      ;01B9AE|BD7D1A  |011A7D;
                       DEC A                               ;01B9B1|3A      |      ;
                       STA.W $192D                        ;01B9B2|8D2D19  |01192D;
                       LDA.W $1A7E,X                      ;01B9B5|BD7E1A  |011A7E;
                       STA.W $192E                        ;01B9B8|8D2E19  |01192E;
                       JSR.W CODE_01880C                   ;01B9BB|200C88  |01880C;
                       STX.W $193D                        ;01B9BE|8E3D19  |01193D;
                       JSR.W CODE_019058                   ;01B9C1|205890  |019058;
                       LDA.W $19BD                        ;01B9C4|ADBD19  |0119BD;
                       CLC                                 ;01B9C7|18      |      ;
                       ADC.B #$07                         ;01B9C8|6907    |      ;
                       AND.B #$1F                         ;01B9CA|291F    |      ;
                       STA.W $19BD                        ;01B9CC|8DBD19  |0119BD;
                       LDA.W $19BF                        ;01B9CF|ADBF19  |0119BF;
                       CLC                                 ;01B9D2|18      |      ;
                       ADC.B #$05                         ;01B9D3|6905    |      ;
                       AND.B #$0F                         ;01B9D5|290F    |      ;
                       STA.W $19BF                        ;01B9D7|8DBF19  |0119BF;
                       JSR.W CODE_0188CD                   ;01B9DA|20CD88  |0188CD;
                       LDX.W $192B                        ;01B9DD|AE2B19  |01192B;
                       STX.W $193F                        ;01B9E0|8E3F19  |01193F;
                       RTS                                 ;01B9E3|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 6, Part 1)
; Advanced Graphics Processing and Complex Animation Control
; ==============================================================================

; ==============================================================================
; Advanced Graphics Tile Coordinate Processing
; Complex tile coordinate processing with multi-layer graphics coordination
; ==============================================================================

CODE_01D044:
                       STA.W $0C58                        ;01D044|8D580C  |010C58;
                       CLC                                 ;01D047|18      |      ;
                       ADC.B #$08                         ;01D048|6908    |      ;
                       STA.W $0C54                        ;01D04A|8D540C  |010C54;
                       STA.W $0C5C                        ;01D04D|8D5C0C  |010C5C;
                       RTS                                 ;01D050|60      |      ;

CODE_01D051:
                       STA.W $0C51                        ;01D051|8D510C  |010C51;
                       STA.W $0C55                        ;01D054|8D550C  |010C55;
                       CLC                                 ;01D057|18      |      ;
                       ADC.B #$08                         ;01D058|6908    |      ;
                       STA.W $0C59                        ;01D05A|8D590C  |010C59;
                       STA.W $0C5D                        ;01D05D|8D5D0C  |010C5D;
                       RTS                                 ;01D060|60      |      ;

; ==============================================================================
; Advanced Graphics Tile Management System
; Complex graphics tile management with advanced coordination
; ==============================================================================

CODE_01D061:
                       PHP                                 ;01D061|08      |      ;
                       REP #$30                           ;01D062|C230    |      ;
                       LDA.W #$0140                       ;01D064|A94001  |      ;
                       BRA CODE_01D06F                     ;01D067|8006    |01D06F;

CODE_01D069:
                       PHP                                 ;01D069|08      |      ;
                       REP #$30                           ;01D06A|C230    |      ;
                       LDA.W #$0144                       ;01D06C|A94401  |      ;

CODE_01D06F:
                       STA.W $0C52                        ;01D06F|8D520C  |010C52;
                       INC A                               ;01D072|1A      |      ;
                       STA.W $0C56                        ;01D073|8D560C  |010C56;
                       INC A                               ;01D076|1A      |      ;
                       STA.W $0C5A                        ;01D077|8D5A0C  |010C5A;
                       INC A                               ;01D07A|1A      |      ;
                       STA.W $0C5E                        ;01D07B|8D5E0C  |010C5E;
                       SEP #$20                           ;01D07E|E220    |      ;
                       REP #$10                           ;01D080|C210    |      ;
                       LDA.B #$0C                         ;01D082|A90C    |      ;
                       ORA.W $1A54                        ;01D084|0D541A  |011A54;
                       TAY                                 ;01D087|A8      |      ;
                       ORA.W $0C53                        ;01D088|0D530C  |010C53;
                       STA.W $0C53                        ;01D08B|8D530C  |010C53;
                       TYA                                 ;01D08E|98      |      ;
                       ORA.W $0C57                        ;01D08F|0D570C  |010C57;
                       STA.W $0C57                        ;01D092|8D570C  |010C57;
                       TYA                                 ;01D095|98      |      ;
                       ORA.W $0C5B                        ;01D096|0D5B0C  |010C5B;
                       STA.W $0C5B                        ;01D099|8D5B0C  |010C5B;
                       TYA                                 ;01D09C|98      |      ;
                       ORA.W $0C5F                        ;01D09D|0D5F0C  |010C5F;
                       STA.W $0C5F                        ;01D0A0|8D5F0C  |010C5F;
                       PLP                                 ;01D0A3|28      |      ;
                       RTS                                 ;01D0A4|60      |      ;

; ==============================================================================
; Complex Graphics Processing Coordination
; Advanced graphics processing with battle coordination
; ==============================================================================

CODE_01D0A5:
                       LDA.B #$08                         ;01D0A5|A908    |      ;
                       JSR.W CODE_01BAAD                   ;01D0A7|20ADBA  |01BAAD;
                       JSR.W CODE_01D069                   ;01D0AA|2069D0  |01D069;
                       LDA.B #$06                         ;01D0AD|A906    |      ;
                       JSR.W CODE_01D6A9                   ;01D0AF|20A9D6  |01D6A9;
                       JSR.W CODE_01D061                   ;01D0B2|2061D0  |01D061;
                       LDA.B #$06                         ;01D0B5|A906    |      ;
                       JSR.W CODE_01D6A9                   ;01D0B7|20A9D6  |01D6A9;
                       RTS                                 ;01D0BA|60      |      ;

; ==============================================================================
; Advanced Animation Loop Control System
; Complex animation loop control with advanced graphics coordination
; ==============================================================================

CODE_01D0BB:
                       PHP                                 ;01D0BB|08      |      ;
                       LDY.W #$0010                       ;01D0BC|A01000  |      ;
                       STZ.W $192B                        ;01D0BF|9C2B19  |01192B;
                       LDX.W #$6B00                       ;01D0C2|A2006B  |      ;
                       STX.W $192D                        ;01D0C5|8E2D19  |01192D;
                       STY.W $192F                        ;01D0C8|8C2F19  |01192F;
                       STZ.W $1931                        ;01D0CB|9C3119  |011931;
                       LDX.W $1900                        ;01D0CE|AE0019  |011900;
                       STX.W $1933                        ;01D0D1|8E3319  |011933;
                       SEP #$20                           ;01D0D4|E220    |      ;
                       REP #$10                           ;01D0D6|C210    |      ;
                       LDA.W $0E91                        ;01D0D8|AD910E  |010E91;
                       CMP.B #$6B                         ;01D0DB|C96B    |      ;
                       BNE CODE_01D0E5                     ;01D0DD|D006    |01D0E5;
                       db $A2,$04,$00,$8E,$31,$19   ;01D0DF|        |      ;

CODE_01D0E5:
                       JSR.W CODE_018DF3                   ;01D0E5|20F38D  |018DF3;

CODE_01D0E8:
                       PHP                                 ;01D0E8|08      |      ;
                       REP #$30                           ;01D0E9|C230    |      ;
                       LDA.W $1900                        ;01D0EB|AD0019  |011900;
                       CLC                                 ;01D0EE|18      |      ;
                       ADC.W $1931                        ;01D0EF|6D3119  |011931;
                       STA.W $1900                        ;01D0F2|8D0019  |011900;
                       LDA.W $1931                        ;01D0F5|AD3119  |011931;
                       EOR.W #$FFFF                       ;01D0F8|49FFFF  |      ;
                       INC A                               ;01D0FB|1A      |      ;
                       STA.W $1931                        ;01D0FC|8D3119  |011931;
                       PLP                                 ;01D0FF|28      |      ;
                       LDA.B #$03                         ;01D100|A903    |      ;
                       STA.W $1A46                        ;01D102|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D105|20F38D  |018DF3;
                       LDA.W $192B                        ;01D108|AD2B19  |01192B;
                       CLC                                 ;01D10B|18      |      ;
                       ADC.B #$03                         ;01D10C|6903    |      ;
                       AND.B #$0F                         ;01D10E|290F    |      ;
                       STA.W $192B                        ;01D110|8D2B19  |01192B;
                       DEY                                 ;01D113|88      |      ;
                       BNE CODE_01D0E8                     ;01D114|D0D2    |01D0E8;
                       REP #$30                           ;01D116|C230    |      ;
                       LDA.W $1933                        ;01D118|AD3319  |011933;
                       STA.W $1900                        ;01D11B|8D0019  |011900;
                       PLP                                 ;01D11E|28      |      ;
                       RTS                                 ;01D11F|60      |      ;

; ==============================================================================
; Advanced Character Sprite Discovery System
; Complex character sprite discovery with battle coordination
; ==============================================================================

CODE_01D120:
                       LDA.B #$00                         ;01D120|A900    |      ;
                       JSR.W CODE_01B1EB                   ;01D122|20EBB1  |01B1EB;
                       BCC CODE_01D14D                     ;01D125|9026    |01D14D;
                       STX.W $1935                        ;01D127|8E3519  |011935;
                       STA.W $1937                        ;01D12A|8D3719  |011937;
                       LDA.W $1A72,X                      ;01D12D|BD721A  |011A72;
                       STA.W $1938                        ;01D130|8D3819  |011938;
                       JSR.W CODE_01D14E                   ;01D133|204ED1  |01D14E;
                       LDA.B #$01                         ;01D136|A901    |      ;
                       JSR.W CODE_01B1EB                   ;01D138|20EBB1  |01B1EB;
                       BCC CODE_01D14D                     ;01D13B|9010    |01D14D;
                       STX.W $1939                        ;01D13D|8E3919  |011939;
                       STA.W $193B                        ;01D140|8D3B19  |01193B;
                       LDA.W $1A72,X                      ;01D143|BD721A  |011A72;
                       STA.W $1938                        ;01D146|8D3819  |011938;
                       JSR.W CODE_01D14E                   ;01D149|204ED1  |01D14E;
                       SEC                                 ;01D14C|38      |      ;

CODE_01D14D:
                       RTS                                 ;01D14D|60      |      ;

CODE_01D14E:
                       LDA.W $1A80,X                      ;01D14E|BD801A  |011A80;
                       AND.B #$3F                         ;01D151|293F    |      ;
                       ORA.B #$80                         ;01D153|0980    |      ;
                       STA.W $1A80,X                      ;01D155|9D801A  |011A80;
                       RTS                                 ;01D158|60      |      ;

; ==============================================================================
; Advanced Color Management and Processing
; Complex color management with advanced coordination systems
; ==============================================================================

CODE_01D159:
                       PHP                                 ;01D159|08      |      ;
                       REP #$30                           ;01D15A|C230    |      ;
                       LDA.W $192B                        ;01D15C|AD2B19  |01192B;
                       STA.W $192F                        ;01D15F|8D2F19  |01192F;
                       CMP.W #$7FFF                       ;01D162|C9FF7F  |      ;
                       BEQ CODE_01D170                     ;01D165|F009    |01D170;
                       JSR.W CODE_01D1E1                   ;01D167|20E1D1  |01D1E1;
                       JSR.W CODE_01D1F4                   ;01D16A|20F4D1  |01D1F4;
                       JSR.W CODE_01D20D                   ;01D16D|200DD2  |01D20D;

CODE_01D170:
                       PLP                                 ;01D170|28      |      ;
                       RTS                                 ;01D171|60      |      ;

; ==============================================================================
; Complex Color Component Processing Engine
; Advanced color component processing with RGB coordination
; ==============================================================================

                       db $08,$C2,$30,$AD,$2B,$19,$8D,$2F,$19,$C9,$FF,$7F,$F0,$5F,$CD,$2D ; 01D172
                       db $19,$F0,$5A,$AD,$2D,$19,$29,$1F,$00,$8D,$31,$19,$AD,$2B,$19,$29 ; 01D182
                       db $1F,$00,$CD,$31,$19,$90,$05,$8D,$2F,$19,$80,$03,$20,$E1,$D1,$AD ; 01D192
                       db $2D,$19,$29,$E0,$03,$8D,$31,$19,$AD,$2B,$19,$29,$E0,$03,$CD,$31 ; 01D1A2
                       db $19,$90,$08,$0D,$2F,$19,$8D,$2F,$19,$80,$03,$20,$F4,$D1,$AD,$2D ; 01D1B2
                       db $19,$29,$00,$7C,$8D,$31,$19,$AD,$2B,$19,$29,$00,$7C,$CD,$31,$19 ; 01D1C2
                       db $90,$08,$0D,$2F,$19,$8D,$2F,$19,$80,$03,$20,$0D,$D2,$28,$60       ; 01D1D2

; ==============================================================================
; Red Component Color Processing
; Handles red component color processing with precision control
; ==============================================================================

CODE_01D1E1:
                       LDA.W $192B                        ;01D1E1|AD2B19  |01192B;
                       AND.W #$001F                       ;01D1E4|291F00  |      ;
                       CMP.W #$001F                       ;01D1E7|C91F00  |      ;
                       BEQ CODE_01D1F0                     ;01D1EA|F004    |01D1F0;
                       INC A                               ;01D1EC|1A      |      ;
                       AND.W #$001F                       ;01D1ED|291F00  |      ;

CODE_01D1F0:
                       STA.W $192F                        ;01D1F0|8D2F19  |01192F;
                       RTS                                 ;01D1F3|60      |      ;

; ==============================================================================
; Green Component Color Processing
; Handles green component color processing with precision control
; ==============================================================================

CODE_01D1F4:
                       LDA.W $192B                        ;01D1F4|AD2B19  |01192B;
                       AND.W #$03E0                       ;01D1F7|29E003  |      ;
                       CMP.W #$03E0                       ;01D1FA|C9E003  |      ;
                       BEQ CODE_01D206                     ;01D1FD|F007    |01D206;
                       CLC                                 ;01D1FF|18      |      ;
                       ADC.W #$0020                       ;01D200|692000  |      ;
                       AND.W #$03E0                       ;01D203|29E003  |      ;

CODE_01D206:
                       ORA.W $192F                        ;01D206|0D2F19  |01192F;
                       STA.W $192F                        ;01D209|8D2F19  |01192F;
                       RTS                                 ;01D20C|60      |      ;

; ==============================================================================
; Blue Component Color Processing
; Handles blue component color processing with precision control
; ==============================================================================

CODE_01D20D:
                       LDA.W $192B                        ;01D20D|AD2B19  |01192B;
                       AND.W #$7C00                       ;01D210|29007C  |      ;
                       CMP.W #$7C00                       ;01D213|C9007C  |      ;
                       BEQ CODE_01D21F                     ;01D216|F007    |01D21F;
                       CLC                                 ;01D218|18      |      ;
                       ADC.W #$0400                       ;01D219|690004  |      ;
                       AND.W #$7C00                       ;01D21C|29007C  |      ;

CODE_01D21F:
                       ORA.W $192F                        ;01D21F|0D2F19  |01192F;
                       STA.W $192F                        ;01D222|8D2F19  |01192F;
                       RTS                                 ;01D225|60      |      ;

; ==============================================================================
; Advanced Color Fade Control System
; Complex color fade control with advanced timing coordination
; ==============================================================================

CODE_01D226:
                       PHP                                 ;01D226|08      |      ;
                       REP #$30                           ;01D227|C230    |      ;
                       LDA.W $192B                        ;01D229|AD2B19  |01192B;
                       STA.W $192F                        ;01D22C|8D2F19  |01192F;
                       BEQ CODE_01D23A                     ;01D22F|F009    |01D23A;
                       JSR.W CODE_01D2AC                   ;01D231|20ACD2  |01D2AC;
                       JSR.W CODE_01D2B9                   ;01D234|20B9D2  |01D2B9;
                       JSR.W CODE_01D2CC                   ;01D237|20CCD2  |01D2CC;

CODE_01D23A:
                       PLP                                 ;01D23A|28      |      ;
                       RTS                                 ;01D23B|60      |      ;

; ==============================================================================
; Advanced Color Interpolation Engine
; Complex color interpolation with advanced blending coordination
; ==============================================================================

CODE_01D23C:
                       PHP                                 ;01D23C|08      |      ;
                       REP #$30                           ;01D23D|C230    |      ;
                       LDA.W $192B                        ;01D23F|AD2B19  |01192B;
                       STA.W $192F                        ;01D242|8D2F19  |01192F;
                       CMP.W $192D                        ;01D245|CD2D19  |01192D;
                       BEQ CODE_01D2AA                     ;01D248|F060    |01D2AA;
                       LDA.W $192D                        ;01D24A|AD2D19  |01192D;
                       AND.W #$001F                       ;01D24D|291F00  |      ;
                       STA.W $1931                        ;01D250|8D3119  |011931;
                       LDA.W $192B                        ;01D253|AD2B19  |01192B;
                       AND.W #$001F                       ;01D256|291F00  |      ;
                       CMP.W $1931                        ;01D259|CD3119  |011931;
                       BEQ CODE_01D260                     ;01D25C|F002    |01D260;
                       BCS CODE_01D265                     ;01D25E|B005    |01D265;

CODE_01D260:
                       STA.W $192F                        ;01D260|8D2F19  |01192F;
                       BRA CODE_01D268                     ;01D263|8003    |01D268;

CODE_01D265:
                       JSR.W CODE_01D2AC                   ;01D265|20ACD2  |01D2AC;

CODE_01D268:
                       LDA.W $192D                        ;01D268|AD2D19  |01192D;
                       AND.W #$03E0                       ;01D26B|29E003  |      ;
                       STA.W $1931                        ;01D26E|8D3119  |011931;
                       LDA.W $192B                        ;01D271|AD2B19  |01192B;
                       AND.W #$03E0                       ;01D274|29E003  |      ;
                       CMP.W $1931                        ;01D277|CD3119  |011931;
                       BEQ CODE_01D27E                     ;01D27A|F002    |01D27E;
                       BCS CODE_01D286                     ;01D27C|B008    |01D286;

CODE_01D27E:
                       ORA.W $192F                        ;01D27E|0D2F19  |01192F;
                       STA.W $192F                        ;01D281|8D2F19  |01192F;
                       BRA CODE_01D289                     ;01D284|8003    |01D289;

CODE_01D286:
                       JSR.W CODE_01D2B9                   ;01D286|20B9D2  |01D2B9;

CODE_01D289:
                       LDA.W $192D                        ;01D289|AD2D19  |01192D;
                       AND.W #$7C00                       ;01D28C|29007C  |      ;
                       STA.W $1931                        ;01D28F|8D3119  |011931;
                       LDA.W $192B                        ;01D292|AD2B19  |01192B;
                       AND.W #$7C00                       ;01D295|29007C  |      ;
                       CMP.W $1931                        ;01D298|CD3119  |011931;
                       BEQ CODE_01D29F                     ;01D29B|F002    |01D29F;
                       BCS CODE_01D2A7                     ;01D29D|B008    |01D2A7;

CODE_01D29F:
                       ORA.W $192F                        ;01D29F|0D2F19  |01192F;
                       STA.W $192F                        ;01D2A2|8D2F19  |01192F;
                       BRA CODE_01D2AA                     ;01D2A5|8003    |01D2AA;

CODE_01D2A7:
                       JSR.W CODE_01D2CC                   ;01D2A7|20CCD2  |01D2CC;

CODE_01D2AA:
                       PLP                                 ;01D2AA|28      |      ;
                       RTS                                 ;01D2AB|60      |      ;

; ==============================================================================
; Red Component Fade Processing
; Handles red component fade processing with precision control
; ==============================================================================

CODE_01D2AC:
                       LDA.W $192B                        ;01D2AC|AD2B19  |01192B;
                       AND.W #$001F                       ;01D2AF|291F00  |      ;
                       BEQ CODE_01D2B5                     ;01D2B2|F001    |01D2B5;
                       DEC A                               ;01D2B4|3A      |      ;

CODE_01D2B5:
                       STA.W $192F                        ;01D2B5|8D2F19  |01192F;
                       RTS                                 ;01D2B8|60      |      ;

; ==============================================================================
; Green Component Fade Processing  
; Handles green component fade processing with precision control
; ==============================================================================

CODE_01D2B9:
                       LDA.W $192B                        ;01D2B9|AD2B19  |01192B;
                       AND.W #$03E0                       ;01D2BC|29E003  |      ;
                       BEQ CODE_01D2C5                     ;01D2BF|F004    |01D2C5;
                       SEC                                 ;01D2C1|38      |      ;
                       SBC.W #$0020                       ;01D2C2|E92000  |      ;

CODE_01D2C5:
                       ORA.W $192F                        ;01D2C5|0D2F19  |01192F;
                       STA.W $192F                        ;01D2C8|8D2F19  |01192F;
                       RTS                                 ;01D2CB|60      |      ;

; ==============================================================================
; Blue Component Fade Processing
; Handles blue component fade processing with precision control
; ==============================================================================

CODE_01D2CC:
                       LDA.W $192B                        ;01D2CC|AD2B19  |01192B;
                       AND.W #$7C00                       ;01D2CF|29007C  |      ;
                       BEQ CODE_01D2D8                     ;01D2D2|F004    |01D2D8;
                       SEC                                 ;01D2D4|38      |      ;
                       SBC.W #$0400                       ;01D2D5|E90004  |      ;

CODE_01D2D8:
                       ORA.W $192F                        ;01D2D8|0D2F19  |01192F;
                       STA.W $192F                        ;01D2DB|8D2F19  |01192F;
                       RTS                                 ;01D2DE|60      |      ;

; ==============================================================================
; Advanced Palette Buffer Management System
; Complex palette buffer management with DMA coordination
; ==============================================================================

CODE_01D2DF:
                       PHP                                 ;01D2DF|08      |      ;
                       REP #$30                           ;01D2E0|C230    |      ;
                       PHB                                 ;01D2E2|8B      |      ;
                       PEA.W $7F00                        ;01D2E3|F4007F  |017F00;
                       PLB                                 ;01D2E6|AB      |      ;
                       PLB                                 ;01D2E7|AB      |      ;
                       LDX.W #$0000                       ;01D2E8|A20000  |      ;
                       LDY.W #$0000                       ;01D2EB|A00000  |      ;
                       LDA.W #$0040                       ;01D2EE|A94000  |      ;

CODE_01D2F1:
                       PHA                                 ;01D2F1|48      |      ;
                       LDA.W $C588,X                      ;01D2F2|BD88C5  |7FC588;
                       STA.W $C608,Y                      ;01D2F5|9908C6  |7FC608;
                       INX                                 ;01D2F8|E8      |      ;
                       INX                                 ;01D2F9|E8      |      ;
                       INY                                 ;01D2FA|C8      |      ;
                       INY                                 ;01D2FB|C8      |      ;
                       PLA                                 ;01D2FC|68      |      ;
                       DEC A                               ;01D2FD|3A      |      ;
                       BNE CODE_01D2F1                     ;01D2FE|D0F1    |01D2F1;
                       PLB                                 ;01D300|AB      |      ;
                       SEP #$20                           ;01D301|E220    |      ;
                       REP #$10                           ;01D303|C210    |      ;
                       LDA.B #$F1                         ;01D305|A9F1    |      ;
                       STA.W $050A                        ;01D307|8D0A05  |01050A;
                       LDA.B #$0A                         ;01D30A|A90A    |      ;
                       STA.W $1935                        ;01D30C|8D3519  |011935;

; ==============================================================================
; Advanced Palette Animation Loop
; Complex palette animation loop with timing coordination
; ==============================================================================

CODE_01D30F:
                       PHP                                 ;01D30F|08      |      ;
                       REP #$30                           ;01D310|C230    |      ;
                       LDY.W #$0040                       ;01D312|A04000  |      ;
                       LDX.W #$0000                       ;01D315|A20000  |      ;

CODE_01D318:
                       LDA.L $7FC588,X                    ;01D318|BF88C57F|7FC588;
                       STA.W $192B                        ;01D31C|8D2B19  |01192B;
                       JSR.W CODE_01D226                   ;01D31F|2026D2  |01D226;
                       LDA.W $192F                        ;01D322|AD2F19  |01192F;
                       STA.L $7FC588,X                    ;01D325|9F88C57F|7FC588;
                       INX                                 ;01D329|E8      |      ;
                       INX                                 ;01D32A|E8      |      ;
                       DEY                                 ;01D32B|88      |      ;
                       BNE CODE_01D318                     ;01D32C|D0EA    |01D318;
                       PLP                                 ;01D32E|28      |      ;
                       LDA.B #$05                         ;01D32F|A905    |      ;
                       STA.W $1A46                        ;01D331|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D334|20F38D  |018DF3;
                       LDA.B #$10                         ;01D337|A910    |      ;
                       JSR.W CODE_01D6A9                   ;01D339|20A9D6  |01D6A9;
                       DEC.W $1935                        ;01D33C|CE3519  |011935;
                       BNE CODE_01D30F                     ;01D33F|D0CE    |01D30F;
                       JSR.W CODE_01D346                   ;01D341|2046D3  |01D346;
                       PLP                                 ;01D344|28      |      ;
                       RTS                                 ;01D345|60      |      ;

; ==============================================================================
; Advanced Memory Clear and Buffer Initialization
; Complex memory clear with advanced buffer initialization
; ==============================================================================

CODE_01D346:
                       PHB                                 ;01D346|8B      |      ;
                       LDA.B #$00                         ;01D347|A900    |      ;
                       STA.L $7F2000                      ;01D349|8F00207F|7F2000;
                       LDX.W #$2000                       ;01D34D|A20020  |      ;
                       LDY.W #$2001                       ;01D350|A00120  |      ;
                       LDA.B #$02                         ;01D353|A902    |      ;
                       XBA                                 ;01D355|EB      |      ;
                       LDA.B #$00                         ;01D356|A900    |      ;
                       MVN $7F,$7F                       ;01D358|547F7F  |      ;
                       PLB                                 ;01D35B|AB      |      ;
                       RTS                                 ;01D35C|60      |      ;
; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 6, Part 2)
; Advanced Graphics DMA Systems and Complex Memory Operations
; ==============================================================================

; ==============================================================================
; Advanced Graphics DMA Transfer System
; Complex DMA transfer with advanced graphics coordination
; ==============================================================================

CODE_01D35D:
                       LDX.W #$6A40                       ;01D35D|A2406A  |      ;
                       STX.W $192B                        ;01D360|8E2B19  |01192B;
                       STX.W $19E8                        ;01D363|8EE819  |0119E8;
                       LDA.B #$7F                         ;01D366|A97F    |      ;
                       STA.W $192D                        ;01D368|8D2D19  |01192D;
                       LDX.W #$0000                       ;01D36B|A20000  |      ;
                       STX.W $192E                        ;01D36E|8E2E19  |01192E;
                       LDX.W #$0100                       ;01D371|A20001  |      ;
                       STX.W $1930                        ;01D374|8E3019  |011930;

CODE_01D377:
                       JSR.W CODE_018DF3                   ;01D377|20F38D  |018DF3;
                       LDA.B #$07                         ;01D37A|A907    |      ;
                       STA.W $1A46                        ;01D37C|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D37F|20F38D  |018DF3;
                       JSR.W CODE_01D386                   ;01D382|2086D3  |01D386;
                       RTS                                 ;01D385|60      |      ;

; ==============================================================================
; Complex Graphics Processing and DMA Coordination
; Advanced graphics processing with DMA coordination systems
; ==============================================================================

CODE_01D386:
                       LDX.W $192B                        ;01D386|AE2B19  |01192B;
                       STX.W $1935                        ;01D389|8E3519  |011935;
                       LDA.W $192D                        ;01D38C|AD2D19  |01192D;
                       STA.W $1937                        ;01D38F|8D3719  |011937;
                       LDX.W #$2000                       ;01D392|A20020  |      ;
                       STX.W $1938                        ;01D395|8E3819  |011938;
                       LDX.W $1930                        ;01D398|AE3019  |011930;
                       STX.W $193A                        ;01D39B|8E3A19  |01193A;
                       LDA.B #$04                         ;01D39E|A904    |      ;
                       STA.W $1A46                        ;01D3A0|8D461A  |011A46;
                       JMP.W CODE_018DF3                   ;01D3A3|4CF38D  |018DF3;

; ==============================================================================
; Advanced Graphics Buffer Management
; Complex graphics buffer management with memory coordination
; ==============================================================================

CODE_01D3A6:
                       LDX.W #$7700                       ;01D3A6|A20077  |      ;
                       STX.W $192B                        ;01D3A9|8E2B19  |01192B;
                       STX.W $19EA                        ;01D3AC|8EEA19  |0119EA;

CODE_01D3AF:
                       LDA.B #$7F                         ;01D3AF|A97F    |      ;
                       STA.W $192D                        ;01D3B1|8D2D19  |01192D;
                       LDX.W #$0100                       ;01D3B4|A20001  |      ;
                       STX.W $192E                        ;01D3B7|8E2E19  |01192E;
                       LDX.W #$0080                       ;01D3BA|A28000  |      ;
                       STX.W $1930                        ;01D3BD|8E3019  |011930;
                       BRA CODE_01D377                     ;01D3C0|80B5    |01D377;

CODE_01D3C2:
                       LDX.W #$6A00                       ;01D3C2|A2006A  |      ;
                       STX.W $192B                        ;01D3C5|8E2B19  |01192B;
                       STX.W $19EA                        ;01D3C8|8EEA19  |0119EA;
                       BRA CODE_01D3AF                     ;01D3CB|80E2    |01D3AF;

; ==============================================================================
; Advanced Graphics Streaming System
; Complex graphics streaming with advanced coordination
; ==============================================================================

CODE_01D3CD:
                       LDX.W #$0F08                       ;01D3CD|A2080F  |      ;
                       STX.W $0501                        ;01D3D0|8E0105  |010501;
                       LDA.B #$1A                         ;01D3D3|A91A    |      ;
                       STA.W $0500                        ;01D3D5|8D0005  |010500;
                       LDA.B #$14                         ;01D3D8|A914    |      ;
                       JSR.W CODE_01D6BD                   ;01D3DA|20BDD6  |01D6BD;
                       LDX.W #$0000                       ;01D3DD|A20000  |      ;
                       STX.W $1933                        ;01D3E0|8E3319  |011933;
                       LDX.W #$0010                       ;01D3E3|A21000  |      ;
                       STX.W $1943                        ;01D3E6|8E4319  |011943;
                       LDA.B #$7F                         ;01D3E9|A97F    |      ;
                       STA.W $1937                        ;01D3EB|8D3719  |011937;

; ==============================================================================
; Advanced Graphics Multi-Layer Processing Loop
; Complex multi-layer graphics processing with coordination
; ==============================================================================

CODE_01D3EE:
                       LDX.W #$0000                       ;01D3EE|A20000  |      ;
                       STX.W $192B                        ;01D3F1|8E2B19  |01192B;
                       LDX.W #$2000                       ;01D3F4|A20020  |      ;
                       STX.W $192D                        ;01D3F7|8E2D19  |01192D;
                       LDX.W #$0008                       ;01D3FA|A20800  |      ;
                       JSR.W CODE_01D462                   ;01D3FD|2062D4  |01D462;
                       LDX.W $19E8                        ;01D400|AEE819  |0119E8;
                       STX.W $1935                        ;01D403|8E3519  |011935;
                       LDX.W $192D                        ;01D406|AE2D19  |01192D;
                       STX.W $1938                        ;01D409|8E3819  |011938;
                       LDX.W #$0100                       ;01D40C|A20001  |      ;
                       STX.W $193A                        ;01D40F|8E3A19  |01193A;
                       JSR.W CODE_018DF3                   ;01D412|20F38D  |018DF3;
                       LDA.B #$04                         ;01D415|A904    |      ;
                       STA.W $1A46                        ;01D417|8D461A  |011A46;
                       JSR.W CODE_0182D0                   ;01D41A|20D082  |0182D0;
                       LDX.W #$0100                       ;01D41D|A20001  |      ;
                       STX.W $192B                        ;01D420|8E2B19  |01192B;
                       LDX.W #$2100                       ;01D423|A20021  |      ;
                       STX.W $192D                        ;01D426|8E2D19  |01192D;
                       LDX.W #$0004                       ;01D429|A20400  |      ;
                       JSR.W CODE_01D462                   ;01D42C|2062D4  |01D462;
                       JSR.W CODE_018DF3                   ;01D42F|20F38D  |018DF3;
                       LDX.W $19EA                        ;01D432|AEEA19  |0119EA;
                       STX.W $1935                        ;01D435|8E3519  |011935;
                       LDX.W $192D                        ;01D438|AE2D19  |01192D;
                       STX.W $1938                        ;01D43B|8E3819  |011938;
                       LDX.W #$0080                       ;01D43E|A28000  |      ;
                       STX.W $193A                        ;01D441|8E3A19  |01193A;
                       LDA.B #$04                         ;01D444|A904    |      ;
                       STA.W $1A46                        ;01D446|8D461A  |011A46;
                       JSR.W CODE_0182D0                   ;01D449|20D082  |0182D0;
                       LDA.W $1933                        ;01D44C|AD3319  |011933;
                       CLC                                 ;01D44F|18      |      ;
                       ADC.B #$12                         ;01D450|6912    |      ;
                       AND.B #$1E                         ;01D452|291E    |      ;
                       STA.W $1933                        ;01D454|8D3319  |011933;
                       LDA.B #$10                         ;01D457|A910    |      ;
                       JSR.W CODE_01D6A9                   ;01D459|20A9D6  |01D6A9;
                       DEC.W $1943                        ;01D45C|CE4319  |011943;
                       BNE CODE_01D3EE                     ;01D45F|D08D    |01D3EE;
                       RTS                                 ;01D461|60      |      ;

; ==============================================================================
; Advanced Graphics Copy Engine
; Complex graphics copy engine with advanced memory management
; ==============================================================================

CODE_01D462:
                       PHP                                 ;01D462|08      |      ;
                       PHB                                 ;01D463|8B      |      ;
                       REP #$30                           ;01D464|C230    |      ;
                       PHX                                 ;01D466|DA      |      ;
                       PEA.W $7F00                        ;01D467|F4007F  |017F00;
                       PLB                                 ;01D46A|AB      |      ;
                       PLB                                 ;01D46B|AB      |      ;
                       LDA.L $00192B                      ;01D46C|AF2B1900|00192B;
                       CLC                                 ;01D470|18      |      ;
                       ADC.L $001933                      ;01D471|6F331900|001933;
                       TAX                                 ;01D475|AA      |      ;
                       LDA.L $00192D                      ;01D476|AF2D1900|00192D;
                       CLC                                 ;01D47A|18      |      ;
                       ADC.L $001933                      ;01D47B|6F331900|001933;
                       TAY                                 ;01D47F|A8      |      ;
                       PLA                                 ;01D480|68      |      ;

CODE_01D481:
                       PHA                                 ;01D481|48      |      ;
                       LDA.W $0000,X                      ;01D482|BD0000  |7F0000;
                       STA.W $0000,Y                      ;01D485|990000  |7F0000;
                       TXA                                 ;01D488|8A      |      ;
                       CLC                                 ;01D489|18      |      ;
                       ADC.W #$0020                       ;01D48A|692000  |      ;
                       TAX                                 ;01D48D|AA      |      ;
                       TYA                                 ;01D48E|98      |      ;
                       CLC                                 ;01D48F|18      |      ;
                       ADC.W #$0020                       ;01D490|692000  |      ;
                       TAY                                 ;01D493|A8      |      ;
                       PLA                                 ;01D494|68      |      ;
                       DEC A                               ;01D495|3A      |      ;
                       BNE CODE_01D481                     ;01D496|D0E9    |01D481;
                       PLB                                 ;01D498|AB      |      ;
                       PLP                                 ;01D499|28      |      ;
                       RTS                                 ;01D49A|60      |      ;

; ==============================================================================
; Advanced Character Animation Processing
; Complex character animation with advanced timing control
; ==============================================================================

CODE_01D49B:
                       PHP                                 ;01D49B|08      |      ;
                       JSR.W CODE_01B1EB                   ;01D49C|20EBB1  |01B1EB;
                       STX.W $192B                        ;01D49F|8E2B19  |01192B;
                       STA.W $192D                        ;01D4A2|8D2D19  |01192D;
                       REP #$30                           ;01D4A5|C230    |      ;
                       LDY.W #$000C                       ;01D4A7|A00C00  |      ;

CODE_01D4AA:
                       PHY                                 ;01D4AA|5A      |      ;
                       LDA.W $1A87,X                      ;01D4AB|BD871A  |011A87;
                       DEC A                               ;01D4AE|3A      |      ;
                       AND.W #$03FF                       ;01D4AF|29FF03  |      ;
                       STA.W $1A87,X                      ;01D4B2|9D871A  |011A87;
                       LDA.W #$0008                       ;01D4B5|A90800  |      ;
                       JSR.W CODE_01D6BD                   ;01D4B8|20BDD6  |01D6BD;
                       PLY                                 ;01D4BB|7A      |      ;
                       DEY                                 ;01D4BC|88      |      ;
                       BNE CODE_01D4AA                     ;01D4BD|D0EB    |01D4AA;
                       LDX.W $192B                        ;01D4BF|AE2B19  |01192B;
                       PHX                                 ;01D4C2|DA      |      ;
                       LDA.W #$0012                       ;01D4C3|A91200  |      ;
                       STA.W $192B                        ;01D4C6|8D2B19  |01192B;
                       JSR.W CODE_01D603                   ;01D4C9|2003D6  |01D603;
                       LDA.W #$0014                       ;01D4CC|A91400  |      ;
                       JSR.W CODE_01D6BD                   ;01D4CF|20BDD6  |01D6BD;
                       LDY.W #$0008                       ;01D4D2|A00800  |      ;

CODE_01D4D5:
                       LDA.W #$0004                       ;01D4D5|A90400  |      ;
                       STA.W $192B                        ;01D4D8|8D2B19  |01192B;
                       JSR.W CODE_01D603                   ;01D4DB|2003D6  |01D603;
                       LDA.W #$0004                       ;01D4DE|A90400  |      ;
                       JSR.W CODE_01D6BD                   ;01D4E1|20BDD6  |01D6BD;
                       DEY                                 ;01D4E4|88      |      ;
                       BNE CODE_01D4D5                     ;01D4E5|D0EE    |01D4D5;
                       PLX                                 ;01D4E7|FA      |      ;
                       STX.W $192B                        ;01D4E8|8E2B19  |01192B;
                       PHP                                 ;01D4EB|08      |      ;
                       SEP #$20                           ;01D4EC|E220    |      ;
                       REP #$10                           ;01D4EE|C210    |      ;
                       LDA.B #$03                         ;01D4F0|A903    |      ;
                       STA.W $1A72,X                      ;01D4F2|9D721A  |011A72;
                       PLP                                 ;01D4F5|28      |      ;
                       REP #$30                           ;01D4F6|C230    |      ;
                       LDY.W #$000C                       ;01D4F8|A00C00  |      ;

CODE_01D4FB:
                       PHY                                 ;01D4FB|5A      |      ;
                       LDA.W $1A87,X                      ;01D4FC|BD871A  |011A87;
                       INC A                               ;01D4FF|1A      |      ;
                       AND.W #$03FF                       ;01D500|29FF03  |      ;
                       STA.W $1A87,X                      ;01D503|9D871A  |011A87;
                       LDA.W #$0008                       ;01D506|A90800  |      ;
                       JSR.W CODE_01D6C4                   ;01D509|20C4D6  |01D6C4;
                       PLY                                 ;01D50C|7A      |      ;
                       DEY                                 ;01D50D|88      |      ;
                       BNE CODE_01D4FB                     ;01D50E|D0EB    |01D4FB;
                       SEP #$20                           ;01D510|E220    |      ;
                       REP #$10                           ;01D512|C210    |      ;
                       LDA.B #$10                         ;01D514|A910    |      ;
                       STA.W $1935                        ;01D516|8D3519  |011935;

; ==============================================================================
; Advanced Palette Animation Control System
; Complex palette animation control with timing coordination
; ==============================================================================

CODE_01D519:
                       PHP                                 ;01D519|08      |      ;
                       REP #$30                           ;01D51A|C230    |      ;
                       LDY.W #$0040                       ;01D51C|A04000  |      ;
                       LDX.W #$0000                       ;01D51F|A20000  |      ;

CODE_01D522:
                       LDA.L $7FC588,X                    ;01D522|BF88C57F|7FC588;
                       STA.W $192B                        ;01D526|8D2B19  |01192B;
                       JSR.W CODE_01D159                   ;01D529|2059D1  |01D159;
                       LDA.W $192F                        ;01D52C|AD2F19  |01192F;
                       STA.L $7FC588,X                    ;01D52F|9F88C57F|7FC588;
                       INX                                 ;01D533|E8      |      ;
                       INX                                 ;01D534|E8      |      ;
                       DEY                                 ;01D535|88      |      ;
                       BNE CODE_01D522                     ;01D536|D0EA    |01D522;
                       PLP                                 ;01D538|28      |      ;
                       LDA.B #$05                         ;01D539|A905    |      ;
                       STA.W $1A46                        ;01D53B|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D53E|20F38D  |018DF3;
                       LDA.B #$10                         ;01D541|A910    |      ;
                       JSR.W CODE_01D6C4                   ;01D543|20C4D6  |01D6C4;
                       DEC.W $1935                        ;01D546|CE3519  |011935;
                       BNE CODE_01D519                     ;01D549|D0CE    |01D519;
                       LDA.B #$70                         ;01D54B|A970    |      ;
                       STA.W $050B                        ;01D54D|8D0B05  |01050B;
                       LDA.B #$81                         ;01D550|A981    |      ;
                       STA.W $050A                        ;01D552|8D0A05  |01050A;
                       LDA.B #$0A                         ;01D555|A90A    |      ;
                       STA.W $192B                        ;01D557|8D2B19  |01192B;
                       JSR.W CODE_01D603                   ;01D55A|2003D6  |01D603;
                       JSR.W CODE_018DF3                   ;01D55D|20F38D  |018DF3;
                       LDA.B #$0E                         ;01D560|A90E    |      ;
                       STA.W $1935                        ;01D562|8D3519  |011935;

; ==============================================================================
; Advanced Color Blending Processing System
; Complex color blending processing with interpolation control
; ==============================================================================

CODE_01D565:
                       PHP                                 ;01D565|08      |      ;
                       REP #$30                           ;01D566|C230    |      ;
                       LDY.W #$0040                       ;01D568|A04000  |      ;
                       LDX.W #$0000                       ;01D56B|A20000  |      ;

CODE_01D56E:
                       LDA.L $7FC588,X                    ;01D56E|BF88C57F|7FC588;
                       STA.W $192B                        ;01D572|8D2B19  |01192B;
                       LDA.L $7FC608,X                    ;01D575|BF08C67F|7FC608;
                       STA.W $192D                        ;01D579|8D2D19  |01192D;
                       JSR.W CODE_01D23C                   ;01D57C|203CD2  |01D23C;
                       LDA.W $192F                        ;01D57F|AD2F19  |01192F;
                       STA.L $7FC588,X                    ;01D582|9F88C57F|7FC588;
                       INX                                 ;01D586|E8      |      ;
                       INX                                 ;01D587|E8      |      ;
                       DEY                                 ;01D588|88      |      ;
                       BNE CODE_01D56E                     ;01D589|D0E3    |01D56E;
                       PLP                                 ;01D58B|28      |      ;
                       JSR.W CODE_018DF3                   ;01D58C|20F38D  |018DF3;
                       LDA.B #$05                         ;01D58F|A905    |      ;
                       STA.W $1A46                        ;01D591|8D461A  |011A46;
                       LDA.B #$10                         ;01D594|A910    |      ;
                       JSR.W CODE_01D6C4                   ;01D596|20C4D6  |01D6C4;
                       DEC.W $1935                        ;01D599|CE3519  |011935;
                       BNE CODE_01D565                     ;01D59C|D0C7    |01D565;
                       LDA.B #$28                         ;01D59E|A928    |      ;
                       JSR.W CODE_01D6C4                   ;01D5A0|20C4D6  |01D6C4;
                       LDX.W #$0F08                       ;01D5A3|A2080F  |      ;
                       STX.W $0501                        ;01D5A6|8E0105  |010501;
                       LDA.W $1916                        ;01D5A9|AD1619  |011916;
                       AND.B #$1F                         ;01D5AC|291F    |      ;
                       STA.W $0500                        ;01D5AE|8D0005  |010500;
                       PLP                                 ;01D5B1|28      |      ;
                       RTS                                 ;01D5B2|60      |      ;

; ==============================================================================
; Advanced VRAM Management System
; Complex VRAM management with DMA coordination
; ==============================================================================

                       LDA.B #$80                         ;01D5B3|A980    |      ;
                       STA.W $2115                        ;01D5B5|8D1521  |012115;
                       LDX.W $192B                        ;01D5B8|AE2B19  |01192B;
                       STX.W $2116                        ;01D5BB|8E1621  |012116;
                       LDA.W $213A                        ;01D5BE|AD3A21  |01213A;
                       LDA.B #$81                         ;01D5C1|A981    |      ;
                       STA.W $4300                        ;01D5C3|8D0043  |014300;
                       LDA.B #$39                         ;01D5C6|A939    |      ;
                       STA.W $4301                        ;01D5C8|8D0143  |014301;
                       LDA.W $192D                        ;01D5CB|AD2D19  |01192D;
                       STA.W $4304                        ;01D5CE|8D0443  |014304;
                       LDX.W $192E                        ;01D5D1|AE2E19  |01192E;
                       STX.W $4302                        ;01D5D4|8E0243  |014302;
                       LDX.W $1930                        ;01D5D7|AE3019  |011930;
                       STX.W $4305                        ;01D5DA|8E0543  |014305;
                       LDA.B #$01                         ;01D5DD|A901    |      ;
                       STA.W $420B                        ;01D5DF|8D0B42  |01420B;
                       RTS                                 ;01D5E2|60      |      ;

; ==============================================================================
; Advanced Graphics Buffer Streaming System
; Complex graphics buffer streaming with memory coordination
; ==============================================================================

                       db $DA,$5A,$08,$8B,$E2,$20,$C2,$10,$AD,$51,$1A,$8D,$2C,$19,$9C,$51 ; 01D5E3
                       db $1A,$AD,$2B,$19,$D0,$03,$4C,$81,$D6,$C2,$30,$AD,$2D,$19,$80,$1B ; 01D5F3

; ==============================================================================
; Advanced Graphics Data Processing Engine
; Complex graphics data processing with advanced memory management
; ==============================================================================

CODE_01D603:
                       PHX                                 ;01D603|DA      |      ;
                       PHY                                 ;01D604|5A      |      ;
                       PHP                                 ;01D605|08      |      ;
                       PHB                                 ;01D606|8B      |      ;
                       SEP #$20                           ;01D607|E220    |      ;
                       REP #$10                           ;01D609|C210    |      ;
                       LDA.W $1A51                        ;01D60B|AD511A  |011A51;
                       STA.W $192C                        ;01D60E|8D2C19  |01192C;
                       STZ.W $1A51                        ;01D611|9C511A  |011A51;
                       LDA.W $192B                        ;01D614|AD2B19  |01192B;
                       BEQ CODE_01D681                     ;01D617|F068    |01D681;
                       REP #$30                           ;01D619|C230    |      ;
                       LDA.W #$6F7B                       ;01D61B|A97B6F  |      ;
                       LDX.W #$5000                       ;01D61E|A20050  |      ;
                       LDY.W #$0100                       ;01D621|A00001  |      ;

CODE_01D624:
                       STA.L $7F0000,X                    ;01D624|9F00007F|7F0000;
                       INX                                 ;01D628|E8      |      ;
                       INX                                 ;01D629|E8      |      ;
                       DEY                                 ;01D62A|88      |      ;
                       BNE CODE_01D624                     ;01D62B|D0F7    |01D624;
                       LDX.W #$C588                       ;01D62D|A288C5  |      ;
                       LDY.W #$4000                       ;01D630|A00040  |      ;
                       LDA.W #$007F                       ;01D633|A97F00  |      ;
                       MVN $7F,$7F                       ;01D636|547F7F  |      ;
                       LDX.W #$C488                       ;01D639|A288C4  |      ;
                       LDY.W #$6000                       ;01D63C|A00060  |      ;
                       LDA.W #$00FF                       ;01D63F|A9FF00  |      ;
                       MVN $7F,$7F                       ;01D642|547F7F  |      ;
                       LDX.W #$5000                       ;01D645|A20050  |      ;
                       LDY.W #$C588                       ;01D648|A088C5  |      ;
                       LDA.W #$007F                       ;01D64B|A97F00  |      ;
                       MVN $7F,$7F                       ;01D64E|547F7F  |      ;
                       LDX.W #$5000                       ;01D651|A20050  |      ;
                       LDY.W #$C488                       ;01D654|A088C4  |      ;
                       LDA.W #$00FF                       ;01D657|A9FF00  |      ;
                       MVN $7F,$7F                       ;01D65A|547F7F  |      ;
                       PLB                                 ;01D65D|AB      |      ;
                       SEP #$20                           ;01D65E|E220    |      ;
                       REP #$10                           ;01D660|C210    |      ;
                       JSR.W CODE_018DF3                   ;01D662|20F38D  |018DF3;
                       LDA.B #$06                         ;01D665|A906    |      ;
                       STA.W $1A46                        ;01D667|8D461A  |011A46;
                       JSR.W CODE_018DF3                   ;01D66A|20F38D  |018DF3;
                       LDA.W $192B                        ;01D66D|AD2B19  |01192B;
                       BMI CODE_01D6A5                     ;01D670|3033    |01D6A5;

CODE_01D672:
                       JSR.W CODE_0182D9                   ;01D672|20D982  |0182D9;
                       DEC.W $192B                        ;01D675|CE2B19  |01192B;
                       BNE CODE_01D672                     ;01D678|D0F8    |01D672;
                       PHB                                 ;01D67A|8B      |      ;
                       LDA.W $192C                        ;01D67B|AD2C19  |01192C;
                       STA.W $1A51                        ;01D67E|8D511A  |011A51;

CODE_01D681:
                       REP #$30                           ;01D681|C230    |      ;
                       LDX.W #$4000                       ;01D683|A20040  |      ;
                       LDY.W #$C588                       ;01D686|A088C5  |      ;
                       LDA.W #$007F                       ;01D689|A97F00  |      ;
                       MVN $7F,$7F                       ;01D68C|547F7F  |      ;
                       LDX.W #$6000                       ;01D68F|A20060  |      ;
                       LDY.W #$C488                       ;01D692|A088C4  |      ;
                       LDA.W #$00FF                       ;01D695|A9FF00  |      ;
                       MVN $7F,$7F                       ;01D698|547F7F  |      ;
                       PLB                                 ;01D69B|AB      |      ;
                       SEP #$20                           ;01D69C|E220    |      ;
                       REP #$10                           ;01D69E|C210    |      ;
                       LDA.B #$06                         ;01D6A0|A906    |      ;
                       STA.W $1A46                        ;01D6A2|8D461A  |011A46;

CODE_01D6A5:
                       PLP                                 ;01D6A5|28      |      ;
                       PLY                                 ;01D6A6|7A      |      ;
                       PLX                                 ;01D6A7|FA      |      ;
                       RTS                                 ;01D6A8|60      |      ;

; ==============================================================================
; Advanced Timing Control Functions
; Complex timing control with advanced synchronization
; ==============================================================================

CODE_01D6A9:
                       PHX                                 ;01D6A9|DA      |      ;
                       PHP                                 ;01D6AA|08      |      ;
                       LDX.W #$0000                       ;01D6AB|A20000  |      ;

CODE_01D6AE:
                       SEP #$20                           ;01D6AE|E220    |      ;
                       REP #$10                           ;01D6B0|C210    |      ;

CODE_01D6B2:
                       PHA                                 ;01D6B2|48      |      ;
                       JSR.W (DATA8_01D6CB,X)              ;01D6B3|FCCBD6  |01D6CB;
                       PLA                                 ;01D6B6|68      |      ;
                       DEC A                               ;01D6B7|3A      |      ;
                       BNE CODE_01D6B2                     ;01D6B8|D0F8    |01D6B2;
                       PLP                                 ;01D6BA|28      |      ;
                       PLX                                 ;01D6BB|FA      |      ;
                       RTS                                 ;01D6BC|60      |      ;

CODE_01D6BD:
                       PHX                                 ;01D6BD|DA      |      ;
                       PHP                                 ;01D6BE|08      |      ;
                       LDX.W #$0002                       ;01D6BF|A20200  |      ;
                       BRA CODE_01D6AE                     ;01D6C2|80EA    |01D6AE;

CODE_01D6C4:
                       PHX                                 ;01D6C4|DA      |      ;
                       PHP                                 ;01D6C5|08      |      ;
                       LDX.W #$0004                       ;01D6C6|A20400  |      ;
                       BRA CODE_01D6AE                     ;01D6C9|80E3    |01D6AE;

DATA8_01D6CB:
                       db $D1,$D6,$D0,$82,$D9,$82   ;01D6CB|        |      ;
                       JSL.L CODE_0096A0                   ;01D6D1|22A09600|0096A0;
                       RTS                                 ;01D6D5|60      |      ;

; ==============================================================================
; Advanced Character Processing Functions
; Complex character processing with battle coordination
; ==============================================================================

                       SEP #$20                           ;01D6D6|E220    |      ;
                       REP #$10                           ;01D6D8|C210    |      ;
                       LDA.B #$03                         ;01D6DA|A903    |      ;
                       STA.W $19E2                        ;01D6DC|8DE219  |0119E2;
                       BRA CODE_01D6E8                     ;01D6DF|8007    |01D6E8;

                       SEP #$20                           ;01D6E1|E220    |      ;
                       REP #$10                           ;01D6E3|C210    |      ;
                       STZ.W $19E2                        ;01D6E5|9CE219  |0119E2;

CODE_01D6E8:
                       LDA.W $19E2                        ;01D6E8|ADE219  |0119E2;
                       JSR.W CODE_01B1EB                   ;01D6EB|20EBB1  |01B1EB;
                       STX.W $19EA                        ;01D6EE|8EEA19  |0119EA;
                       STA.W $19E7                        ;01D6F1|8DE719  |0119E7;
                       LDA.W $1A7D,X                      ;01D6F4|BD7D1A  |011A7D;
                       STA.W $192D                        ;01D6F7|8D2D19  |01192D;
                       LDA.W $1A7E,X                      ;01D6FA|BD7E1A  |011A7E;
                       DEC A                               ;01D6FD|3A      |      ;
                       STA.W $192E                        ;01D6FE|8D2E19  |01192E;
                       JSR.W CODE_01880C                   ;01D701|200C88  |01880C;
                       LDA.L $7F8000,X                    ;01D704|BF00807F|7F8000;
                       INC A                               ;01D708|1A      |      ;
                       STA.L $7F8000,X                    ;01D709|9F00807F|7F8000;
                       STA.W $19D6                        ;01D70D|8DD619  |0119D6;
                       LDA.B #$01                         ;01D710|A901    |      ;
                       STA.W $194B                        ;01D712|8D4B19  |01194B;
                       STZ.W $1951                        ;01D715|9C5119  |011951;
                       LDA.W $19C9                        ;01D718|ADC919  |0119C9;
                       STA.W $19CA                        ;01D71B|8DCA19  |0119CA;
                       LDA.B #$00                         ;01D71E|A900    |      ;
                       XBA                                 ;01D720|EB      |      ;
                       LDA.W $19D6                        ;01D721|ADD619  |0119D6;
                       TAX                                 ;01D724|AA      |      ;
                       LDA.L $7FD0F4,X                    ;01D725|BFF4D07F|7FD0F4;
                       STA.W $19C9                        ;01D729|8DC919  |0119C9;
                       PHP                                 ;01D72C|08      |      ;
                       REP #$30                           ;01D72D|C230    |      ;
                       TXA                                 ;01D72F|8A      |      ;
                       ASL A                               ;01D730|0A      |      ;
                       ASL A                               ;01D731|0A      |      ;
                       TAX                                 ;01D732|AA      |      ;
                       LDA.L $7FCEF4,X                    ;01D733|BFF4CE7F|7FCEF4;
                       STA.W $19C5                        ;01D737|8DC519  |0119C5;
                       LDA.L $7FCEF6,X                    ;01D73A|BFF6CE7F|7FCEF6;
                       STA.W $19C7                        ;01D73E|8DC719  |0119C7;
                       PLP                                 ;01D741|28      |      ;
                       JSR.W CODE_0196D3                   ;01D742|20D396  |0196D3;
                       JSR.W CODE_019058                   ;01D745|205890  |019058;
                       LDA.W $19E2                        ;01D748|ADE219  |0119E2;
                       BNE CODE_01D76D                     ;01D74B|D020    |01D76D;
                       LDX.W #$0000                       ;01D74D|A20000  |      ;
                       LDA.W $19BD                        ;01D750|ADBD19  |0119BD;
                       INC A                               ;01D753|1A      |      ;
                       CLC                                 ;01D754|18      |      ;
                       ADC.L DATA8_0196CB,X                ;01D755|7FCB9601|0196CB;
                       AND.B #$1F                         ;01D759|291F    |      ;
                       STA.W $19BD                        ;01D75B|8DBD19  |0119BD;
                       LDA.W $19BF                        ;01D75E|ADBF19  |0119BF;
                       CLC                                 ;01D761|18      |      ;
                       ADC.L DATA8_0196CC,X                ;01D762|7FCC9601|0196CC;
                       AND.B #$0F                         ;01D766|290F    |      ;
                       STA.W $19BF                        ;01D768|8DBF19  |0119BF;
                       BRA CODE_01D78B                     ;01D76B|801E    |01D78B;

CODE_01D76D:
                       LDX.W #$0000                       ;01D76D|A20000  |      ;
                       LDA.W $19BD                        ;01D770|ADBD19  |0119BD;
                       CLC                                 ;01D773|18      |      ;
                       ADC.L DATA8_0196CB,X                ;01D774|7FCB9601|0196CB;
                       AND.B #$1F                         ;01D778|291F    |      ;
                       STA.W $19BD                        ;01D77A|8DBD19  |0119BD;
                       LDA.W $19BF                        ;01D77D|ADBF19  |0119BF;
                       DEC A                               ;01D780|3A      |      ;
                       CLC                                 ;01D781|18      |      ;
                       ADC.L DATA8_0196CC,X                ;01D782|7FCC9601|0196CC;
                       AND.B #$0F                         ;01D786|290F    |      ;
                       STA.W $19BF                        ;01D788|8DBF19  |0119BF;

CODE_01D78B:
                       JSR.W CODE_0188CD                   ;01D78B|20CD88  |0188CD;
                       LDX.W $192B                        ;01D78E|AE2B19  |01192B;
                       STX.W $195F                        ;01D791|8E5F19  |01195F;
                       REP #$30                           ;01D794|C230    |      ;
                       LDA.L DATA8_00F5EA                  ;01D796|AFEAF500|00F5EA;
                       STA.W $194D                        ;01D79A|8D4D19  |01194D;
                       SEP #$20                           ;01D79D|E220    |      ;
                       REP #$10                           ;01D79F|C210    |      ;
                       LDX.W #$A11F                       ;01D7A1|A21FA1  |      ;
                       STX.W $0506                        ;01D7A4|8E0605  |010506;
                       LDA.B #$0A                         ;01D7A7|A90A    |      ;
                       STA.W $0505                        ;01D7A9|8D0505  |010505;
                       LDA.B #$14                         ;01D7AC|A914    |      ;
                       STA.W $1926                        ;01D7AE|8D2619  |011926;

; ==============================================================================
; Advanced Animation State Control
; Complex animation state control with advanced timing
; ==============================================================================

CODE_01D7B1:
                       LDA.W $1926                        ;01D7B1|AD2619  |011926;
                       CMP.B #$0F                         ;01D7B4|C90F    |      ;
                       BCS CODE_01D7C0                     ;01D7B6|B008    |01D7C0;
                       CMP.B #$05                         ;01D7B8|C905    |      ;
                       BCS CODE_01D7C4                     ;01D7BA|B008    |01D7C4;
                       LDA.B #$39                         ;01D7BC|A939    |      ;
                       BRA CODE_01D7C6                     ;01D7BE|8006    |01D7C6;

CODE_01D7C0:
                       LDA.B #$37                         ;01D7C0|A937    |      ;
                       BRA CODE_01D7C6                     ;01D7C2|8002    |01D7C6;

CODE_01D7C4:
                       LDA.B #$36                         ;01D7C4|A936    |      ;

CODE_01D7C6:
                       LDX.W $19EA                        ;01D7C6|AEEA19  |0119EA;
                       JSR.W CODE_01CACF                   ;01D7C9|20CFCA  |01CACF;
                       BRA CODE_01D7CE                     ;01D7CC|8000    |01D7CE;

CODE_01D7CE:
                       LDX.W $194D                        ;01D7CE|AE4D19  |01194D;

CODE_01D7D1:
                       LDA.L DATA8_00F5F2,X                ;01D7D1|BFF2F500|00F5F2;
                       INX                                 ;01D7D5|E8      |      ;
                       CMP.B #$FF                         ;01D7D6|C9FF    |      ;
                       BEQ CODE_01D809                     ;01D7D8|F02F    |01D809;
                       CMP.B #$80                         ;01D7DA|C980    |      ;
                       BEQ CODE_01D7FC                     ;01D7DC|F01E    |01D7FC;
                       STA.W $1949                        ;01D7DE|8D4919  |011949;
                       LDA.B #$0C                         ;01D7E1|A90C    |      ;
                       STA.W $194A                        ;01D7E3|8D4A19  |01194A;
                       PHX                                 ;01D7E6|DA      |      ;
                       LDX.W $19EA                        ;01D7E7|AEEA19  |0119EA;
                       LDA.W $1A85,X                      ;01D7EA|BD851A  |011A85;
                       STA.W $192D                        ;01D7ED|8D2D19  |01192D;
                       LDA.W $1A87,X                      ;01D7F0|BD871A  |011A87;
                       STA.W $192E                        ;01D7F3|8D2E19  |01192E;
                       PLX                                 ;01D7F6|FA      |      ;
                       JSR.W CODE_019681                   ;01D7F7|208196  |019681;
                       BRA CODE_01D7D1                     ;01D7FA|80D5    |01D7D1;

CODE_01D7FC:
                       LDA.L DATA8_00F5F2,X                ;01D7FC|BFF2F500|00F5F2;
                       INX                                 ;01D800|E8      |      ;
                       STA.W $1949                        ;01D801|8D4919  |011949;
                       JSR.W CODE_019EDD                   ;01D804|20DD9E  |019EDD;
                       BRA CODE_01D7D1                     ;01D807|80C8    |01D7D1;

CODE_01D809:
                       STX.W $194D                        ;01D809|8E4D19  |01194D;
                       JSR.W CODE_0182D0                   ;01D80C|20D082  |0182D0;
                       LDA.W $1926                        ;01D80F|AD2619  |011926;
                       CMP.B #$0B                         ;01D812|C90B    |      ;
                       BNE CODE_01D81B                     ;01D814|D005    |01D81B;
                       LDA.B #$22                         ;01D816|A922    |      ;
                       JSR.W CODE_01BAAD                   ;01D818|20ADBA  |01BAAD;

CODE_01D81B:
                       DEC.W $1926                        ;01D81B|CE2619  |011926;
                       BPL CODE_01D7B1                     ;01D81E|1091    |01D7B1;
                       LDA.W $19E7                        ;01D820|ADE719  |0119E7;
