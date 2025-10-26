; ==============================================================================
; Bank $0D - Sound Driver Interface (SPC700 Communication)
; ==============================================================================
; This bank contains the sound driver interface code for communicating with
; the SPC700 audio processor. Handles music playback, sound effects, and
; audio data transfer to the sound CPU.
;
; Memory Range: $0D8000-$0DFFFF (32 KB)
;
; Major Sections:
; - SPC700 initialization and handshake
; - Music/SFX data transfer via APU I/O ports
; - Sound driver upload routine
; - Audio command interface
;
; Key Routines:
; - CODE_0D802C: Main SPC700 initialization
; - CODE_0D8004: Sound data transfer routine
; - DATA8_0D8008: Sound driver data pointers
;
; APU I/O Ports (used for communication):
; - $2140 (APUIO0): Command/status port
; - $2141 (APUIO1): Data port 1
; - $2142 (APUIO2): Data port 2
; - $2143 (APUIO3): Data port 3
;
; Related Files:
; - Sound driver binary (embedded in this bank)
; - Music/SFX data (referenced by pointers)
; ==============================================================================

	ORG $0D8000

; ==============================================================================
; Entry Points
; ==============================================================================

CODE_0D8000:
	JMP.W CODE_0D802C						;0D8000	; Jump to SPC700 init
	db $EA									;0D8003	; NOP padding

CODE_0D8004:
	JMP.W CODE_0D8147						;0D8004	; Jump to sound transfer
	db $EA									;0D8007	; NOP padding

; ==============================================================================
; Sound Driver Data Pointers
; ==============================================================================
; Pointers to sound driver code and data for upload to SPC700.
; ==============================================================================

DATA8_0D8008:
	db $87									;0D8008	; Driver size low byte

DATA8_0D8009:
	db $86,$AC,$A1,$78,$9D,$46,$A1,$78,$A1,$92,$A1	;0D8009	; Pointers

DATA8_0D8014:
	db $00									;0D8014	; Load address low

DATA8_0D8015:
	db $02,$00,$2C,$00,$48,$00,$1B,$80,$1A,$00,$1A	;0D8015	; Pointers
	db $AE,$BD,$FF,$BD,$35,$BE,$7D,$BE,$59,$BE,$A1,$BE	;0D8020

; ==============================================================================
; SPC700 Initialization Routine
; ==============================================================================
; Initializes the SPC700 audio processor and uploads the sound driver.
; This routine performs a handshake with the SPC700 and transfers the
; sound driver code to audio RAM.
;
; Process:
; 1. Check if SPC700 is ready (look for $BBAA signature)
; 2. Send initialization command
; 3. Upload sound driver in chunks
; 4. Verify each chunk transfer
; 5. Start sound driver execution
;
; Reference: https://wiki.superfamicom.org/spc700-reference
; ==============================================================================

CODE_0D802C:
	PHB										;0D802C	; Save data bank
	PHD										;0D802D	; Save direct page
	PHP										;0D802E	; Save processor status
	REP #$20								;0D802F	; 16-bit accumulator
	REP #$10								;0D8031	; 16-bit index
	PHA										;0D8033	; Save accumulator
	PHX										;0D8034	; Save X
	PHY										;0D8035	; Save Y
	SEP #$20								;0D8036	; 8-bit accumulator
	LDA.B #$00								;0D8038	; Bank $00
	PHA										;0D803A	; Push to stack
	PLB										;0D803B	; Pull to data bank
	LDX.W #$0600							;0D803C	; Direct page = $0600
	PHX										;0D803F	; Push to stack
	PLD										;0D8040	; Pull to direct page
	LDX.W #$BBAA							;0D8041	; SPC700 ready signature
	CPX.W SNES_APUIO0						;0D8044	; Check APU port 0/1
	BEQ CODE_0D8077							;0D8047	; Branch if ready
	LDY.B $F8								;0D8049	; Check communication flag
	BEQ CODE_0D8077							;0D804B	; Branch if not communicating
	CPY.B $48								;0D804D	; Compare with previous state
	BNE CODE_0D8077							;0D804F	; Branch if changed
	LDA.B #$F0								;0D8051	; Reset command
	CMP.B $00								;0D8053	; Check current command
	BNE CODE_0D8077							;0D8055	; Branch if different
	
	; Send reset sequence to SPC700
	db $A9,$08,$8D,$41,$21,$A9,$00,$8D,$40,$21,$A2,$F8,$00,$9D,$FF,$05	;0D8057
	db $CA,$D0,$FA,$84,$48,$A9,$FF,$85,$05,$A9,$F0,$85,$00,$4C,$5C,$81	;0D8067

CODE_0D8077:
	; Wait for SPC700 to be ready
	CPX.W SNES_APUIO0						;0D8077	; Check for ready signature
	BNE CODE_0D8077							;0D807A	; Loop until ready
	
	; Begin sound driver upload
	LDX.W #$0000							;0D807C	; Start at offset 0
	LDA.L DATA8_0D8014						;0D807F	; Load target address low
	STA.W SNES_APUIO2						;0D8083	; Send to APU port 2
	LDA.L DATA8_0D8015						;0D8086	; Load target address high
	STA.W SNES_APUIO3						;0D808A	; Send to APU port 3
	LDA.B #$01								;0D808D	; Upload start command
	STA.W SNES_APUIO1						;0D808F	; Send to APU port 1
	LDA.B #$CC								;0D8092	; Handshake value
	STA.W SNES_APUIO0						;0D8094	; Send to APU port 0

CODE_0D8097:
	; Wait for SPC700 acknowledgment
	CMP.W SNES_APUIO0						;0D8097	; Check port 0
	BNE CODE_0D8097							;0D809A	; Loop until acknowledged

; ==============================================================================
; Sound Driver Data Transfer Loop
; ==============================================================================
; Transfers sound driver data to SPC700 audio RAM in chunks.
; Each byte is sent with handshake verification.
; ==============================================================================

CODE_0D809C:
	LDA.B #$00								;0D809C	; Clear high byte
	XBA										;0D809E	; Swap A/B
	LDA.L DATA8_0D8008,X					;0D809F	; Load driver data byte
	STA.B $14								;0D80A3	; Store to transfer buffer
	LDA.L DATA8_0D8009,X					;0D80A5	; Load pointer low
	STA.B $15								;0D80A9	; Store to buffer
	LDA.B #$0D								;0D80AB	; Bank $0D
	STA.B $16								;0D80AD	; Store bank to buffer
	LDY.W #$0000							;0D80AF	; Start at offset 0
	LDA.B [$14],Y							;0D80B2	; Load data size
	CLC										;0D80B4	; Clear carry
	ADC.B #$02								;0D80B5	; Add 2 (header size)
	STA.B $10								;0D80B7	; Store total size low
	INY										;0D80B9	; Increment offset
	LDA.B [$14],Y							;0D80BA	; Load size high byte
	ADC.B #$00								;0D80BC	; Add carry
	STA.B $11								;0D80BE	; Store total size high
	INY										;0D80C0	; Increment offset

CODE_0D80C1:
	; Transfer data bytes with handshake
	LDA.B [$14],Y							;0D80C1	; Load data byte
	STA.W SNES_APUIO1						;0D80C3	; Send to APU port 1
	XBA										;0D80C6	; Swap to counter byte
	STA.W SNES_APUIO0						;0D80C7	; Send to APU port 0

CODE_0D80CA:
	; Wait for acknowledgment
	CMP.W SNES_APUIO0						;0D80CA	; Check port 0
	BNE CODE_0D80CA							;0D80CD	; Loop until acknowledged
	INY										;0D80CF	; Next byte
	XBA										;0D80D0	; Swap back
	INC A									;0D80D1	; Increment counter
	XBA										;0D80D2	; Swap to counter
	CPY.B $10								;0D80D3	; Check if done
	BNE CODE_0D80C1							;0D80D5	; Loop if more data
	INX										;0D80D7	; Next data block
	CPX.W #$000B							;0D80D8	; Check if all blocks done
	BNE CODE_0D809C							;0D80DB	; Loop if more blocks
	
	; Sound driver upload complete
	LDA.B #$00								;0D80DD	; Zero value
	STA.W SNES_APUIO1						;0D80DF	; Clear port 1
	LDA.L DATA8_0D8014						;0D80E2	; Load start address low
	STA.W SNES_APUIO2						;0D80E6	; Send to port 2
	LDA.L DATA8_0D8015						;0D80E9	; Load start address high
	STA.W SNES_APUIO3						;0D80ED	; Send to port 3
	LDA.B #$00								;0D80F0	; Start execution command
	XBA										;0D80F2	; Swap

CODE_0D80F3:
	; Final handshake to start driver
	STA.W SNES_APUIO0						;0D80F3	; Send to port 0
	CMP.W SNES_APUIO0						;0D80F6	; Wait for ack
	BNE CODE_0D80F3							;0D80F9	; Loop until acknowledged
	
	PLY										;0D80FB	; Restore Y
	PLX										;0D80FC	; Restore X
	PLA										;0D80FD	; Restore A
	PLP										;0D80FE	; Restore processor status
	PLD										;0D80FF	; Restore direct page
	PLB										;0D8100	; Restore data bank
	RTL										;0D8101	; Return

; ==============================================================================
; [Additional Sound Driver Code]
; ==============================================================================
; The remaining code (CODE_0D8147 onwards) includes:
; - Music playback commands
; - Sound effect triggering
; - Volume control
; - Audio fade in/out
; - Driver communication protocol
;
; Complete code available in original bank_0D.asm
; Total bank size: ~2,900 lines including sound driver data
; ==============================================================================

; [Remaining sound driver code continues to $0DFFFF]
; See original bank_0D.asm for complete implementation

; ==============================================================================
; End of Bank $0D
; ==============================================================================
; Total size: 32 KB (complete bank)
; Primary content: SPC700 sound driver interface
; Related: Audio data in other banks
;
; Key functions documented:
; - SPC700 initialization and handshake
; - Sound driver upload protocol
; - APU I/O port communication
;
; Remaining work:
; - Extract embedded sound driver binary
; - Document audio command protocol
; - Map music/SFX data locations
; - Analyze sound driver assembly code
; ==============================================================================
