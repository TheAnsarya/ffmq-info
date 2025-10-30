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
; ==============================================================================
; BANK $0D - APU (Audio Processing Unit) Communication & Sound Driver Upload
; ==============================================================================
; Address Range: $0D8000-$0DFFFF (65,536 bytes)
; Purpose: SPC700 sound driver upload, audio data transfer, APU communication
; Systems: APU I/O ports ($2140-$2143), SPC700 audio processor interaction
; ==============================================================================

                       ORG $0D8000                          ;      |        |      ;

; ==============================================================================
; APU Entry Points and Jump Table
; ==============================================================================

; ------------------------------------------------------------------------------
; CODE_0D8000: Primary APU Upload Entry Point
; ------------------------------------------------------------------------------
; Entry point for uploading sound driver to SPC700 audio processor
; Called during game initialization to set up audio system
; Uses IPL (Initial Program Loader) handshake protocol with SPC700
; ------------------------------------------------------------------------------
          CODE_0D8000:
                       JMP.W CODE_0D802C                    ;0D8000|4C2C80  |0D802C; Jump to APU upload routine
                       db $EA                               ;0D8003|        |      ; NOP padding

; ------------------------------------------------------------------------------
; CODE_0D8004: Secondary APU Command Entry Point
; ------------------------------------------------------------------------------
; Entry point for sending commands/data to already-initialized SPC700
; Used for music/sound effect playback after driver is loaded
; ------------------------------------------------------------------------------
          CODE_0D8004:
                       JMP.W CODE_0D8147                    ;0D8004|4C4781  |0D8147; Jump to APU command routine
                       db $EA                               ;0D8007|        |      ; NOP padding

; ==============================================================================
; APU Data Tables - Sound Driver Module Addresses
; ==============================================================================
; These tables define the location and size of SPC700 driver modules
; Format: Each entry is 2 bytes pointing to compressed sound driver data
; The driver is split into multiple modules loaded sequentially
; ==============================================================================

; ------------------------------------------------------------------------------
; DATA8_0D8008: Module Count/Header
; ------------------------------------------------------------------------------
         DATA8_0D8008:
                       db $87                               ;0D8008|        |      ; Module count/header byte

; ------------------------------------------------------------------------------
; DATA8_0D8009: Module Pointer Table (Low Bytes)
; ------------------------------------------------------------------------------
; Points to start of each SPC700 driver module in this bank
; These are 16-bit addresses offset from bank start ($0D8000)
; ------------------------------------------------------------------------------
         DATA8_0D8009:
                       db $86,$AC,$A1,$78,$9D,$46,$A1,$78,$A1,$92,$A1;0D8009|        |      ; Module pointers

; ------------------------------------------------------------------------------
; DATA8_0D8014-0D8015: Module Size/Address Table
; ------------------------------------------------------------------------------
; Each pair defines: [size_low, size_high] for corresponding module
; Used to calculate transfer length during upload
; ------------------------------------------------------------------------------
         DATA8_0D8014:
                       db $00                               ;0D8014|        |      ; Module 0 size (low)
         DATA8_0D8015:
                       db $02,$00,$2C,$00,$48,$00,$1B,$80,$1A,$00,$1A;0D8015|        |      ; Module sizes/addresses
                       db $AE,$BD,$FF,$BD,$35,$BE,$7D,$BE,$59,$BE,$A1,$BE;0D8020|        |00FFBD; Continue module table

; ==============================================================================
; CODE_0D802C: Main APU Upload Routine
; ==============================================================================
; Uploads SPC700 sound driver to audio processor memory
; Protocol: Uses IPL (Initial Program Loader) handshake with SPC700
;
; APU I/O Port Usage ($2140-$2143):
;   $2140 (APUIO0): Command/handshake byte (read/write both sides)
;   $2141 (APUIO1): Parameter/data byte
;   $2142 (APUIO2): Address low byte for SPC700 RAM
;   $2143 (APUIO3): Address high byte for SPC700 RAM
;
; Upload Process:
;   1. Save CPU state (registers, flags, data bank, direct page)
;   2. Wait for SPC700 IPL ready signal ($BBAA in APUIO0/1)
;   3. Send each driver module sequentially
;   4. Use handshake protocol to sync with SPC700
;   5. Start execution at $0200 in SPC700 RAM
; ------------------------------------------------------------------------------
          CODE_0D802C:
                       PHB                                  ;0D802C|8B      |      ; Push data bank
                       PHD                                  ;0D802D|0B      |      ; Push direct page
                       PHP                                  ;0D802E|08      |      ; Push processor status
                       REP #$20                             ;0D802F|C220    |      ; 16-bit accumulator
                       REP #$10                             ;0D8031|C210    |      ; 16-bit index registers
                       PHA                                  ;0D8033|48      |      ; Push accumulator
                       PHX                                  ;0D8034|DA      |      ; Push X register
                       PHY                                  ;0D8035|5A      |      ; Push Y register
                       SEP #$20                             ;0D8036|E220    |      ; 8-bit accumulator

; ------------------------------------------------------------------------------
; Set up direct page and data bank for APU communication
; ------------------------------------------------------------------------------
                       LDA.B #$00                           ;0D8038|A900    |      ; Data bank = $00 (I/O registers)
                       PHA                                  ;0D803A|48      |      ;
                       PLB                                  ;0D803B|AB      |      ; Set data bank to $00
                       LDX.W #$0600                         ;0D803C|A20006  |      ; Direct page = $0600 (work RAM)
                       PHX                                  ;0D803F|DA      |      ;
                       PLD                                  ;0D8040|2B      |      ; Set direct page to $0600

; ------------------------------------------------------------------------------
; Wait for SPC700 IPL (Initial Program Loader) ready signal
; Expected: $BBAA in APUIO0+APUIO1 (signature from SPC700 IPL ROM)
; This confirms SPC700 is ready to receive data
; ------------------------------------------------------------------------------
                       LDX.W #$BBAA                         ;0D8041|A2AABB  |      ; IPL ready signature
                       CPX.W SNES_APUIO0                    ;0D8044|EC4021  |002140; Check APUIO0/1 for $AABB
                       BEQ CODE_0D8077                      ;0D8047|F02E    |0D8077; If IPL ready, start upload

; ------------------------------------------------------------------------------
; Check if sound driver already loaded (warm start detection)
; Verifies checksum values in work RAM to detect existing driver
; ------------------------------------------------------------------------------
                       LDY.B $F8                            ;0D8049|A4F8    |0006F8; Load checksum value 1
                       BEQ CODE_0D8077                      ;0D804B|F02A    |0D8077; If zero, proceed normally
                       CPY.B $48                            ;0D804D|C448    |000648; Compare with checksum value 2
                       BNE CODE_0D8077                      ;0D804F|D026    |0D8077; If mismatch, upload driver
                       LDA.B #$F0                           ;0D8051|A9F0    |      ; Check flag byte
                       CMP.B $00                            ;0D8053|C500    |000600; Compare against work RAM
                       BNE CODE_0D8077                      ;0D8055|D020    |0D8077; If not $F0, upload driver

; ------------------------------------------------------------------------------
; Warm start path: Sound driver already loaded, just reinitialize
; Sends reset command to SPC700 instead of uploading entire driver
; This saves significant time on soft resets
; ------------------------------------------------------------------------------
                       db $A9,$08,$8D,$41,$21,$A9,$00,$8D,$40,$21,$A2,$F8,$00,$9D,$FF,$05;0D8057|        |      ; Reset sequence
                       db $CA,$D0,$FA,$84,$48,$A9,$FF,$85,$05,$A9,$F0,$85,$00,$4C,$5C,$81;0D8067|        |      ; Continue reset

; ------------------------------------------------------------------------------
; CODE_0D8077: Begin IPL Upload Protocol
; ------------------------------------------------------------------------------
; Standard SPC700 IPL handshake sequence
; Protocol steps:
;   1. Wait for SPC700 to echo handshake byte
;   2. Send module address to $2142/$2143
;   3. Send command byte to $2141
;   4. Send handshake to $2140 ($CC to start)
;   5. Wait for SPC700 to echo handshake
;   6. Transfer data bytes with incrementing handshake
; ------------------------------------------------------------------------------
          CODE_0D8077:
                       CPX.W SNES_APUIO0                    ;0D8077|EC4021  |002140; Wait for SPC700 ready
                       BNE CODE_0D8077                      ;0D807A|D0FB    |0D8077; Loop until $BBAA confirmed

; ------------------------------------------------------------------------------
; Initialize upload parameters
; ------------------------------------------------------------------------------
                       LDX.W #$0000                         ;0D807C|A20000  |      ; Module index = 0
                       LDA.L DATA8_0D8014                   ;0D807F|AF14800D|0D8014; Load module address low
                       STA.W SNES_APUIO2                    ;0D8083|8D4221  |002142; Send to APUIO2 (SPC700 RAM addr low)
                       LDA.L DATA8_0D8015                   ;0D8086|AF15800D|0D8015; Load module address high
                       STA.W SNES_APUIO3                    ;0D808A|8D4321  |002143; Send to APUIO3 (SPC700 RAM addr high)
                       LDA.B #$01                           ;0D808D|A901    |      ; Command $01 = upload data
                       STA.W SNES_APUIO1                    ;0D808F|8D4121  |002141; Send command to APUIO1
                       LDA.B #$CC                           ;0D8092|A9CC    |      ; Initial handshake byte
                       STA.W SNES_APUIO0                    ;0D8094|8D4021  |002140; Send to APUIO0 (triggers SPC700)

; ------------------------------------------------------------------------------
; Wait for SPC700 to acknowledge handshake
; SPC700 IPL will echo handshake byte back to APUIO0 when ready
; ------------------------------------------------------------------------------
          CODE_0D8097:
                       CMP.W SNES_APUIO0                    ;0D8097|CD4021  |002140; Wait for echo
                       BNE CODE_0D8097                      ;0D809A|D0FB    |0D8097; Loop until handshake confirmed

; ==============================================================================
; CODE_0D809C: Module Data Transfer Loop
; ==============================================================================
; Transfers each driver module byte-by-byte to SPC700
; Uses indirect addressing to read module data from ROM
; Handshake increments each transfer to sync CPU/SPC700
; ==============================================================================
          CODE_0D809C:
                       LDA.B #$00                           ;0D809C|A900    |      ; Clear high byte
                       XBA                                  ;0D809E|EB      |      ; Swap to B accumulator

; ------------------------------------------------------------------------------
; Load module pointer from table
; $14-$16 = 24-bit pointer to module data in ROM
; ------------------------------------------------------------------------------
                       LDA.L DATA8_0D8008,X                 ;0D809F|BF08800D|0D8008; Get module pointer (low)
                       STA.B $14                            ;0D80A3|8514    |000614; Store to DP $14
                       LDA.L DATA8_0D8009,X                 ;0D80A5|BF09800D|0D8009; Get module pointer (mid)
                       STA.B $15                            ;0D80A9|8515    |000615; Store to DP $15
                       LDA.B #$0D                           ;0D80AB|A90D    |      ; Bank $0D
                       STA.B $16                            ;0D80AD|8516    |000616; Store to DP $16 (complete 24-bit pointer)

; ------------------------------------------------------------------------------
; Read module size from first 2 bytes of module data
; Module format: [size_low, size_high, data_bytes...]
; ------------------------------------------------------------------------------
                       LDY.W #$0000                         ;0D80AF|A00000  |      ; Y = 0 (offset into module)
                       LDA.B [$14],Y                        ;0D80B2|B714    |000614; Read size low byte
                       CLC                                  ;0D80B4|18      |      ;
                       ADC.B #$02                           ;0D80B5|6902    |      ; Add 2 (include size bytes)
                       STA.B $10                            ;0D80B7|8510    |000610; Store to $10 (total bytes low)
                       INY                                  ;0D80B9|C8      |      ; Y = 1
                       LDA.B [$14],Y                        ;0D80BA|B714    |000614; Read size high byte
                       ADC.B #$00                           ;0D80BC|6900    |      ; Add carry
                       STA.B $11                            ;0D80BE|8511    |000611; Store to $11 (total bytes high)
                       INY                                  ;0D80C0|C8      |      ; Y = 2 (start of actual data)

; ------------------------------------------------------------------------------
; CODE_0D80C1: Byte Transfer Loop
; ------------------------------------------------------------------------------
; Transfers module data byte-by-byte with handshake protocol
; Each byte requires handshake increment to confirm transfer
; ------------------------------------------------------------------------------
          CODE_0D80C1:
                       LDA.B [$14],Y                        ;0D80C1|B714    |000614; Read data byte from module
                       STA.W SNES_APUIO1                    ;0D80C3|8D4121  |002141; Send to APUIO1 (data port)
                       XBA                                  ;0D80C6|EB      |      ; Get handshake byte from B
                       STA.W SNES_APUIO0                    ;0D80C7|8D4021  |002140; Send to APUIO0 (triggers transfer)

; ------------------------------------------------------------------------------
; Wait for SPC700 to echo handshake (confirms byte received)
; ------------------------------------------------------------------------------
          CODE_0D80CA:
                       CMP.W SNES_APUIO0                    ;0D80CA|CD4021  |002140; Wait for echo
                       BNE CODE_0D80CA                      ;0D80CD|D0FB    |0D80CA; Loop until confirmed

; ------------------------------------------------------------------------------
; Increment handshake and continue
; ------------------------------------------------------------------------------
                       INC A                                ;0D80CF|1A      |      ; Increment handshake byte
                       XBA                                  ;0D80D0|EB      |      ; Save to B accumulator
                       INY                                  ;0D80D1|C8      |      ; Next byte in module
                       CPY.B $10                            ;0D80D2|C410    |000610; Compare with total size
                       BNE CODE_0D80C1                      ;0D80D4|D0EB    |0D80C1; Loop if more bytes

; ------------------------------------------------------------------------------
; Module transfer complete, prepare for next module
; ------------------------------------------------------------------------------
                       XBA                                  ;0D80D6|EB      |      ; Get handshake back
                       INC A                                ;0D80D7|1A      |      ; Increment handshake
                       INC A                                ;0D80D8|1A      |      ; +2 more (align for next)
                       INC A                                ;0D80D9|1A      |      ; +3 total
                       BNE CODE_0D80DD                      ;0D80DA|D001    |0D80DD; If not rolled over
                       db $1A                               ;0D80DC|        |      ; +4 if rolled over (skip $00)

          CODE_0D80DD:
                       INX                                  ;0D80DD|E8      |      ; Next module index
                       INX                                  ;0D80DE|E8      |      ; (2 bytes per entry)
                       CPX.W #$000C                         ;0D80DF|E00C00  |      ; 6 modules total (12 bytes)
                       BEQ CODE_0D8101                      ;0D80E2|F01D    |0D8101; If all modules done, start driver

; ------------------------------------------------------------------------------
; Send next module parameters to SPC700
; ------------------------------------------------------------------------------
                       XBA                                  ;0D80E4|EB      |      ; Get handshake
                       LDA.L DATA8_0D8014,X                 ;0D80E5|BF14800D|0D8014; Next module address low
                       STA.W SNES_APUIO2                    ;0D80E9|8D4221  |002142; Send to APUIO2
                       LDA.L DATA8_0D8015,X                 ;0D80EC|BF15800D|0D8015; Next module address high
                       STA.W SNES_APUIO3                    ;0D80F0|8D4321  |002143; Send to APUIO3
                       XBA                                  ;0D80F3|EB      |      ; Restore handshake
                       STA.W SNES_APUIO1                    ;0D80F4|8D4121  |002141; Send to APUIO1
                       STA.W SNES_APUIO0                    ;0D80F7|8D4021  |002140; Trigger transfer

; ------------------------------------------------------------------------------
; Wait for acknowledgment, then continue
; ------------------------------------------------------------------------------
          CODE_0D80FA:
                       CMP.W SNES_APUIO0                    ;0D80FA|CD4021  |002140; Wait for echo
                       BNE CODE_0D80FA                      ;0D80FD|D0FB    |0D80FA; Loop until confirmed
                       BRA CODE_0D809C                      ;0D80FF|809B    |0D809C; Transfer next module

; ==============================================================================
; CODE_0D8101: Start SPC700 Driver Execution
; ==============================================================================
; All modules transferred, now start execution at $0200 in SPC700 RAM
; This is the standard entry point for uploaded SPC700 programs
; ==============================================================================
          CODE_0D8101:
                       LDY.W #$0200                         ;0D8101|A00002  |      ; Execution address = $0200
                       STY.W SNES_APUIO2                    ;0D8104|8C4221  |002142; Send address to APUIO2/3
                       XBA                                  ;0D8107|EB      |      ; Get handshake
                       LDA.B #$00                           ;0D8108|A900    |      ; Command $00 = execute
                       STA.W SNES_APUIO1                    ;0D810A|8D4121  |002141; Send command
                       XBA                                  ;0D810D|EB      |      ; Restore handshake
                       STA.W SNES_APUIO0                    ;0D810E|8D4021  |002140; Trigger execution

; ------------------------------------------------------------------------------
; Wait for confirmation that driver started
; ------------------------------------------------------------------------------
          CODE_0D8111:
                       CMP.W SNES_APUIO0                    ;0D8111|CD4021  |002140; Wait for echo
                       BNE CODE_0D8111                      ;0D8114|D0FB    |0D8111; Loop until confirmed

; ------------------------------------------------------------------------------
; Clear work RAM used during upload
; ------------------------------------------------------------------------------
                       XBA                                  ;0D8116|EB      |      ; Get handshake to A
                       STA.W SNES_APUIO0                    ;0D8117|8D4021  |002140; Send final handshake
                       LDX.W #$0100                         ;0D811A|A20001  |      ; Clear 256 bytes
          CODE_0D811D:
                       STA.W $05FF,X                        ;0D811D|9DFF05  |0005FF; Clear work RAM
                       DEX                                  ;0D8120|CA      |      ; Decrement counter
                       BNE CODE_0D811D                      ;0D8121|D0FA    |0D811D; Loop until done

; ------------------------------------------------------------------------------
; Set up driver status flags
; ------------------------------------------------------------------------------
                       LDA.B #$FF                           ;0D8123|A9FF    |      ; Status byte $FF
                       STA.B $05                            ;0D8125|8505    |000605; Set status flag
                       REP #$20                             ;0D8127|C220    |      ; 16-bit accumulator

; ------------------------------------------------------------------------------
; Calculate and store checksum for warm start detection
; Checksum = driver_size + $4800 (base address in SPC700 RAM)
; ------------------------------------------------------------------------------
                       LDA.L DATA8_0D9D78                   ;0D8129|AF789D0D|0D9D78; Load driver size
                       CLC                                  ;0D812D|18      |      ;
                       ADC.W #$4800                         ;0D812E|690048  |      ; Add base address
                       STA.B $F8                            ;0D8131|85F8    |0006F8; Store checksum value 1
                       STA.B $48                            ;0D8133|8548    |000648; Store checksum value 2 (redundant)

; ------------------------------------------------------------------------------
; Delay to allow SPC700 initialization
; 2048 cycle delay ensures driver is fully initialized
; ------------------------------------------------------------------------------
                       LDX.W #$0800                         ;0D8135|A20008  |      ; Delay counter = 2048
          CODE_0D8138:
                       DEX                                  ;0D8138|CA      |      ; Decrement
                       BNE CODE_0D8138                      ;0D8139|D0FD    |0D8138; Loop until zero

; ------------------------------------------------------------------------------
; Set up driver callback pointer
; Points to this bank's command handler for ongoing communication
; ------------------------------------------------------------------------------
                       SEP #$20                             ;0D813B|E220    |      ; 8-bit accumulator
                       LDA.B #$80                           ;0D813D|A980    |      ; Callback address $0D8080
                       STA.B $FA                            ;0D813F|85FA    |0006FA; Store low byte
                       LDA.B #$0D                           ;0D8141|A90D    |      ; Bank $0D
                       STA.B $FB                            ;0D8143|85FB    |0006FB; Store bank byte
                       BRA CODE_0D8178                      ;0D8145|8031    |0D8178; Exit routine

; ==============================================================================
; CODE_0D8147: APU Command Handler
; ==============================================================================
; Entry point for sending commands to initialized SPC700 driver
; Called from main game code to play music, sound effects, adjust volume, etc.
; Command byte in $0600 determines operation
;
; Command Types:
;   $00: No operation (NOP)
;   $01: Load music track
;   $03: Play sound effect
;   $70+: Advanced commands (volume, pitch, etc.)
;   $F0+: System commands (reset, mute, etc.)
; ==============================================================================
          CODE_0D8147:
                       PHB                                  ;0D8147|8B      |      ; Push data bank
                       PHD                                  ;0D8148|0B      |      ; Push direct page
                       PHP                                  ;0D8149|08      |      ; Push processor status
                       REP #$20                             ;0D814A|C220    |      ; 16-bit accumulator
                       REP #$10                             ;0D814C|C210    |      ; 16-bit index registers
                       PHA                                  ;0D814E|48      |      ; Push accumulator
                       PHX                                  ;0D814F|DA      |      ; Push X register
                       PHY                                  ;0D8150|5A      |      ; Push Y register

; ------------------------------------------------------------------------------
; Set up environment for APU communication
; ------------------------------------------------------------------------------
                       SEP #$20                             ;0D8151|E220    |      ; 8-bit accumulator
                       LDA.B #$00                           ;0D8153|A900    |      ; Data bank = $00
                       PHA                                  ;0D8155|48      |      ;
                       PLB                                  ;0D8156|AB      |      ; Set data bank
                       LDX.W #$0600                         ;0D8157|A20006  |      ; Direct page = $0600
                       PHX                                  ;0D815A|DA      |      ;
                       PLD                                  ;0D815B|2B      |      ; Set direct page

; ------------------------------------------------------------------------------
; Read and dispatch command
; Command byte at $0600 determines operation
; ------------------------------------------------------------------------------
                       SEP #$20                             ;0D815C|E220    |      ; 8-bit accumulator
                       LDA.B $00                            ;0D815E|A500    |000600; Read command byte
                       STZ.B $00                            ;0D8160|6400    |000600; Clear command (mark processed)
                       BEQ CODE_0D8178                      ;0D8162|F014    |0D8178; If $00, NOP - exit
                       BMI CODE_0D8172                      ;0D8164|300C    |0D8172; If $80+, system command

; ------------------------------------------------------------------------------
; Standard command dispatch
; ------------------------------------------------------------------------------
                       CMP.B #$01                           ;0D8166|C901    |      ; Command $01 = load music
                       BEQ CODE_0D8183                      ;0D8168|F019    |0D8183; Handle music load
                       CMP.B #$03                           ;0D816A|C903    |      ; Command $03 = play SFX
                       BEQ CODE_0D8183                      ;0D816C|F015    |0D8183; Handle SFX play
                       CMP.B #$70                           ;0D816E|C970    |      ; Commands $70+ = advanced
                       BCS UNREACH_0D8175                   ;0D8170|B003    |0D8175; Handle advanced commands

; ------------------------------------------------------------------------------
; System command handler (commands $80-$FF)
; ------------------------------------------------------------------------------
          CODE_0D8172:
                       JMP.W CODE_0D85BA                    ;0D8172|4CBA85  |0D85BA; Jump to system handler

; ------------------------------------------------------------------------------
; Advanced command handler (commands $70-$7F)
; ------------------------------------------------------------------------------
       UNREACH_0D8175:
                       db $4C,$0E,$86                       ;0D8175|        |0D860E; Jump to advanced handler

; ------------------------------------------------------------------------------
; CODE_0D8178: Exit Routine
; ------------------------------------------------------------------------------
; Restores CPU state and returns to caller
; Called after command processing complete
; ------------------------------------------------------------------------------
          CODE_0D8178:
                       REP #$20                             ;0D8178|C220    |      ; 16-bit accumulator
                       REP #$10                             ;0D817A|C210    |      ; 16-bit index registers
                       PLY                                  ;0D817C|7A      |      ; Restore Y register
                       PLX                                  ;0D817D|FA      |      ; Restore X register
                       PLA                                  ;0D817E|68      |      ; Restore accumulator
                       PLP                                  ;0D817F|28      |      ; Restore processor status
                       PLD                                  ;0D8180|2B      |      ; Restore direct page
                       PLB                                  ;0D8181|AB      |      ; Restore data bank
                       RTL                                  ;0D8182|6B      |      ; Return to caller

; ==============================================================================
; CODE_0D8183: Music/SFX Load Handler
; ==============================================================================
; Handles command $01 (load music) and $03 (play SFX)
; Transfers music/sound data to SPC700 for playback
;
; Parameters (at direct page $0600+):
;   $01: Track number
;   $02-$03: Data address (16-bit)
;   Additional parameters vary by command
; ==============================================================================
          CODE_0D8183:
                       SEP #$20                             ;0D8183|E220    |      ; 8-bit accumulator
                       XBA                                  ;0D8185|EB      |      ; Save command to B
                       LDA.B $01                            ;0D8186|A501    |000601; Load track number
                       CMP.B $05                            ;0D8188|C505    |000605; Compare with current track
                       BNE CODE_0D81ED                      ;0D818A|D061    |0D81ED; If different, load new track

; ------------------------------------------------------------------------------
; Same track requested - check if parameters changed
; If parameters match, skip reload (already playing)
; ------------------------------------------------------------------------------
                       LDX.B $02                            ;0D818C|A602    |000602; Load parameter word
                       STX.B $06                            ;0D818E|8606    |000606; Store for comparison
                       TXA                                  ;0D8190|8A      |      ; A = parameter low byte
                       AND.B #$0F                           ;0D8191|290F    |      ; Mask low nibble
                       STA.W SNES_APUIO1                    ;0D8193|8D4121  |002141; Send to APUIO1

; ------------------------------------------------------------------------------
; Handshake protocol for parameter update
; ------------------------------------------------------------------------------
                       LDA.B #$84                           ;0D8196|A984    |      ; Handshake $84
          CODE_0D8198:
                       CMP.W SNES_APUIO0                    ;0D8198|CD4021  |002140; Wait for different value
                       BEQ CODE_0D8198                      ;0D819B|F0FB    |0D8198; Loop until SPC700 not $84
                       STA.W SNES_APUIO0                    ;0D819D|8D4021  |002140; Send handshake

          CODE_0D81A0:
                       CMP.W SNES_APUIO0                    ;0D81A0|CD4021  |002140; Wait for echo
                       BNE CODE_0D81A0                      ;0D81A3|D0FB    |0D81A0; Loop until confirmed
                       LDA.B #$00                           ;0D81A5|A900    |      ; Clear APUIO0
                       STA.W SNES_APUIO0                    ;0D81A7|8D4021  |002140; (prepare for next)

; ------------------------------------------------------------------------------
; Send high nibble of parameter
; ------------------------------------------------------------------------------
                       XBA                                  ;0D81AA|EB      |      ; Get command back
                       LDA.B $03                            ;0D81AB|A503    |000603; Load parameter high byte
                       LSR A                                ;0D81AD|4A      |      ; Shift right 4 bits
                       LSR A                                ;0D81AE|4A      |      ; (extract high nibble)
                       LSR A                                ;0D81AF|4A      |      ;
                       LSR A                                ;0D81B0|4A      |      ;
                       STA.W SNES_APUIO1                    ;0D81B1|8D4121  |002141; Send to APUIO1
                       LDA.B #$81                           ;0D81B4|A981    |      ; Handshake $81

          CODE_0D81B6:
                       CMP.W SNES_APUIO0                    ;0D81B6|CD4021  |002140; Wait for different
                       BEQ CODE_0D81B6                      ;0D81B9|F0FB    |0D81B6; Loop
                       STA.W SNES_APUIO0                    ;0D81BB|8D4021  |002140; Send handshake

          CODE_0D81BE:
                       CMP.W SNES_APUIO0                    ;0D81BE|CD4021  |002140; Wait for echo
                       BNE CODE_0D81BE                      ;0D81C1|D0FB    |0D81BE; Loop
                       XBA                                  ;0D81C3|EB      |      ; Restore command
                       STA.W SNES_APUIO0                    ;0D81C4|8D4021  |002140; Send to APUIO0

; ------------------------------------------------------------------------------
; Send combined low nibbles
; Packs low nibble of byte 2 and byte 3 into single byte
; ------------------------------------------------------------------------------
                       XBA                                  ;0D81C7|EB      |      ; Save command
                       LDA.B $02                            ;0D81C8|A502    |000602; Get byte 2
                       AND.B #$F0                           ;0D81CA|29F0    |      ; Keep high nibble
                       STA.B $02                            ;0D81CC|8502    |000602; Store back
                       LDA.B $03                            ;0D81CE|A503    |000603; Get byte 3
                       AND.B #$0F                           ;0D81D0|290F    |      ; Keep low nibble
                       ORA.B $02                            ;0D81D2|0502    |000602; Combine nibbles
                       STA.W SNES_APUIO1                    ;0D81D4|8D4121  |002141; Send to APUIO1
                       LDA.B #$81                           ;0D81D7|A981    |      ; Handshake $81

          CODE_0D81D9:
                       CMP.W SNES_APUIO0                    ;0D81D9|CD4021  |002140; Wait for different
                       BEQ CODE_0D81D9                      ;0D81DC|F0FB    |0D81D9; Loop
                       STA.W SNES_APUIO0                    ;0D81DE|8D4021  |002140; Send handshake

          CODE_0D81E1:
                       CMP.W SNES_APUIO0                    ;0D81E1|CD4021  |002140; Wait for echo
                       BNE CODE_0D81E1                      ;0D81E4|D0FB    |0D81E1; Loop
                       XBA                                  ;0D81E6|EB      |      ; Restore command
                       STA.W SNES_APUIO0                    ;0D81E7|8D4021  |002140; Send final handshake
                       JMP.W CODE_0D8178                    ;0D81EA|4C7881  |0D8178; Exit

; ==============================================================================
; CODE_0D81ED: Load New Track/SFX
; ==============================================================================
; Loads new music track or sound effect data to SPC700
; Different track number detected, perform full upload
; ==============================================================================
          CODE_0D81ED:
                       JSR.W CODE_0D8625                    ;0D81ED|202586  |0D8625; Call helper routine
                       LDA.B $05                            ;0D81F0|A505    |000605; Load current track status
                       BMI CODE_0D81FA                      ;0D81F2|3006    |0D81FA; If negative, skip backup
                       STA.B $09                            ;0D81F4|8509    |000609; Backup current track
                       LDX.B $06                            ;0D81F6|A606    |000606; Backup parameters
                       STX.B $0A                            ;0D81F8|860A    |00060A; Store backup

; ------------------------------------------------------------------------------
; Set up new track parameters
; ------------------------------------------------------------------------------
          CODE_0D81FA:
                       LDA.B $01                            ;0D81FA|A501    |000601; Load new track number
                       STA.W SNES_APUIO1                    ;0D81FC|8D4121  |002141; Send to APUIO1
                       STA.B $05                            ;0D81FF|8505    |000605; Update current track
                       STA.W SNES_WRMPYA                    ;0D8201|8D0242  |004202; Multiply A (track number)
                       LDA.B #$03                           ;0D8204|A903    |      ; By 3 (entry size)
                       STA.W SNES_WRMPYB                    ;0D8206|8D0342  |004203; WRMPYB triggers multiply

; ------------------------------------------------------------------------------
; Send track address to SPC700
; ------------------------------------------------------------------------------
                       LDX.B $02                            ;0D8209|A602    |000602; Load track address
                       STX.W SNES_APUIO2                    ;0D820B|8E4221  |002142; Send to APUIO2/3
                       STX.B $06                            ;0D820E|8606    |000606; Store for later
                       XBA                                  ;0D8210|EB      |      ; Swap accumulators

; ------------------------------------------------------------------------------
; Handshake for address transfer
; ------------------------------------------------------------------------------
          CODE_0D8211:
                       CMP.W SNES_APUIO0                    ;0D8211|CD4021  |002140; Wait for different
                       BEQ CODE_0D8211                      ;0D8214|F0FB    |0D8211; Loop
                       STA.W SNES_APUIO0                    ;0D8216|8D4021  |002140; Send handshake

          CODE_0D8219:
                       CMP.W SNES_APUIO0                    ;0D8219|CD4021  |002140; Wait for echo
                       BNE CODE_0D8219                      ;0D821C|D0FB    |0D8219; Loop

; ------------------------------------------------------------------------------
; Send data type command
; Command $02 = load track data to $1C00 in SPC700 RAM
; ------------------------------------------------------------------------------
                       LDA.B #$02                           ;0D821E|A902    |      ; Command $02
                       STA.W SNES_APUIO1                    ;0D8220|8D4121  |002141; Send command
                       LDX.W #$1C00                         ;0D8223|A2001C  |      ; SPC700 destination = $1C00
                       STX.W SNES_APUIO2                    ;0D8226|8E4221  |002142; Send address
                       STA.W SNES_APUIO0                    ;0D8229|8D4021  |002140; Trigger command

          CODE_0D822C:
                       CMP.W SNES_APUIO0                    ;0D822C|CD4021  |002140; Wait for echo
                       BNE CODE_0D822C                      ;0D822F|D0FB    |0D822C; Loop

; ------------------------------------------------------------------------------
; Look up track data address in table
; Uses hardware multiply result (track# × 3) as table index
; ------------------------------------------------------------------------------
                       LDX.W SNES_RDMPYL                    ;0D8231|AE1642  |004216; Get multiply result
                       LDA.L UNREACH_0DBDAE,X               ;0D8234|BFAEBD0D|0DBDAE; Load data ptr low
                       STA.B $14                            ;0D8238|8514    |000614; Store to DP
                       LDA.L UNREACH_0DBDAF,X               ;0D823A|BFAFBD0D|0DBDAF; Load data ptr mid
                       STA.B $15                            ;0D823E|8515    |000615; Store to DP
                       LDA.L UNREACH_0DBDB0,X               ;0D8240|BFB0BD0D|0DBDB0; Load data ptr bank
                       STA.B $16                            ;0D8244|8516    |000616; Store to DP

; ------------------------------------------------------------------------------
; Transfer track data to SPC700
; Calls helper routine to send data bytes
; ------------------------------------------------------------------------------
                       JSR.W CODE_0D85FA                    ;0D8246|20FA85  |0D85FA; Transfer data routine

