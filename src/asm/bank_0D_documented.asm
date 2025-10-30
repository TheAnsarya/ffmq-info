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

; ------------------------------------------------------------------------------
; Continue: Track Data Transfer (from CODE_0D8249)
; ------------------------------------------------------------------------------
                       LDY.B $14                            ;0D8249|A414    |000614; Get pointer offset
                       STZ.B $14                            ;0D824B|6414    |000614; Clear pointer low
                       STZ.B $15                            ;0D824D|6415    |000615; Clear pointer mid
                       LDA.B [$14],Y                        ;0D824F|B714    |000614; Read size low from data
                       XBA                                  ;0D8251|EB      |      ; Swap to B accumulator
                       INY                                  ;0D8252|C8      |      ; Next byte
                       BNE CODE_0D825A                      ;0D8253|D005    |0D825A; If no page wrap
                       db $E6,$16,$A0,$00,$80               ;0D8255|        |000016; Increment bank, reset Y

          CODE_0D825A:
                       LDA.B [$14],Y                        ;0D825A|B714    |000614; Read size high
                       PHA                                  ;0D825C|48      |      ; Push size high
                       INY                                  ;0D825D|C8      |      ; Next byte
                       BNE CODE_0D8265                      ;0D825E|D005    |0D8265; If no page wrap
                       db $E6,$16,$A0,$00,$80               ;0D8260|        |000016; Increment bank, reset Y

          CODE_0D8265:
                       XBA                                  ;0D8265|EB      |      ; Get size low from B
                       PHA                                  ;0D8266|48      |      ; Push size low
                       PLX                                  ;0D8267|FA      |      ; Pull both size bytes to X
                       LDA.B #$05                           ;0D8268|A905    |      ; Handshake start value $05
                       XBA                                  ;0D826A|EB      |      ; Save to B accumulator

; ==============================================================================
; CODE_0D826B: Data Block Transfer Loop
; ==============================================================================
; Transfers data blocks (3 bytes at a time) with handshake protocol
; Each iteration sends: [byte1 to APUIO2, byte2 to APUIO3, handshake to APUIO0]
; X register counts down from data size
; ==============================================================================
          CODE_0D826B:
                       LDA.B [$14],Y                        ;0D826B|B714    |000614; Read data byte 1
                       STA.W SNES_APUIO2                    ;0D826D|8D4221  |002142; Send to APUIO2
                       INY                                  ;0D8270|C8      |      ; Next byte
                       BNE CODE_0D8278                      ;0D8271|D005    |0D8278; If no page wrap
                       db $E6,$16,$A0,$00,$80               ;0D8273|        |000016; Increment bank, reset Y

          CODE_0D8278:
                       LDA.B [$14],Y                        ;0D8278|B714    |000614; Read data byte 2
                       STA.W SNES_APUIO3                    ;0D827A|8D4321  |002143; Send to APUIO3
                       INY                                  ;0D827D|C8      |      ; Next byte
                       BNE CODE_0D8285                      ;0D827E|D005    |0D8285; If no page wrap
                       db $E6,$16,$A0,$00,$80               ;0D8280|        |000016; Increment bank, reset Y

          CODE_0D8285:
                       XBA                                  ;0D8285|EB      |      ; Get handshake from B
                       STA.W SNES_APUIO0                    ;0D8286|8D4021  |002140; Send to trigger transfer

          CODE_0D8289:
                       CMP.W SNES_APUIO0                    ;0D8289|CD4021  |002140; Wait for SPC700 echo
                       BNE CODE_0D8289                      ;0D828C|D0FB    |0D8289; Loop until confirmed
                       INC A                                ;0D828E|1A      |      ; Increment handshake
                       BNE CODE_0D8292                      ;0D828F|D001    |0D8292; If not $00
                       INC A                                ;0D8291|1A      |      ; Skip $00 (use $01 instead)

          CODE_0D8292:
                       XBA                                  ;0D8292|EB      |      ; Save handshake to B
                       DEX                                  ;0D8293|CA      |      ; Decrement byte counter
                       DEX                                  ;0D8294|CA      |      ; (2 bytes per iteration)
                       BPL CODE_0D826B                      ;0D8295|10D4    |0D826B; Loop if more data

; ==============================================================================
; Post-Transfer Initialization
; ==============================================================================
; After track data transfer complete, set up playback parameters
; Initializes channel buffers and prepares for audio playback
; ==============================================================================

; ------------------------------------------------------------------------------
; Set up multiplication for later calculations
; ------------------------------------------------------------------------------
                       LDA.B #$20                           ;0D8297|A920    |      ; Multiply by $20
                       STA.W SNES_WRMPYB                    ;0D8299|8D0342  |004203; Set multiplier
                       REP #$20                             ;0D829C|C220    |      ; 16-bit accumulator

; ------------------------------------------------------------------------------
; Clear channel buffers ($0688-$06A7 and $06C8-$06E7)
; These store active channel states for music playback
; ------------------------------------------------------------------------------
                       LDX.W #$0000                         ;0D829E|A20000  |      ; Start at offset 0
          CODE_0D82A1:
                       STZ.B $88,X                          ;0D82A1|7488    |000688; Clear buffer 1 entry
                       STZ.B $C8,X                          ;0D82A3|74C8    |0006C8; Clear buffer 2 entry
                       INX                                  ;0D82A5|E8      |      ; Next entry
                       INX                                  ;0D82A6|E8      |      ; (2 bytes per entry)
                       CPX.W #$0020                         ;0D82A7|E02000  |      ; 16 entries total (32 bytes)
                       BNE CODE_0D82A1                      ;0D82AA|D0F5    |0D82A1; Loop until all cleared

; ------------------------------------------------------------------------------
; Calculate pattern table base address
; Uses hardware multiply result (track# × $20) as offset
; ------------------------------------------------------------------------------
                       LDA.W SNES_RDMPYL                    ;0D82AC|AD1642  |004216; Get multiply result
                       TAX                                  ;0D82AF|AA      |      ; X = pattern table offset
                       CLC                                  ;0D82B0|18      |      ; Clear carry
                       ADC.W #$0020                         ;0D82B1|692000  |      ; Add $20 (next entry)
                       STA.B $12                            ;0D82B4|8512    |000612; Store end offset

; ------------------------------------------------------------------------------
; Set up buffer pointers
; $14 = $06A8 (pattern data buffer)
; $16 = $06C8 (secondary buffer)
; ------------------------------------------------------------------------------
                       LDA.W #$06A8                         ;0D82B6|A9A806  |      ; Buffer 1 address
                       STA.B $14                            ;0D82B9|8514    |000614; Store to DP
                       LDA.W #$06C8                         ;0D82BB|A9C806  |      ; Buffer 2 address
                       STA.B $16                            ;0D82BE|8516    |000616; Store to DP

; ==============================================================================
; CODE_0D82C0: Pattern Table Processing Loop
; ==============================================================================
; Processes pattern data from table, distributing to buffers
; Handles pattern assignment to audio channels
; ==============================================================================
          CODE_0D82C0:
                       LDA.L UNREACH_0DBEA1,X               ;0D82C0|BFA1BE0D|0DBEA1; Load pattern table entry
                       STA.B ($14)                          ;0D82C4|9214    |000614; Store to buffer 1
                       INC.B $14                            ;0D82C6|E614    |000614; Advance pointer
                       INC.B $14                            ;0D82C8|E614    |000614; (2 bytes per entry)
                       LDY.W #$0000                         ;0D82CA|A00000  |      ; Y = search offset

; ------------------------------------------------------------------------------
; Search for matching pattern in channel buffer
; ------------------------------------------------------------------------------
          CODE_0D82CD:
                       CMP.W $0628,Y                        ;0D82CD|D92806  |000628; Compare with channel entry
                       BEQ CODE_0D82E1                      ;0D82D0|F00F    |0D82E1; If match found
                       INY                                  ;0D82D2|C8      |      ; Next channel
                       INY                                  ;0D82D3|C8      |      ; (2 bytes per channel)
                       CPY.W #$0020                         ;0D82D4|C02000  |      ; 16 channels total
                       BNE CODE_0D82CD                      ;0D82D7|D0F4    |0D82CD; Loop until all checked

; ------------------------------------------------------------------------------
; No match found - store to buffer 2
; ------------------------------------------------------------------------------
                       STA.B ($16)                          ;0D82D9|9216    |000616; Store to buffer 2
                       INC.B $16                            ;0D82DB|E616    |000616; Advance pointer
                       INC.B $16                            ;0D82DD|E616    |000616; (2 bytes per entry)
                       BRA CODE_0D82E4                      ;0D82DF|8003    |0D82E4; Continue

; ------------------------------------------------------------------------------
; Match found - update channel buffer
; ------------------------------------------------------------------------------
          CODE_0D82E1:
                       STA.W $0688,Y                        ;0D82E1|998806  |000688; Store to channel buffer

          CODE_0D82E4:
                       INX                                  ;0D82E4|E8      |      ; Next table entry
                       INX                                  ;0D82E5|E8      |      ; (2 bytes per entry)
                       CPX.B $12                            ;0D82E6|E412    |000612; Check if at end
                       BNE CODE_0D82C0                      ;0D82E8|D0D6    |0D82C0; Loop if more entries

; ------------------------------------------------------------------------------
; Check if buffer 2 has any entries
; If empty, skip advanced processing
; ------------------------------------------------------------------------------
                       LDA.B $C8                            ;0D82EA|A5C8    |0006C8; Check buffer 2 first entry
                       BNE CODE_0D82F1                      ;0D82EC|D003    |0D82F1; If not empty, continue
                       JMP.W CODE_0D84DD                    ;0D82EE|4CDD84  |0D84DD; If empty, skip to end

; ==============================================================================
; CODE_0D82F1: Sound Effect Processing
; ==============================================================================
; Processes sound effects from buffer 2
; Calculates sizes and prepares data for upload to SPC700
; ==============================================================================
          CODE_0D82F1:
                       STZ.B $17                            ;0D82F1|6417    |000617; Clear size accumulator low
                       SEP #$20                             ;0D82F3|E220    |      ; 8-bit accumulator
                       LDA.B #$03                           ;0D82F5|A903    |      ; Multiply by 3
                       STA.W SNES_WRMPYA                    ;0D82F7|8D0242  |004202; Set multiplicand
                       LDX.W #$0000                         ;0D82FA|A20000  |      ; Start at first entry

; ------------------------------------------------------------------------------
; Loop through buffer 2 entries, accumulate sizes
; ------------------------------------------------------------------------------
          CODE_0D82FD:
                       LDA.B $C8,X                          ;0D82FD|B5C8    |0006C8; Load buffer 2 entry
                       BEQ CODE_0D8340                      ;0D82FF|F03F    |0D8340; If zero, end of list
                       DEC A                                ;0D8301|3A      |      ; Convert to 0-based index
                       STA.W SNES_WRMPYB                    ;0D8302|8D0342  |004203; Multiply (entry × 3)
                       NOP                                  ;0D8305|EA      |      ; Wait for multiply (8 cycles)
                       NOP                                  ;0D8306|EA      |      ;
                       PHX                                  ;0D8307|DA      |      ; Save buffer index

; ------------------------------------------------------------------------------
; Look up sound effect data pointer using multiply result
; ------------------------------------------------------------------------------
                       LDX.W SNES_RDMPYL                    ;0D8308|AE1642  |004216; Get multiply result (index × 3)
                       LDA.L DATA8_0DBDFF,X                 ;0D830B|BFFFBD0D|0DBDFF; Load data pointer low
                       STA.B $14                            ;0D830F|8514    |000614; Store to DP
                       LDA.L DATA8_0DBE00,X                 ;0D8311|BF00BE0D|0DBE00; Load data pointer mid
                       STA.B $15                            ;0D8315|8515    |000615; Store to DP
                       LDA.L DATA8_0DBE01,X                 ;0D8317|BF01BE0D|0DBE01; Load data pointer bank
                       STA.B $16                            ;0D831B|8516    |000616; Store to DP

; ------------------------------------------------------------------------------
; Transfer SFX data to SPC700
; ------------------------------------------------------------------------------
                       JSR.W CODE_0D85FA                    ;0D831D|20FA85  |0D85FA; Call transfer routine

; ------------------------------------------------------------------------------
; Read SFX size from data (first 2 bytes)
; ------------------------------------------------------------------------------
                       LDY.B $14                            ;0D8320|A414    |000614; Get final pointer offset
                       STZ.B $14                            ;0D8322|6414    |000614; Clear pointer low
                       STZ.B $15                            ;0D8324|6415    |000615; Clear pointer mid
                       LDA.B [$14],Y                        ;0D8326|B714    |000614; Read size low byte
                       CLC                                  ;0D8328|18      |      ; Clear carry
                       ADC.B $17                            ;0D8329|6517    |000617; Add to accumulator
                       STA.B $17                            ;0D832B|8517    |000617; Store total size low
                       INY                                  ;0D832D|C8      |      ; Next byte
                       BNE CODE_0D8335                      ;0D832E|D005    |0D8335; If no page wrap
                       db $E6,$16,$A0,$00,$80               ;0D8330|        |000016; Increment bank, reset Y

          CODE_0D8335:
                       LDA.B [$14],Y                        ;0D8335|B714    |000614; Read size high byte
                       ADC.B $18                            ;0D8337|6518    |000618; Add to accumulator high
                       STA.B $18                            ;0D8339|8518    |000618; Store total size high
                       PLX                                  ;0D833B|FA      |      ; Restore buffer index
                       INX                                  ;0D833C|E8      |      ; Next entry
                       INX                                  ;0D833D|E8      |      ; (2 bytes per entry)
                       BRA CODE_0D82FD                      ;0D833E|80BD    |0D82FD; Loop for next SFX

; ==============================================================================
; CODE_0D8340: Channel Allocation and Memory Management
; ==============================================================================
; Finds free channels and allocates memory for new patterns
; Manages SPC700 RAM space for audio data
; ==============================================================================
          CODE_0D8340:
                       LDX.W #$0000                         ;0D8340|A20000  |      ; Start at channel 0
                       REP #$20                             ;0D8343|C220    |      ; 16-bit accumulator

; ------------------------------------------------------------------------------
; Find first free channel slot
; ------------------------------------------------------------------------------
          CODE_0D8345:
                       LDA.B $28,X                          ;0D8345|B528    |000628; Check channel status
                       BEQ CODE_0D834D                      ;0D8347|F004    |0D834D; If free, found slot
                       INX                                  ;0D8349|E8      |      ; Next channel
                       INX                                  ;0D834A|E8      |      ; (2 bytes per channel)
                       BRA CODE_0D8345                      ;0D834B|80F8    |0D8345; Keep searching

; ------------------------------------------------------------------------------
; Check if new data fits in available SPC700 RAM
; SPC700 has limited RAM ($0000-$FFFF), must not overflow
; ------------------------------------------------------------------------------
          CODE_0D834D:
                       LDA.B $48,X                          ;0D834D|B548    |000648; Get current RAM position
                       CLC                                  ;0D834F|18      |      ; Clear carry
                       ADC.B $17                            ;0D8350|6517    |000617; Add new data size
                       BCS CODE_0D835C                      ;0D8352|B008    |0D835C; If overflow, reallocate
                       CMP.W #$D200                         ;0D8354|C900D2  |      ; Compare with RAM limit
                       BCS CODE_0D835C                      ;0D8357|B003    |0D835C; If >= $D200, reallocate
                       JMP.W CODE_0D840E                    ;0D8359|4C0E84  |0D840E; Data fits, proceed

; ==============================================================================
; CODE_0D835C: Memory Reallocation
; ==============================================================================
; SPC700 RAM is full - need to free old patterns and reorganize
; Finds patterns to evict and compacts memory
; ==============================================================================
          CODE_0D835C:
                       LDX.W #$001E                         ;0D835C|A21E00  |      ; Start from last channel
          CODE_0D835F:
                       LDA.B $86,X                          ;0D835F|B586    |000686; Check channel active
                       BNE CODE_0D8367                      ;0D8361|D004    |0D8367; If active, found last used
                       DEX                                  ;0D8363|CA      |      ; Previous channel
                       DEX                                  ;0D8364|CA      |      ; (2 bytes per channel)
                       BNE CODE_0D835F                      ;0D8365|D0F8    |0D835F; Loop until found

          CODE_0D8367:
                       STX.B $24                            ;0D8367|8624    |000624; Store last used channel
                       LDX.W #$0000                         ;0D8369|A20000  |      ; Start from first channel

; ------------------------------------------------------------------------------
; Find first free slot in pattern buffer
; ------------------------------------------------------------------------------
          CODE_0D836C:
                       LDA.B $88,X                          ;0D836C|B588    |000688; Check pattern buffer
                       BEQ CODE_0D8377                      ;0D836E|F007    |0D8377; If free, found slot
                       INX                                  ;0D8370|E8      |      ; Next slot
                       INX                                  ;0D8371|E8      |      ; (2 bytes per slot)
                       CPX.W #$0020                         ;0D8372|E02000  |      ; 16 slots total
                       BNE CODE_0D836C                      ;0D8375|D0F5    |0D836C; Loop

          CODE_0D8377:
                       CPX.B $24                            ;0D8377|E424    |000624; Compare with last used
                       BNE CODE_0D8387                      ;0D8379|D00C    |0D8387; If different, proceed

; ------------------------------------------------------------------------------
; All channels full - clear from this point
; ------------------------------------------------------------------------------
          CODE_0D837B:
                       STZ.B $28,X                          ;0D837B|7428    |000628; Clear channel status
                       INX                                  ;0D837D|E8      |      ; Next channel
                       INX                                  ;0D837E|E8      |      ; (2 bytes per channel)
                       CPX.W #$0020                         ;0D837F|E02000  |      ; All channels
                       BNE CODE_0D837B                      ;0D8382|D0F7    |0D837B; Loop
                       JMP.W CODE_0D840E                    ;0D8384|4C0E84  |0D840E; Continue processing

; ==============================================================================
; CODE_0D8387: Channel Reallocation - Pattern Swap
; ==============================================================================
; Reallocates SPC700 RAM by swapping old patterns with new ones
; Manages channel assignments and updates SPC700 memory pointers
; ==============================================================================
          CODE_0D8387:
                       SEP #$20                             ;0D8387|E220    |      ; 8-bit accumulator
                       LDA.B #$07                           ;0D8389|A907    |      ; APU command $07
                       STA.W SNES_APUIO1                    ;0D838B|8D4121  |002141; Send swap command
                       STZ.B $10                            ;0D838E|6410    |000610; Clear handshake counter
                       LDY.W #$0000                         ;0D8390|A00000  |      ; Y = channel index
                       REP #$20                             ;0D8393|C220    |      ; 16-bit accumulator

; ------------------------------------------------------------------------------
; Find patterns to swap out
; ------------------------------------------------------------------------------
          CODE_0D8395:
                       LDA.W $0688,Y                        ;0D8395|B98806  |000688; Check pattern buffer
                       BEQ CODE_0D83A2                      ;0D8398|F008    |0D83A2; If empty, found slot
          CODE_0D839A:
                       INY                                  ;0D839A|C8      |      ; Next slot
                       INY                                  ;0D839B|C8      |      ; (2 bytes per slot)
                       CPY.B $24                            ;0D839C|C424    |000624; Check if at last used
                       BNE CODE_0D8395                      ;0D839E|D0F5    |0D8395; Continue search
                       db $80,$62                           ;0D83A0|        |0D8404; Jump to cleanup

          CODE_0D83A2:
                       TYX                                  ;0D83A2|BB      |      ; X = found slot
                       BRA CODE_0D83A9                      ;0D83A3|8004    |0D83A9; Continue

          CODE_0D83A5:
                       LDA.B $88,X                          ;0D83A5|B588    |000688; Check pattern buffer
                       BNE CODE_0D83B1                      ;0D83A7|D008    |0D83B1; If occupied, swap it

          CODE_0D83A9:
                       INX                                  ;0D83A9|E8      |      ; Next slot
                       INX                                  ;0D83AA|E8      |      ;
                       CPX.B $24                            ;0D83AB|E424    |000624; Check limit
                       BNE CODE_0D83A5                      ;0D83AD|D0F6    |0D83A5; Continue search
                       BRA CODE_0D8404                      ;0D83AF|8053    |0D8404; Jump to cleanup

; ==============================================================================
; CODE_0D83B1: Perform Pattern Swap
; ==============================================================================
; Swaps old pattern with new pattern in SPC700 RAM
; Updates channel assignments and memory pointers
; ==============================================================================
          CODE_0D83B1:
                       STZ.B $28,X                          ;0D83B1|7428    |000628; Clear old channel
                       STZ.B $88,X                          ;0D83B3|7488    |000688; Clear old pattern
                       STA.W $0628,Y                        ;0D83B5|992806  |000628; Assign new channel
                       LDA.B $48,X                          ;0D83B8|B548    |000648; Get old RAM address
                       STA.W SNES_APUIO2                    ;0D83BA|8D4221  |002142; Send to SPC700
                       SEP #$20                             ;0D83BD|E220    |      ; 8-bit accumulator
                       LDA.B $10                            ;0D83BF|A510    |000610; Get handshake
                       STA.W SNES_APUIO0                    ;0D83C1|8D4021  |002140; Send to SPC700

          CODE_0D83C4:
                       CMP.W SNES_APUIO0                    ;0D83C4|CD4021  |002140; Wait for echo
                       BNE CODE_0D83C4                      ;0D83C7|D0FB    |0D83C4; Loop
                       INC.B $10                            ;0D83C9|E610    |000610; Increment handshake
                       REP #$20                             ;0D83CB|C220    |      ; 16-bit accumulator

; ------------------------------------------------------------------------------
; Send additional swap parameters
; ------------------------------------------------------------------------------
                       LDA.W $0648,Y                        ;0D83CD|B94806  |000648; Get new data address
                       STA.W SNES_APUIO2                    ;0D83D0|8D4221  |002142; Send to SPC700
                       SEP #$20                             ;0D83D3|E220    |      ; 8-bit accumulator
                       LDA.B $10                            ;0D83D5|A510    |000610; Get handshake
                       STA.W SNES_APUIO0                    ;0D83D7|8D4021  |002140; Send to SPC700

          CODE_0D83DA:
                       CMP.W SNES_APUIO0                    ;0D83DA|CD4021  |002140; Wait for echo
                       BNE CODE_0D83DA                      ;0D83DD|D0FB    |0D83DA; Loop
                       INC.B $10                            ;0D83DF|E610    |000610; Increment handshake
                       REP #$20                             ;0D83E1|C220    |      ; 16-bit accumulator

; ------------------------------------------------------------------------------
; Transfer pattern size data
; ------------------------------------------------------------------------------
                       LDA.B $68,X                          ;0D83E3|B568    |000668; Get pattern size
                       STA.W SNES_APUIO2                    ;0D83E5|8D4221  |002142; Send to SPC700
                       STA.W $0668,Y                        ;0D83E8|996806  |000668; Store in new slot
                       CLC                                  ;0D83EB|18      |      ; Clear carry
                       ADC.W $0648,Y                        ;0D83EC|794806  |000648; Add base address
                       STA.W $064A,Y                        ;0D83EF|994A06  |00064A; Store end address
                       SEP #$20                             ;0D83F2|E220    |      ; 8-bit accumulator
                       LDA.B $10                            ;0D83F4|A510    |000610; Get handshake
                       STA.W SNES_APUIO0                    ;0D83F6|8D4021  |002140; Send to SPC700

          CODE_0D83F9:
                       CMP.W SNES_APUIO0                    ;0D83F9|CD4021  |002140; Wait for echo
                       BNE CODE_0D83F9                      ;0D83FC|D0FB    |0D83F9; Loop
                       INC.B $10                            ;0D83FE|E610    |000610; Increment handshake
                       REP #$20                             ;0D8400|C220    |      ; 16-bit accumulator
                       BRA CODE_0D839A                      ;0D8402|8096    |0D839A; Continue swapping

; ==============================================================================
; CODE_0D8404: Cleanup After Reallocation
; ==============================================================================
; Clears remaining channel slots after reallocation complete
; ==============================================================================
          CODE_0D8404:
                       TYX                                  ;0D8404|BB      |      ; X = current position
          CODE_0D8405:
                       STZ.B $28,X                          ;0D8405|7428    |000628; Clear channel
                       INX                                  ;0D8407|E8      |      ; Next channel
                       INX                                  ;0D8408|E8      |      ;
                       CPX.W #$0020                         ;0D8409|E02000  |      ; All 16 channels
                       BNE CODE_0D8405                      ;0D840C|D0F7    |0D8405; Loop

; ==============================================================================
; CODE_0D840E: Sound Effect Upload
; ==============================================================================
; Uploads sound effect data to SPC700 for playback
; Similar to music upload but for shorter SFX samples
; ==============================================================================
          CODE_0D840E:
                       SEP #$20                             ;0D840E|E220    |      ; 8-bit accumulator
                       LDA.B #$03                           ;0D8410|A903    |      ; Multiply by 3
                       STA.W SNES_WRMPYA                    ;0D8412|8D0242  |004202; Set multiplier
                       STA.W SNES_APUIO1                    ;0D8415|8D4121  |002141; Send command $03
                       LDX.W #$0000                         ;0D8418|A20000  |      ; Start at channel 0

; ------------------------------------------------------------------------------
; Find next free channel for SFX
; ------------------------------------------------------------------------------
          CODE_0D841B:
                       LDA.B $28,X                          ;0D841B|B528    |000628; Check channel status
                       BEQ CODE_0D8423                      ;0D841D|F004    |0D8423; If free, use it
                       INX                                  ;0D841F|E8      |      ; Next channel
                       INX                                  ;0D8420|E8      |      ;
                       BRA CODE_0D841B                      ;0D8421|80F8    |0D841B; Continue search

; ------------------------------------------------------------------------------
; Set SFX destination address in SPC700 RAM
; ------------------------------------------------------------------------------
          CODE_0D8423:
                       STX.B $24                            ;0D8423|8624    |000624; Store channel index
                       LDA.B $48,X                          ;0D8425|B548    |000648; Get RAM address low
                       STA.W SNES_APUIO2                    ;0D8427|8D4221  |002142; Send to SPC700
                       LDA.B $49,X                          ;0D842A|B549    |000649; Get RAM address high
                       STA.W SNES_APUIO3                    ;0D842C|8D4321  |002143; Send to SPC700
                       LDA.B #$00                           ;0D842F|A900    |      ; Initial handshake
                       STA.W SNES_APUIO0                    ;0D8431|8D4021  |002140; Send to trigger

          CODE_0D8434:
                       CMP.W SNES_APUIO0                    ;0D8434|CD4021  |002140; Wait for echo
                       BNE CODE_0D8434                      ;0D8437|D0FB    |0D8434; Loop
                       INC A                                ;0D8439|1A      |      ; Handshake = $01
                       STA.B $10                            ;0D843A|8510    |000610; Store handshake
                       LDX.W #$0000                         ;0D843C|A20000  |      ; Buffer index

; ==============================================================================
; CODE_0D843F: SFX Data Transfer Loop
; ==============================================================================
; Transfers sound effect data blocks to SPC700
; Processes each SFX in buffer sequentially
; ==============================================================================
          CODE_0D843F:
                       SEP #$20                             ;0D843F|E220    |      ; 8-bit accumulator
                       LDA.B $C8,X                          ;0D8441|B5C8    |0006C8; Check buffer entry
                       BNE CODE_0D8448                      ;0D8443|D003    |0D8448; If valid, process
                       JMP.W CODE_0D84DD                    ;0D8445|4CDD84  |0D84DD; If empty, done

; ------------------------------------------------------------------------------
; Process SFX entry
; ------------------------------------------------------------------------------
          CODE_0D8448:
                       LDY.B $24                            ;0D8448|A424    |000624; Get channel index
                       STA.W $0628,Y                        ;0D844A|992806  |000628; Assign to channel
                       DEC A                                ;0D844D|3A      |      ; Convert to 0-based
                       STA.W SNES_WRMPYB                    ;0D844E|8D0342  |004203; Multiply (SFX# × 3)
                       NOP                                  ;0D8451|EA      |      ; Wait for multiply
                       NOP                                  ;0D8452|EA      |      ;
                       PHX                                  ;0D8453|DA      |      ; Save buffer index

; ------------------------------------------------------------------------------
; Look up SFX data pointer in table
; ------------------------------------------------------------------------------
                       LDX.W SNES_RDMPYL                    ;0D8454|AE1642  |004216; Get table index
                       LDA.L DATA8_0DBDFF,X                 ;0D8457|BFFFBD0D|0DBDFF; Load pointer low
                       STA.B $14                            ;0D845B|8514    |000614; Store to DP
                       LDA.L DATA8_0DBE00,X                 ;0D845D|BF00BE0D|0DBE00; Load pointer mid
                       STA.B $15                            ;0D8461|8515    |000615; Store to DP
                       LDA.L DATA8_0DBE01,X                 ;0D8463|BF01BE0D|0DBE01; Load pointer bank
                       STA.B $16                            ;0D8467|8516    |000616; Store to DP

; ------------------------------------------------------------------------------
; Call data transfer helper
; ------------------------------------------------------------------------------
                       JSR.W CODE_0D85FA                    ;0D8469|20FA85  |0D85FA; Transfer SFX data

; ------------------------------------------------------------------------------
; Read SFX size and update memory pointers
; ------------------------------------------------------------------------------
                       LDY.B $14                            ;0D846C|A414    |000614; Get data offset
                       STZ.B $14                            ;0D846E|6414    |000614; Clear pointer
                       STZ.B $15                            ;0D8470|6415    |000615;
                       LDA.B [$14],Y                        ;0D8472|B714    |000614; Read size low
                       XBA                                  ;0D8474|EB      |      ; Save to B
                       INY                                  ;0D8475|C8      |      ; Next byte
                       BNE CODE_0D847D                      ;0D8476|D005    |0D847D; If no page wrap
                       db $E6,$16,$A0,$00,$80               ;0D8478|        |000016; Increment bank

          CODE_0D847D:
                       LDA.B [$14],Y                        ;0D847D|B714    |000614; Read size high
                       INY                                  ;0D847F|C8      |      ; Next byte
                       BNE CODE_0D8487                      ;0D8480|D005    |0D8487; If no page wrap
                       db $E6,$16,$A0,$00,$80               ;0D8482|        |000016; Increment bank

; ------------------------------------------------------------------------------
; Store size and update channel pointers
; ------------------------------------------------------------------------------
          CODE_0D8487:
                       XBA                                  ;0D8487|EB      |      ; Get size from B
                       REP #$20                             ;0D8488|C220    |      ; 16-bit accumulator
                       PHA                                  ;0D848A|48      |      ; Push size
                       LDX.B $24                            ;0D848B|A624    |000624; Get channel index
                       STA.B $68,X                          ;0D848D|9568    |000668; Store size
                       CLC                                  ;0D848F|18      |      ; Clear carry
                       ADC.B $48,X                          ;0D8490|7548    |000648; Add base address
                       STA.B $4A,X                          ;0D8492|954A    |00064A; Store end address
                       INX                                  ;0D8494|E8      |      ; Next channel
                       INX                                  ;0D8495|E8      |      ;
                       STX.B $24                            ;0D8496|8624    |000624; Update index
                       PLX                                  ;0D8498|FA      |      ; Pull size to X
                       SEP #$20                             ;0D8499|E220    |      ; 8-bit accumulator

; ==============================================================================
; CODE_0D849B: SFX Byte Transfer Loop
; ==============================================================================
; Transfers SFX data bytes (3 per iteration) with handshake
; Similar to music transfer but for sound effects
; ==============================================================================
          CODE_0D849B:
                       LDA.B [$14],Y                        ;0D849B|B714    |000614; Read byte 1
                       STA.W SNES_APUIO1                    ;0D849D|8D4121  |002141; Send to APUIO1
                       INY                                  ;0D84A0|C8      |      ; Next byte
                       BNE CODE_0D84A8                      ;0D84A1|D005    |0D84A8; If no wrap
                       INC.B $16                            ;0D84A3|E616    |000616; Increment bank
                       LDY.W #$8000                         ;0D84A5|A00080  |      ; Reset Y

          CODE_0D84A8:
                       LDA.B [$14],Y                        ;0D84A8|B714    |000614; Read byte 2
                       STA.W SNES_APUIO2                    ;0D84AA|8D4221  |002142; Send to APUIO2
                       INY                                  ;0D84AD|C8      |      ; Next byte
                       BNE CODE_0D84B5                      ;0D84AE|D005    |0D84B5; If no wrap
                       INC.B $16                            ;0D84B0|E616    |000616; Increment bank
                       LDY.W #$8000                         ;0D84B2|A00080  |      ; Reset Y

          CODE_0D84B5:
                       LDA.B [$14],Y                        ;0D84B5|B714    |000614; Read byte 3
                       STA.W SNES_APUIO3                    ;0D84B7|8D4321  |002143; Send to APUIO3
                       INY                                  ;0D84BA|C8      |      ; Next byte
                       BNE CODE_0D84C2                      ;0D84BB|D005    |0D84C2; If no wrap
                       db $E6,$16,$A0,$00,$80               ;0D84BD|        |000016; Increment bank

; ------------------------------------------------------------------------------
; Handshake protocol
; ------------------------------------------------------------------------------
          CODE_0D84C2:
                       LDA.B $10                            ;0D84C2|A510    |000610; Get handshake
                       STA.W SNES_APUIO0                    ;0D84C4|8D4021  |002140; Send to trigger

          CODE_0D84C7:
                       CMP.W SNES_APUIO0                    ;0D84C7|CD4021  |002140; Wait for echo
                       BNE CODE_0D84C7                      ;0D84CA|D0FB    |0D84C7; Loop
                       INC.B $10                            ;0D84CC|E610    |000610; Increment handshake
                       BNE CODE_0D84D2                      ;0D84CE|D002    |0D84D2; If not $00
                       INC.B $10                            ;0D84D0|E610    |000610; Skip $00

          CODE_0D84D2:
                       DEX                                  ;0D84D2|CA      |      ; Decrement byte count
                       DEX                                  ;0D84D3|CA      |      ;
                       DEX                                  ;0D84D4|CA      |      ; (3 bytes per iteration)
                       BNE CODE_0D849B                      ;0D84D5|D0C4    |0D849B; Loop if more data
                       PLX                                  ;0D84D7|FA      |      ; Restore buffer index
                       INX                                  ;0D84D8|E8      |      ; Next buffer entry
                       INX                                  ;0D84D9|E8      |      ;
                       BRL CODE_0D843F                      ;0D84DA|8262FF  |0D843F; Process next SFX

; ==============================================================================
; CODE_0D84DD: Channel Pattern Management
; ==============================================================================
; Manages active patterns and channel assignments
; Updates pattern buffers for ongoing playback
; ==============================================================================
          CODE_0D84DD:
                       REP #$20                             ;0D84DD|C220    |      ; 16-bit accumulator
                       LDA.B $A8                            ;0D84DF|A5A8    |0006A8; Check pattern buffer
                       BNE CODE_0D84E6                      ;0D84E1|D003    |0D84E6; If has patterns
                       db $4C,$AD,$85                       ;0D84E3|        |0D85AD; Jump to exit

; ****************************************************************************
; Bank $0D - APU Communication & Sound Driver
; Cycle 4: Audio Data Tables & Music Pattern Data (Lines 1201-1600)
; ****************************************************************************

; ===========================================================================
; MUSIC/SFX PATTERN DATA - Large Binary Data Blocks
; ===========================================================================
; These data blocks contain raw audio pattern data uploaded to SPC700 RAM.
; Format: Binary instrument samples, note sequences, timing data, etc.
; Used by the music/SFX playback routines documented in Cycles 1-3.

                       db $C4,$36,$EB,$C5,$E4,$C4,$D4,$8D,$D0,$0A,$DB,$86,$D4,$85,$D4,$8A;0D9476| Pattern data block |
                       db $D4,$89,$2F,$35,$DD,$80,$B4,$86,$F0,$EC,$4D,$0D,$B0,$03,$48,$FF;0D9486|        |
                       db $BC,$F8,$C4,$8D,$00,$9E,$C4,$39,$E8,$00,$9E,$C4,$38,$BA,$38,$D0;0D9496|        |
                       db $02,$AB,$38,$8E,$B0,$08,$58,$FF,$38,$58,$FF,$39,$3A,$38,$BA,$38;0D94A6|        |
                       db $CE,$D4,$89,$DB,$8A,$E8,$00,$D4,$85,$AB,$C3,$69,$36,$C3,$F0,$04;0D94B6|        |
                       db $3D,$3D,$2F,$AE,$8F,$FF,$D8,$6F,$AB,$C3,$E4,$C4,$28,$0F,$F0,$71;0D94C6|        |
                       db $38,$F0,$C4,$9F,$C4,$C5,$CD,$00,$E4,$C3,$13,$C3,$03,$BC,$2F,$0D;0D94D6|        |
                       db $33,$C3,$05,$BC,$CD,$02,$2F,$05,$AB,$C3,$60,$88,$03,$C4,$36,$EB;0D94E6|        |
                       db $C5,$E4,$C4,$D4,$99,$D0,$0A,$DB,$92,$D4,$91,$D4,$96,$D4,$95,$2F;0D94F6| More pattern data |
                       db $35,$DD,$80,$B4,$92,$F0,$EC,$4D,$0D,$B0,$03,$48,$FF,$BC,$F8,$C4;0D9506|        |
                       db $8D,$00,$9E,$C4,$39,$E8,$00,$9E,$C4,$38,$BA,$38,$D0,$02,$AB,$38;0D9516|        |
                       db $8E,$B0,$08,$58,$FF,$38,$58,$FF,$39,$3A,$38,$BA,$38,$CE,$D4,$95;0D9526|        |
                       db $DB,$96,$E8,$00,$D4,$91,$AB,$C3,$69,$36,$C3,$F0,$04,$3D,$3D,$2F;0D9536|        |
                       db $AE,$8F,$FF,$D8,$6F,$E4,$C4,$28,$07,$F0,$08,$8D,$12,$CF,$73,$C4;0D9546|        |
                       db $02,$48,$FF,$48,$80,$C4,$C5,$38,$F0,$C4,$CD,$00,$E4,$C3,$13,$C3;0D9556|        |
                       db $03,$BC,$2F,$0D,$23,$C3,$05,$BC,$CD,$02,$2F,$05,$AB,$C3,$60,$88;0D9566|        |
                       db $03,$C4,$36,$EB,$C5,$E4,$C4,$D4,$A5,$D0,$0A,$DB,$9E,$D4,$9D,$D4;0D9576| Pattern sequences |
                       db $A2,$D4,$A1,$2F,$35,$DD,$80,$B4,$9E,$F0,$EC,$4D,$0D,$B0,$03,$48;0D9586|        |
                       db $FF,$BC,$F8,$C4,$8D,$00,$9E,$C4,$39,$E8,$00,$9E,$C4,$38,$BA,$38;0D9596|        |
                       db $D0,$02,$AB,$38,$8E,$B0,$08,$58,$FF,$38,$58,$FF,$39,$3A,$38,$BA;0D95A6|        |
                       db $38,$CE,$D4,$A1,$DB,$A2,$E8,$00,$D4,$9D,$AB,$C3,$69,$36,$C3,$F0;0D95B6|        |
                       db $04,$3D,$3D,$2F,$AE,$6F,$AB,$C3,$E4,$C4,$28,$07,$F0,$08,$8D,$12;0D95C6|        |
                       db $CF,$73,$C4,$02,$48,$FF,$48,$80,$C4,$C5,$38,$F0,$C4,$CD,$00,$E4;0D95D6|        |
                       db $C3,$13,$C3,$03,$BC,$2F,$0D,$23,$C3,$05,$BC,$CD,$02,$2F,$05,$AB;0D95E6|        |
                       db $C3,$60,$88,$03,$C4,$36,$EB,$C5,$E4,$C4,$D4,$B1,$D0,$0A,$DB,$AA;0D95F6| Complex patterns |
                       db $D4,$A9,$D4,$AE,$D4,$AD,$2F,$35,$DD,$80,$B4,$AA,$F0,$EC,$4D,$0D;0D9606|        |
                       db $B0,$03,$48,$FF,$BC,$F8,$C4,$8D,$00,$9E,$C4,$39,$E8,$00,$9E,$C4;0D9616|        |
                       db $38,$BA,$38,$D0,$02,$AB,$38,$8E,$B0,$08,$58,$FF,$38,$58,$FF,$39;0D9626|        |
                       db $3A,$38,$BA,$38,$CE,$D4,$AD,$DB,$AE,$E8,$00,$D4,$A9,$AB,$C3,$69;0D9636|        |
                       db $36,$C3,$F0,$04,$3D,$3D,$2F,$AE,$6F,$13,$C3,$04,$12,$C0,$2F,$02;0D9646|        |
                       db $02,$C0,$8F,$FF,$D8,$6F,$23,$C3,$29,$E4,$BC,$04,$BD,$48,$FF,$0E;0D9656|        |
                       db $BF,$00,$4E,$BE,$00,$4E,$C7,$00,$4E,$C9,$00,$4E,$C8,$00,$E8,$00;0D9666|        |
                       db $C4,$BB,$C4,$DA,$C4,$CB,$C4,$CF,$C4,$CD,$9C,$C4,$ED,$C4,$EE,$03;0D9676|        |

; ===========================================================================
; SPC700 DRIVER CODE SECTION - Embedded Audio Processor Routines
; ===========================================================================
; These routines run ON THE SPC700 (not the 65816 CPU!)
; Uploaded to SPC700 RAM during initialization (see CODE_0D8000).
; Contains: Note processing, envelope control, DSP register management, etc.

                       db $C3,$1D,$E4,$BC,$0E,$BF,$00,$4E,$BE,$00,$C4,$04,$CD,$1E,$8F,$80;0D9686| SPC700 driver code |
                       db $C1,$0B,$04,$90,$03,$3F,$1C,$0A,$1D,$1D,$4B,$C1,$B3,$C1,$F2,$6F;0D9696| - Note processing |
                       db $FA,$C4,$C2,$8F,$FF,$D8,$6F,$FA,$BB,$D3,$6F,$AA,$C3,$00,$CA,$C0;0D96A6| - Envelope control |
                       db $60,$6F,$03,$C3,$3A,$8D,$05,$CB,$F2,$E4,$F3,$28,$7F,$C4,$F3,$DD;0D96B6| - DSP interaction |
                       db $60,$88,$10,$FD,$10,$F1,$CD,$00,$8D,$00,$CB,$F2,$D8,$F3,$FC,$CB;0D96C6|        |
                       db $F2,$D8,$F3,$DD,$60,$88,$0F,$FD,$10,$F0,$BA,$BB,$F0,$06,$DA,$DA;0D96D6|        |
                       db $BA,$00,$DA,$BB,$C4,$BE,$8D,$10,$D6,$DB,$00,$FE,$FB,$2F,$1E,$8D;0D96E6|        |
                       db $05,$CB,$F2,$E4,$F3,$08,$80,$C4,$F3,$DD,$60,$88,$10,$FD,$10,$F1;0D96F6|        |
                       db $BA,$DA,$F0,$09,$8F,$FF,$D8,$DA,$BB,$BA,$00,$DA,$DA,$6F,$E4,$F5;0D9706|        |
                       db $C4,$06,$28,$07,$C4,$F5,$D0,$04,$D8,$F4,$2F,$1B,$1C,$2D,$BA,$F6;0D9716|        |
                       db $DA,$2E,$EE,$F6,$BB,$17,$2D,$F6,$BA,$17,$2D,$8D,$00,$F8,$F4,$D8;0D9726|        |
                       db $F4,$3E,$F4,$F0,$FC,$F8,$F4,$6F,$E4,$F5,$D7,$2E,$3A,$2E,$E4,$F6;0D9736|        |
                       db $D7,$2E,$3A,$2E,$E4,$F7,$D7,$2E,$3A,$2E,$D8,$F4,$3E,$F4,$F0,$FC;0D9746|        |
                       db $F8,$F4,$D0,$E4,$2F,$B8,$E4,$F6,$D7,$2E,$3A,$2E,$E4,$F7,$D7,$2E;0D9756|        |
                       db $3A,$2E,$D8,$F4,$3E,$F4,$F0,$FC,$F8,$F4,$D0,$EA,$2F,$A0,$E4,$F7;0D9766|        |
                       db $D7,$2E,$3A,$2E,$D8,$F4,$3E,$F4,$F0,$FC,$F8,$F4,$D0,$F0,$2F,$8E;0D9776|        |
                       db $D8,$F4,$3E,$F4,$F0,$FC,$F8,$F4,$D0,$F6,$5F,$8B,$12,$BA,$F6,$DA;0D9786|        |
                       db $30,$D8,$F4,$3E,$F4,$F0,$FC,$F8,$F4,$BA,$F6,$DA,$36,$D8,$F4,$8D;0D9796|        |
                       db $00,$F7,$2E,$D7,$30,$FC,$D0,$04,$AB,$2F,$AB,$31,$1A,$36,$D0,$F1;0D97A6|        |
                       db $3E,$F4,$F0,$FC,$F8,$F4,$F0,$0E,$BA,$F6,$DA,$2E,$D8,$F4,$3E,$F4;0D97B6|        |
                       db $F0,$FC,$F8,$F4,$2F,$C7,$5F,$8B,$12,$EA,$C3,$20,$AA,$C3,$20,$CA;0D97C6|        |
                       db $C0,$20,$B0,$04,$E8,$24,$2F,$02,$E8,$01,$8F,$00,$F1,$C4,$FA,$8F;0D97D6|        |
                       db $01,$F1,$6F,$E8,$FF,$8D,$FE,$5A,$C3,$D0,$0C,$E8,$FD,$8D,$FC,$5A;0D97E6|        |
                       db $C5,$D0,$04,$E2,$C0,$2F,$02,$F2,$C0,$6F,$E8,$00,$8D,$D2,$DA,$2E;0D97F6|        |
                       db $E8,$00,$FD,$D7,$2E,$FC,$D0,$FB,$AB,$2F,$78,$FA,$2F,$D0,$F4,$6F;0D9806|        |

; ===========================================================================
; DSP REGISTER VOICE MAPPING TABLE
; ===========================================================================
; Maps SPC700 DSP registers to voice control parameters.
; Each entry: [voice_register_offset, control_value]
; Used to initialize/control the 8 hardware voices on SPC700 DSP.

                       db $FA,$EE,$ED,$E4,$82,$C5,$60,$FD,$E4,$B9,$C5,$61,$FD,$E4,$BB,$C5;0D9816| DSP voice 0 regs |
                       db $62,$FD,$E4,$CB,$C5,$63,$FD,$E4,$CD,$C5,$64,$FD,$E4,$CF,$C5,$65;0D9826| DSP voice 1 regs |
                       db $FD,$E4,$D1,$C5,$66,$FD,$E4,$D3,$C5,$67,$FD,$E4,$D4,$C5,$68,$FD;0D9836| DSP voice 2 regs |
                       db $E4,$D6,$C5,$69,$FD,$E4,$D7,$C5,$6A,$FD,$BA,$08,$C5,$6B,$FD,$CC;0D9846| DSP voice 3 regs |
                       db $6C,$FD,$BA,$7E,$C5,$6D,$FD,$CC,$6E,$FD,$BA,$80,$C5,$6F,$FD,$CC;0D9856| DSP voice 4 regs |
                       db $70,$FD,$BA,$83,$C5,$71,$FD,$CC,$72,$FD,$BA,$B5,$C5,$73,$FD,$CC;0D9866| DSP voice 5 regs |
                       db $74,$FD,$BA,$B7,$C5,$75,$FD,$CC,$76,$FD,$CD,$0E,$F4,$3E,$D5,$77;0D9876| DSP voice 6 regs |
                       db $FD,$F4,$3F,$D5,$78,$FD,$F4,$5E,$D5,$87,$FD,$F4,$5F,$D5,$88,$FD;0D9886| DSP voice 7 regs |

; ===========================================================================
; INSTRUMENT/SAMPLE POINTER TABLE
; ===========================================================================
; 16-bit pointers to instrument sample data in SPC700 RAM.
; Format: [addr_low, addr_high] pairs for each instrument.
; Used by voice initialization to set sample source addresses.

                       db $F5,$00,$01,$D5,$97,$FD,$F5,$01,$01,$D5,$98,$FD,$F5,$20,$01,$D5;0D9896| Instrument 0-3 |
                       db $A7,$FD,$F5,$21,$01,$D5,$A8,$FD,$F5,$40,$01,$D5,$B7,$FD,$F5,$41;0D98A6| Instrument 4-7 |
                       db $01,$D5,$B8,$FD,$F5,$60,$01,$D5,$C7,$FD,$F5,$61,$01,$D5,$C8,$FD;0D98B6| Instrument 8-11 |
                       db $F5,$80,$FA,$D5,$D7,$FD,$F5,$81,$FA,$D5,$D8,$FD,$F5,$A0,$FA,$D5;0D98C6| Instrument 12-15 |
                       db $E7,$FD,$F5,$A1,$FA,$D5,$E8,$FD,$F5,$C0,$FA,$D5,$F7,$FD,$1D,$1D;0D98D6| Instrument 16-18 |
                       db $10,$9A,$CD,$0E,$F5,$C1,$FA,$D5,$F8,$FD,$F5,$E0,$FA,$D5,$07,$FE;0D98E6| Instrument 19-21 |
                       db $F5,$E1,$FA,$D5,$08,$FE,$F5,$00,$FB,$D5,$17,$FE,$F5,$40,$FB,$D5;0D98F6| Instrument 22-25 |
                       db $27,$FE,$F5,$41,$FB,$D5,$28,$FE,$F5,$60,$FB,$D5,$37,$FE,$F5,$61;0D9906| Instrument 26-29 |
                       db $FB,$D5,$38,$FE,$F5,$C0,$FB,$D5,$47,$FE,$F5,$C1,$FB,$D5,$48,$FE;0D9916| Instrument 30-33 |
                       db $F5,$01,$FB,$D5,$18,$FE,$F5,$00,$FC,$D5,$57,$FE,$F5,$01,$FC,$D5;0D9926| Instrument 34-37 |
                       db $58,$FE,$1D,$1D,$10,$AE,$CD,$3F,$F5,$E0,$FC,$D5,$57,$FF,$1D,$C8;0D9936| Instrument 38-39 |

; ===========================================================================
; ENVELOPE/ADSR CONFIGURATION DATA
; ===========================================================================
; ADSR (Attack, Decay, Sustain, Release) envelope parameters for each voice.
; Format: Configuration bytes for SPC700 DSP ADSR registers.
; Controls volume envelope shape during note playback.

                       db $20,$B0,$F5,$F5,$E0,$FC,$D5,$57,$FF,$F5,$A0,$FC,$D5,$37,$FF,$1D;0D9946| ADSR config 0-1 |
                       db $C8,$10,$B0,$EF,$F5,$E0,$FC,$D5,$57,$FF,$F5,$A0,$FC,$D5,$37,$FF;0D9956| ADSR config 2-3 |
                       db $F4,$0E,$D5,$67,$FE,$F5,$00,$FA,$D5,$77,$FE,$F5,$20,$FA,$D5,$87;0D9966| ADSR config 4-7 |
                       db $FE,$F5,$40,$FA,$D5,$97,$FE,$F5,$60,$FA,$D5,$A7,$FE,$F5,$20,$FB;0D9976| ADSR config 8-11 |
                       db $D5,$B7,$FE,$F5,$80,$FB,$D5,$C7,$FE,$F5,$A0,$FB,$D5,$D7,$FE,$F5;0D9986| ADSR config 12-15 |
                       db $E0,$FB,$D5,$E7,$FE,$F5,$20,$FC,$D5,$F7,$FE,$F5,$40,$FC,$D5,$07;0D9996| ADSR config 16-19 |
                       db $FF,$F5,$60,$FC,$D5,$17,$FF,$F5,$80,$FC,$D5,$27,$FF,$1D,$10,$A4;0D99A6| ADSR config 20-23 |
                       db $6F,$8F,$FF,$ED,$E5,$60,$FD,$C4,$82,$E5,$61,$FD,$C4,$B9,$E5,$62;0D99B6| ADSR config 24+ |

; ===========================================================================
; VOICE PARAMETER ALTERNATE TABLE
; ===========================================================================
; Alternate voice configuration (different ADSR/volume settings).
; Used for layered sounds or special effects.

                       db $FD,$C4,$BB,$E5,$63,$FD,$C4,$CB,$C4,$C7,$E5,$64,$FD,$C4,$CD,$C4;0D99C6| Alt voice 0-3 |
                       db $C8,$E5,$65,$FD,$C4,$CF,$C4,$C9,$E5,$66,$FD,$C4,$D1,$E5,$67,$FD;0D99D6| Alt voice 4-7 |
                       db $C4,$D3,$E5,$68,$FD,$C4,$D4,$C4,$CA,$E5,$6A,$FD,$C4,$D7,$E5,$69;0D99E6| Alt voice 8-11 |
                       db $FD,$3F,$78,$07,$E5,$6B,$FD,$EC,$6C,$FD,$DA,$08,$E5,$6D,$FD,$EC;0D99F6| Alt voice 12-15 |
                       db $6E,$FD,$DA,$7E,$E5,$6F,$FD,$EC,$70,$FD,$DA,$80,$E5,$71,$FD,$EC;0D9A06| Alt voice 16-19 |
                       db $72,$FD,$DA,$83,$E5,$73,$FD,$EC,$74,$FD,$DA,$B5,$E5,$75,$FD,$EC;0D9A16| Alt voice 20-23 |
                       db $76,$FD,$DA,$B7,$CD,$0E,$F5,$77,$FD,$D4,$3E,$F5,$78,$FD,$D4,$3F;0D9A26| Alt voice 24-27 |

; ===========================================================================
; EXTENDED INSTRUMENT POINTER TABLE (Continued)
; ===========================================================================
; Continuation of instrument sample pointers for higher instrument IDs.

                       db $F5,$87,$FD,$D4,$5E,$F5,$88,$FD,$D4,$5F,$F5,$97,$FD,$D5,$00,$01;0D9A36| Instruments 28-31 |
                       db $F5,$98,$FD,$D5,$01,$01,$F5,$A7,$FD,$D5,$20,$01,$F5,$A8,$FD,$D5;0D9A46| Instruments 32-35 |
                       db $21,$01,$F5,$B7,$FD,$D5,$40,$01,$F5,$B8,$FD,$D5,$41,$01,$F5,$C7;0D9A56| Instruments 36-39 |
                       db $FD,$D5,$60,$01,$F5,$C8,$FD,$D5,$61,$01,$F5,$D7,$FD,$D5,$80,$FA;0D9A66| Instruments 40-43 |
                       db $F5,$D8,$FD,$D5,$81,$FA,$F5,$E7,$FD,$D5,$A0,$FA,$F5,$E8,$FD,$D5;0D9A76| Instruments 44-47 |
                       db $A1,$FA,$F5,$F7,$FD,$D5,$C0,$FA,$1D,$1D,$10,$9A,$CD,$0E,$F5,$F8;0D9A86| Instruments 48-50 |

; ===========================================================================
; EXTENDED ADSR CONFIGURATION (Continued)
; ===========================================================================
; More ADSR envelope parameters for additional instruments/voices.

                       db $FD,$D5,$C1,$FA,$F5,$07,$FE,$D5,$E0,$FA,$F5,$08,$FE,$D5,$E1,$FA;0D9A96| ADSR extended 0-3 |
                       db $F5,$17,$FE,$D5,$00,$FB,$F5,$27,$FE,$D5,$40,$FB,$F5,$28,$FE,$D5;0D9AA6| ADSR extended 4-7 |
                       db $41,$FB,$F5,$37,$FE,$D5,$60,$FB,$F5,$38,$FE,$D5,$61,$FB,$F5,$47;0D9AB6| ADSR extended 8-11 |
                       db $FE,$D5,$C0,$FB,$F5,$48,$FE,$D5,$C1,$FB,$F5,$18,$FE,$D5,$01,$FB;0D9AC6| ADSR extended 12-15 |
                       db $F5,$57,$FE,$D5,$00,$FC,$F5,$58,$FE,$D5,$01,$FC,$1D,$1D,$10,$AE;0D9AD6| ADSR extended 16-18 |

; ===========================================================================
; SPECIAL EFFECT ENVELOPE DATA
; ===========================================================================
; Specialized envelope configurations for sound effects.

                       db $CD,$3F,$F5,$57,$FF,$D5,$E0,$FC,$1D,$C8,$20,$B0,$F5,$F5,$57,$FF;0D9AE6| SFX envelope 0-1 |
                       db $D5,$E0,$FC,$F5,$37,$FF,$D5,$A0,$FC,$1D,$C8,$10,$B0,$EF,$F5,$57;0D9AF6| SFX envelope 2-3 |
                       db $FF,$D5,$E0,$FC,$F5,$37,$FF,$D5,$A0,$FC,$F5,$67,$FE,$D4,$0E,$F5;0D9B06| SFX envelope 4-6 |
                       db $77,$FE,$D5,$00,$FA,$F5,$87,$FE,$D5,$20,$FA,$F5,$97,$FE,$D5,$40;0D9B16| SFX envelope 7-10 |
                       db $FA,$F5,$A7,$FE,$D5,$60,$FA,$F5,$B7,$FE,$D5,$20,$FB,$F5,$C7,$FE;0D9B26| SFX envelope 11-14 |
                       db $D5,$80,$FB,$F5,$D7,$FE,$D5,$A0,$FB,$F5,$E7,$FE,$D5,$E0,$FB,$F5;0D9B36| SFX envelope 15-18 |
                       db $F7,$FE,$D5,$20,$FC,$F5,$07,$FF,$D5,$40,$FC,$F5,$17,$FF,$D5,$60;0D9B46| SFX envelope 19-22 |
                       db $FC,$F5,$27,$FF,$D5,$80,$FC,$1D,$10,$A4,$6F,$E8,$36,$C4,$3B,$E8;0D9B56| SFX envelope 23-24 |

; ===========================================================================
; CODE_0D9B5C - Audio Command Processing Routine
; ===========================================================================
; Processes audio commands from CPU to SPC700.
; Handles command parsing, parameter extraction, DSP control.

CODE_0D9B5C:           db $DC,$8F,$00,$05,$43,$C0,$05,$8F,$09,$C1,$2F,$08,$8F,$49,$C1,$60;0D9B5C| Command processor |
                       db $88,$08,$E2,$05,$C4,$3C,$60,$88,$08,$C4,$04,$F8,$3C,$EB,$C1,$CB;0D9B6C| - Parse command byte |
                       db $F2,$EB,$F3,$6D,$BF,$CF,$DD,$28,$70,$C4,$3A,$EE,$BF,$CF,$DD,$D8;0D9B7C| - Extract parameters |
                       db $3C,$F8,$3B,$9F,$28,$07,$04,$3A,$04,$05,$AF,$D8,$3B,$60,$98,$10;0D9B8C| - Dispatch to handler |
                       db $C1,$69,$04,$3C,$D0,$D5,$BA,$36,$DA,$F4,$BA,$38,$DA,$F6,$58,$04;0D9B9C|        |
                       db $C0,$6F,$E4,$8D,$F0,$0F,$8B,$8D,$BA,$89,$7A,$85,$7E,$86,$DA,$85;0D9BAC|        |

; ===========================================================================
; VOICE CHANNEL CONTROL ROUTINES
; ===========================================================================
; Control individual SPC700 DSP voices (pitch, volume, ADSR, etc.)

                       db $F0,$03,$09,$BB,$D8,$E4,$8F,$F0,$0F,$8B,$8F,$BA,$8B,$7A,$87,$7E;0D9BBC| Voice 0 control |
                       db $88,$DA,$87,$F0,$03,$09,$BC,$D8,$E4,$99,$F0,$0F,$8B,$99,$BA,$95;0D9BCC| Voice 1 control |
                       db $7A,$91,$7E,$92,$DA,$91,$F0,$03,$09,$BB,$D8,$E4,$9B,$F0,$0F,$8B;0D9BDC| Voice 2 control |
                       db $9B,$BA,$97,$7A,$93,$7E,$94,$DA,$93,$F0,$03,$09,$BC,$D8,$E4,$A5;0D9BEC| Voice 3 control |
                       db $F0,$08,$8B,$A5,$BA,$A1,$7A,$9D,$DA,$9D,$E4,$A7,$F0,$08,$8B,$A7;0D9BFC| Voice 4-5 control |
                       db $BA,$A3,$7A,$9F,$DA,$9F,$E4,$B1,$F0,$0F,$8B,$B1,$BA,$AD,$7A,$A9;0D9C0C| Voice 6 control |
                       db $7E,$AA,$DA,$A9,$F0,$03,$09,$BB,$D9,$E4,$B3,$F0,$0F,$8B,$B3,$BA;0D9C1C| Voice 7 control |
                       db $AF,$7A,$AB,$7E,$AC,$DA,$AB,$F0,$03,$09,$BC,$D9,$6F,$FD,$12,$EB;0D9C2C|        |

; ===========================================================================
; TRACK/PATTERN POINTER TABLES
; ===========================================================================
; Lookup tables for music track and SFX pattern data.
; Format: 24-bit pointers [bank, addr_low, addr_high] for each track.

DATA8_0D9C3C:          db $12,$D3,$12,$B5,$12,$FD,$12,$FD,$12,$FD,$12,$0A,$13,$85,$06,$91;0D9C3C| Track pointers 0-7 |
                       db $06,$13,$07,$1F,$07,$5B,$07,$9A,$07,$AC,$07,$B0,$07,$C2,$07,$C6;0D9C4C| Track pointers 8-15 |
                       db $07,$17,$08,$9B,$08,$5A,$08,$87,$08,$AB,$08,$C4,$08,$31,$08,$4A;0D9C5C| Track pointers 16-23 |
                       db $08,$2D,$08,$23,$08,$29,$08,$6A,$07,$66,$07,$16,$0A,$D4,$08,$FE;0D9C6C| Track pointers 24-31 |
                       db $08,$2E,$09,$41,$09,$53,$09,$63,$09,$AC,$09,$D5,$09,$1A,$0A,$3D;0D9C7C| Track pointers 32-39 |
                       db $06,$4A,$06,$CD,$06,$DA,$06,$6E,$07,$82,$06,$87,$09,$75,$09,$FB;0D9C8C| Track pointers 40-47 |
                       db $09,$1A,$0A,$1A,$0A,$1A,$0A,$1A,$0A,$01,$02,$01,$02,$02,$03,$00;0D9C9C| Track pointers 48-55 |

; ===========================================================================
; TRACK TYPE/FLAGS TABLE
; ===========================================================================
; Flags indicating track type (music/SFX), loop points, priority, etc.
; One byte per track entry.

                       db $03,$00,$02,$00,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$01,$01;0D9CAC| Track flags 0-15 |
                       db $01,$01,$01,$01,$01,$01,$00,$01,$00,$00,$01,$02,$01,$02,$02,$01;0D9CBC| Track flags 16-31 |
                       db $03,$02,$02,$00,$00,$00,$00,$79,$08,$FA,$08,$83,$09,$14,$0A,$AD;0D9CCC| Track flags 32-39 |
                       db $0A,$50,$0B,$FC,$0B,$B2,$0C,$74,$0D,$41,$0E,$1A,$0F,$00,$10,$F3;0D9CDC| More pointers |
                       db $10,$7F,$00,$00,$00,$00,$00,$00,$00,$0C,$21,$2B,$2B,$13,$FE,$F3;0D9CEC|        |

; ===========================================================================
; AUDIO DRIVER CONFIGURATION DATA
; ===========================================================================
; Driver initialization parameters, timing values, buffer sizes, etc.

DATA8_0D9CFC:          db $F9,$58,$BF,$DB,$F0,$FE,$07,$0C,$0C,$34,$33,$00,$D9,$E5,$01,$FC;0D9CFC| Config: Timing/buffers |
                       db $EB,$C0,$90,$60,$40,$48,$30,$20,$24,$18,$10,$0C,$08,$06,$04,$03;0D9D0C| Config: Rate table |
                       db $BD,$18,$CC,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0D9D1C| Config: Reserved |
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0D9D2C| Padding/alignment |
                       db $D2,$D2,$EA,$02,$E4,$05,$0D,$E5,$0D,$D2,$28,$0D,$E5,$0D,$F2,$D2;0D9D3C| Command templates |
                       db $FA,$EA,$07,$E4,$05,$0D,$E5,$0D,$E6,$0D,$D2,$32,$0D,$E5,$0D,$E6;0D9D4C|        |
                       db $0D,$F2,$4C,$5C,$2D,$3D,$4D,$2C,$3C,$6C,$BE,$BF,$C9,$C8,$C7,$B6;0D9D5C| Note mapping |
                       db $B6,$CA                           ;0D9D6C|        |

; ===========================================================================
; DATA8_0D9D78 - SPC700 MUSIC TRACK DATA
; ===========================================================================
; Embedded music sequence data for multiple tracks.
; Format: Proprietary music notation (notes, durations, commands, loops, etc.)
; Processed by SPC700 sequencer uploaded during initialization.

DATA8_0D9D78:          db $CC,$03,$02,$00,$00,$00,$00,$00,$00,$00,$00,$AA,$21,$F0,$31,$EE;0D9D78| Track data block 0 |
                       db $1E,$CE,$41,$F0,$86,$E5,$0D,$23,$00,$10,$23,$FD,$47,$96,$FD,$35;0D9D88|        |
                       db $FD,$35,$FD,$35,$0F,$34,$9A,$E0,$21,$11,$00,$33,$F1,$42,$BD,$AA;0D9D98|        |
                       db $1F,$BE,$42,$E0,$32,$EF,$00,$F0,$96,$0F,$02,$0F,$23,$FE,$34,$ED;0D9DA8|        |
                       db $35,$96,$FE,$35,$0F,$34,$21,$33,$34,$44,$AA,$11,$01,$20,$EE,$1F;0D9DB8|        |
                       db $CE,$32,$F0,$87,$D4,$FD,$33,$FF,$11,$22,$FE,$46,$02,$00,$00,$00;0D9DC8|        |
                       db $00,$00,$00,$00,$00,$A6,$60,$AF,$50,$BF,$30,$DF,$00,$11,$BA,$F0;0D9DD8| Track data block 1 |
                       db $1F,$E2,$4F,$D3,$4C,$B2,$3D,$A2,$20,$56,$32,$32,$0F,$EE,$00,$CB;0D9DE8|        |
                       db $A6,$40,$AF,$61,$AF,$50,$AF,$40,$C0,$BA,$1F,$F0,$00,$10,$F0,$1E;0D9DF8|        |
                       db $E3,$4F,$BA,$D3,$3D,$B1,$3E,$E3,$3E,$E2,$1F,$A6,$EF,$F0,$20,$CF;0D9E08|        |
                       db $40,$AF,$61,$AF,$A6,$60,$9E,$51,$CF,$30,$EF,$0F,$11,$BB,$F0,$1F;0D9E18|        |
                       db $E2,$30,$E3,$2C,$C2,$3D,$02,$00,$00,$00,$00,$00,$00,$00,$00,$B6;0D9E28| Track data block 2 |
                       db $FF,$FF,$F0,$12,$AC,$21,$0F,$FE,$9A,$CF,$10,$11,$11,$10,$FE,$DB;0D9E38|        |
                       db $DC,$B6,$64,$EF,$01,$12,$33,$32,$10,$00,$B6,$FE,$EF,$01,$12,$AC;0D9E48|        |
                       db $11,$10,$ED,$9B,$01,$F0,$10,$21,$10,$FD,$DC,$EB,$02,$00,$00,$00;0D9E58|        |
                       db $00,$00,$00,$00,$00,$A6,$DE,$20,$ED,$BF,$3F,$E0,$13,$33,$AA,$FE;0D9E68| Track data block 3 |
                       db $36,$BD,$21,$11,$00,$F0,$00,$AA,$01,$4C,$E1,$04,$0E,$EE,$F0,$00;0D9E78|        |
                       db $A6,$DF,$12,$11,$00,$64,$F0,$01,$16,$AA,$39,$F0,$00,$11,$23,$EB;0D9E88|        |
                       db $52,$EF,$B2,$42,$0E,$CC,$DE,$F0,$21,$DE,$11,$9A,$E1,$13,$FF,$FF;0D9E98|        |
                       db $EE,$00,$22,$41,$A6,$DE,$20,$ED,$BF,$3F,$E0,$13,$33,$AB,$FE,$36;0D9EA8|        |
                       db $BD,$21,$11,$00,$F0,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$CA;0D9EB8| Track data block 4 |
                       db $00,$01,$01,$CC,$51,$00,$00,$0F,$8A,$04,$59,$EF,$0F,$FE,$00,$0F;0D9EC8|        |
                       db $00,$7A,$01,$13,$12,$22,$34,$34,$54,$45,$CA,$00,$01,$01,$CC,$51;0D9ED8|        |
                       db $00,$00,$0F,$8B,$04,$59,$FF,$FE,$0F,$F0,$0F,$00,$02,$00,$00,$00;0D9EE8|        |
                       db $00,$00,$00,$00,$00,$8A,$C0,$C2,$00,$0F,$01,$11,$0F,$3E,$BA,$1D;0D9EF8| Track data block 5 |
                       db $A4,$4F,$00,$00,$00,$F0,$10,$8A,$DF,$40,$12,$12,$22,$23,$31,$40;0D9F08|        |
                       db $B6,$20,$AD,$00,$09,$AF,$FF,$00,$00,$7A,$AC,$CF,$EE,$EF,$E0,$F0;0D9F18|        |
                       db $01,$12,$BA,$00,$01,$00,$01,$00,$01,$CD,$51,$BA,$01,$00,$00,$00;0D9F28|        |
                       db $1D,$A5,$3F,$00,$7A,$EC,$E1,$F0,$00,$00,$13,$1E,$5C,$BB,$1D,$B4;0D9F38|        |
                       db $3F,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$BA;0D9F48| Track data block 6 |
                       db $ED,$41,$00,$00,$00,$00,$00,$01,$86,$1E,$CF,$0F,$01,$EF,$F1,$1E;0D9F58|        |
                       db $0F,$CA,$00,$00,$00,$00,$0E,$E3,$15,$ED,$BA,$ED,$41,$F0,$11,$FF;0D9F68|        |
                       db $01,$00,$01,$87,$0D,$CF,$00,$11,$DF,$F1,$0E,$10,$02,$00,$00,$00;0D9F78|        |
                       db $00,$00,$00,$00,$00,$C6,$FF,$14,$2E,$12,$D1,$3E,$C0,$11,$C6,$31;0D9F88| Track data block 7 |
                       db $DF,$2D,$E2,$ED,$12,$11,$FC,$B6,$D5,$DB,$50,$B4,$60,$EE,$BE,$61;0D9F98|        |
                       db $C6,$E3,$2E,$23,$FE,$FF,$14,$2E,$12,$B6,$B1,$5D,$A0,$22,$52,$AE;0D9FA8|        |
                       db $4A,$C5,$C6,$EC,$02,$11,$0D,$E2,$FE,$2F,$D2,$B6,$71,$FE,$AE,$61;0D9FB8|        |
                       db $B6,$4C,$46,$EC,$C6,$FF,$14,$2E,$12,$E1,$3E,$D0,$11,$C7,$31,$DF;0D9FC8|        |
                       db $2D,$E2,$ED,$12,$11,$FC,$02,$00,$00,$00,$00,$00,$00,$00,$00,$C6;0D9FD8| Track data block 8 |
                       db $E1,$22,$FC,$D2,$41,$DC,$E1,$33,$C6,$FC,$E3,$41,$EE,$02,$32,$EC;0D9FE8|        |
                       db $F4,$C6,$40,$DD,$F2,$41,$CB,$04,$2E,$DE,$C6,$03,$3F,$BD,$24,$2F;0D9FF8|        |
                       db $EE,$14,$4F,$C6,$CE,$34,$1E,$DE,$14,$2D,$CF,$22,$C6,$1E,$CE,$34;0DA008|        |
                       db $0C,$D0,$33,$1D,$C0,$C6,$55,$FC,$E2,$33,$0D,$C1,$43,$EC,$C6,$E1;0DA018|        |
                       db $32,$FB,$C1,$52,$DC,$F2,$32,$C7,$EC,$E3,$41,$EE,$02,$42,$EC,$04;0DA028|        |
                       db $02,$00,$00,$00,$00,$00,$00,$00,$00,$C2,$40,$E3,$30,$12,$11,$22;0DA038| Track data block 9 |
                       db $22,$22,$96,$EC,$04,$DD,$2F,$E2,$EC,$32,$DF,$C6,$00,$00,$F0,$0F;0DA048|        |
                       db $01,$DF,$5F,$A4,$C2,$4F,$D3,$41,$23,$22,$21,$11,$11,$97,$2C,$14;0DA058|        |
                       db $EE,$3E,$D2,$FD,$31,$CF,$02,$00,$00,$00,$00,$00,$00,$00,$00,$7A;0DA068| Track data block 10 |
                       db $13,$32,$F0,$35,$54,$23,$57,$61,$8A,$EE,$F1,$23,$21,$35,$64,$2E;0DA078|        |
                       db $E0,$8A,$35,$43,$12,$12,$34,$31,$01,$23,$9A,$21,$FE,$F2,$45,$30;0DA088|        |
                       db $EF,$35,$41,$AA,$FF,$01,$10,$EC,$D0,$33,$0F,$F0,$9A,$13,$2E,$BC;0DA098|        |
                       db $02,$2F,$CA,$D0,$10,$8A,$FC,$CD,$FF,$FE,$CC,$DF,$FF,$EC,$8A,$BC;0DA0A8|        |
                       db $E2,$21,$EB,$BC,$ED,$DB,$EF,$7A,$34,$3C,$AB,$DF,$EB,$BD,$F1,$ED;0DA0B8|        |
                       db $7A,$EF,$12,$0B,$AE,$34,$0E,$CE,$36,$7A,$4F,$DC,$15,$63,$EB,$C2;0DA0C8|        |
                       db $42,$FE,$7A,$E1,$57,$41,$11,$34,$1E,$CB,$DD,$7A,$F0,$11,$46,$50;0DA0D8|        |
                       db $E0,$12,$0C,$AC,$7A,$E2,$20,$DD,$F2,$65,$EA,$C0,$45,$7A,$F1,$BC;0DA0E8|        |
                       db $05,$40,$DD,$04,$54,$0E,$7A,$12,$32,$00,$35,$44,$23,$57,$62,$8B;0DA0F8|        |
                       db $FD,$E1,$33,$21,$25,$65,$2E,$E0,$02,$00,$00,$00,$00,$00,$00,$00;0DA108|        |
                       db $00,$7A,$43,$42,$33,$1F,$0F,$EE,$BC,$CB,$7A,$AC,$CC,$CD,$FF,$1F;0DA118| Track data block 11 |
                       db $01,$31,$21,$7A,$12,$11,$01,$02,$F1,$12,$33,$24,$7A,$33,$43,$33;0DA128|        |
                       db $1F,$1F,$DD,$CC,$CB,$7B,$BB,$BD,$DD,$EF,$00,$11,$12,$22,$30,$00;0DA138|        |
; ****************************************************************************
; Bank $0D - APU Communication & Sound Driver
; Cycle 5: Extended Music Track Data & Padding (Lines 1601-2000)
; ****************************************************************************

; ===========================================================================
; EXTENDED MUSIC TRACK DATA (Continued from Cycle 4)
; ===========================================================================
; More music sequence data for later tracks.
; These are uploaded to SPC700 RAM during music load commands.

                       db $46,$55,$CD,$F2,$D2,$A4,$D4,$80,$EA,$07,$E4,$0D,$D7,$00,$25,$40;0DAD48| Track continuation |
                       db $EB,$0F,$EC,$04,$ED,$00,$EE,$08,$0C,$E4,$09,$D6,$08,$00,$08,$F2;0DAD58|        |
                       db $D2,$59,$D4,$80,$EA,$00,$E4,$00,$DE,$ED,$07,$EC,$06,$EE,$18,$DD;0DAD68|        |
                       db $18,$0C,$DD,$1A,$08,$F2,$E2,$D2,$C8,$D4,$80,$EA,$08,$E4,$0C,$D7;0DAD78|        |
                       db $00,$25,$40,$EB,$0F,$EC,$04,$ED,$00,$EE,$08,$0E,$E4,$0C,$D6,$08;0DAD88|        |
                       db $00,$D7,$00,$10,$48,$EE,$11,$ED,$07,$EC,$02,$01,$F2,$D2,$59,$D4;0DAD98|        |
                       db $80,$EA,$07,$E4,$07,$EE,$10,$ED,$00,$EC,$00,$D6,$10,$09,$D7,$00;0DADA8|        |
                       db $10,$C3,$01,$F2,$D2,$FF,$D4,$80,$EA,$00,$E4,$05,$0C,$0A,$F2,$D2;0DADB8|        |
                       db $B4,$D4,$80,$EA,$00,$DD,$1E,$DE,$EB,$0C,$EC,$07,$ED,$00,$EE,$14;0DADC8|        |
                       db $0E,$08,$F2,$D2,$78,$D4,$80,$EA,$03,$E4,$04,$D6,$48,$CA,$08,$F2;0DADD8|        |
                       db $D2,$DC,$D4,$80,$EA,$00,$DD,$16,$DE,$EB,$0F,$EC,$07,$ED,$00,$EE;0DADE8|        |
                       db $16,$0D,$0C,$CE,$DD,$1B,$08,$F2,$D2,$B4,$D4,$80,$EA,$00,$DD,$1A;0DADF8|        |
                       db $DE,$EB,$0E,$0E,$EB,$0C,$EC,$07,$ED,$00,$EE,$1A,$05,$F2,$E2,$D2;0DAE08|        |
                       db $C0,$D4,$00,$EA,$25,$E4,$03,$0A,$F2,$E2,$D2,$AC,$D4,$FF,$EA,$25;0DAE18|        |
                       db $E4,$04,$CF,$0A,$D2,$22,$D3,$24,$10,$F0,$02,$28,$F1,$D3,$34,$00;0DAE28|        |
                       db $F0,$04,$28,$F1,$F2,$D2,$B4,$D4,$80,$EA,$00,$DD,$1C,$DE,$EB,$08;0DAE38|        |
                       db $EC,$07,$ED,$00,$EE,$17,$08,$F2,$D2,$A0,$D4,$80,$EA,$02,$E4,$00;0DAE48|        |
                       db $EB,$08,$EC,$07,$ED,$00,$EE,$1F,$D6,$1C,$9B,$08,$F2,$D2,$90,$D4;0DAE58|        |
                       db $80,$EA,$00,$DE,$EB,$0F,$EC,$07,$ED,$00,$EE,$12,$F0,$00,$DD,$1C;0DAE68|        |
                       db $0E,$DD,$17,$0E,$F1,$F2,$D2,$47,$D4,$80,$EA,$0B,$E4,$05,$EB,$08;0DAE78|        |
                       db $D6,$FE,$CC,$69,$F2,$D2,$4B,$D4,$80,$E4,$05,$EB,$0F,$E6,$EA,$04;0DAE88|        |
                       db $D7,$00,$05,$7F,$D6,$18,$DC,$07,$F2,$D2,$99,$D4,$80,$EA,$0A,$E4;0DAE98|        |
                       db $05,$DE,$EB,$0F,$EC,$04,$ED,$00,$EE,$1D,$DD,$14,$93,$EA,$07,$EC;0DAEA8|        |
                       db $05,$ED,$00,$EE,$05,$DF,$D7,$04,$14,$AC,$D2,$FF,$E4,$03,$0E,$E4;0DAEB8|        |
                       db $03,$08,$F2,$D2,$97,$D4,$80,$EA,$00,$E4,$05,$DE,$DD,$14,$EB,$0F;0DAEC8|        |
                       db $EC,$04,$ED,$00,$EE,$00,$D3,$39,$00,$05,$F2,$D2,$FF,$D4,$80,$EA;0DAED8|        |
                       db $07,$E4,$05,$EB,$0F,$EC,$02,$ED,$00,$EE,$0D,$D7,$00,$0C,$64,$D6;0DAEE8|        |
                       db $05,$D5,$04,$F2,$E2,$D2,$00,$D4,$40,$E4,$00,$EA,$00,$DE,$F0,$00;0DAEF8|        |
                       db $D3,$CC,$20,$DD,$19,$00,$D3,$CC,$05,$DD,$19,$B4,$B8,$F1,$F2,$E2;0DAF08|        |
                       db $D2,$00,$D4,$C0,$E4,$00,$EA,$00,$DE,$C5,$F0,$00,$D3,$C0,$1C,$DD;0DAF18|        |
                       db $19,$00,$D3,$CC,$04,$DD,$19,$B4,$B8,$D3,$DC,$20,$DD,$19,$02,$D3;0DAF28|        |
                       db $E0,$05,$DD,$19,$B4,$F1,$F2,$D2,$FF,$D4,$80,$EA,$00,$DE,$DD,$1A;0DAF38|        |
                       db $EB,$07,$EC,$07,$ED,$01,$EE,$0C,$08,$DD,$1A,$EB,$0F,$EC,$05,$ED;0DAF48|        |
                       db $00,$EE,$11,$BE,$DD,$17,$BE,$F2,$D2,$DC,$D4,$80,$EA,$0B,$E4,$06;0DAF58|        |
                       db $EB,$07,$EC,$03,$ED,$00,$EE,$08,$D7,$00,$04,$FF,$D6,$F8,$6D,$05;0DAF68|        |
                       db $F2,$D2,$E3,$D4,$80,$EA,$05,$E4,$02,$D7,$18,$00,$FC,$E4,$10,$D6;0DAF78|        |
                       db $F4,$C4,$04,$D6,$23,$FF,$BB,$D7,$00,$14,$50,$E4,$07,$EA,$07,$EB;0DAF88|        |
                       db $0F,$EC,$00,$ED,$00,$EE,$19,$D7,$00,$01,$FB,$D6,$A8,$C0,$D2,$54;0DAF98|        |
                       db $7D,$F2,$D2,$45,$D4,$80,$EA,$05,$E4,$03,$DE,$EB,$06,$F0,$01,$DD;0DAFA8|        |
                       db $17,$0C,$DD,$18,$C0,$DD,$19,$C0,$DD,$1A,$C0,$DD,$1B,$C0,$DD,$1C;0DAFB8|        |
                       db $C0,$DD,$1D,$C0,$DD,$1E,$C0,$F1,$EB,$0F,$EE,$0E,$DD,$1F,$C0,$DD;0DAFC8|        |
                       db $13,$C0,$D3,$3C,$28,$DD,$19,$02,$F2,$D2,$F0,$D4,$80,$EA,$00,$DE;0DAFD8|        |
                       db $EB,$0F,$EC,$02,$ED,$04,$EE,$11,$DD,$11,$0E,$DD,$11,$05,$F2,$D2;0DAFE8|        |
                       db $FF,$D4,$80,$EA,$07,$E4,$04,$EB,$0F,$EC,$02,$ED,$00,$EE,$0D,$D7;0DAFF8|        |
                       db $00,$0C,$64,$D6,$05,$D5,$04,$F2,$D2,$BE,$D4,$80,$EA,$00,$DE,$F0;0DB008|        |
                       db $04,$DD,$1A,$0C,$DD,$12,$0C,$EB,$0C,$EC,$02,$ED,$00,$EE,$0C,$0A;0DB018|        |
                       db $EF,$F1,$F2,$D2,$BE,$D4,$80,$EA,$0A,$F0,$04,$E4,$08,$D6,$10,$90;0DB028|        |
                       db $0A,$EB,$0C,$EC,$07,$ED,$00,$EE,$1F,$D6,$10,$B5,$0A,$EF,$F1,$F2;0DB038|        |
                       db $D2,$DC,$D4,$80,$EA,$04,$E4,$03,$D7,$00,$18,$7C,$0A,$E4,$02,$D6;0DB048|        |
                       db $5C,$D8,$B9,$F2,$D2,$98,$D4,$80,$EA,$05,$E4,$03,$DE,$EB,$03,$DD;0DB058|        |
                       db $1D,$0C,$DD,$1C,$C0,$DD,$1B,$C0,$DD,$1A,$C0,$DD,$19,$C0,$DD,$18;0DB068|        |
                       db $C0,$DD,$17,$C0,$DD,$16,$C0,$DD,$17,$C0,$DD,$18,$D3,$34,$00,$B9;0DB078|        |
                       db $F2,$E2,$D2,$FF,$D4,$A4,$EA,$0A,$E4,$0E,$D7,$00,$05,$FC,$E4,$01;0DB088|        |
                       db $D6,$94,$8F,$04,$D6,$94,$8F,$4E,$EA,$0A,$E4,$03,$D7,$00,$01,$7F;0DB098|        |
                       db $0E,$D6,$FF,$FB,$E4,$04,$00,$D2,$FF,$D3,$54,$00,$D7,$00,$02,$7F;0DB0A8|        |
                       db $B6,$F2,$E2,$D2,$F0,$D4,$67,$EA,$0B,$E4,$00,$D7,$00,$02,$FC,$D6;0DB0B8|        |
                       db $94,$8F,$04,$D7,$00,$02,$FC,$03,$0E,$D7,$0C,$00,$F8,$DE,$DD,$14;0DB0C8|        |
                       db $D2,$45,$D3,$E8,$00,$00,$B6,$F2                                 ;0DB0D8| End music data |

; ===========================================================================
; BANK PADDING - $FF Bytes to End of Bank
; ===========================================================================
; Unused space in Bank $0D filled with $FF (standard SNES ROM padding).
; Starts at $0DB0E0, continues to $0DBDAD (3,278 bytes).

                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB0E8| Padding block start |
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB0F8|        |
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB108| (Extensive $FF padding) |
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB118| Lines 0DB0E8-0DBDA7 |
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB128| All $FF bytes |
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB138| (Omitted for brevity) |
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB148|        |
                       db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF;0DB158|        |
; ... [3,200+ bytes of $FF padding omitted - continues through 0DBDA7] ...
                       db $FF,$FF,$FF,$FF,$FF,$FF           ;0DBDA8| Padding end |

; ===========================================================================
; UNREACHABLE DATA - Post-Padding Lookup Tables
; ===========================================================================
; These tables appear after the $FF padding, possibly leftover from development
; or used by dynamic code/data loading mechanisms.

UNREACH_0DBDAE:        db $0D                               ;0DBDAE| Unknown table entry |
UNREACH_0DBDAF:        db $85                               ;0DBDAF|        |
UNREACH_0DBDB0:        db $0E                               ;0DBDB0| More entries |
                       db $73,$85,$0E,$69,$8B,$0E           ;0DBDB1|        |
                       db $21,$93,$0E                       ;0DBDB7| Pattern: 2-byte pairs |
                       db $74,$9B,$0E,$0B,$9E,$0E,$88,$9F,$0E,$9B,$A2,$0E,$4F,$A8,$0E,$4F;0DBDBA|        |
                       db $AE,$0E,$0C,$B2,$0E,$04,$B5,$0E,$79,$B7,$0E,$2E,$BF,$0E,$F8,$C2;0DBDCA|        |
                       db $0E,$43,$C7,$0E,$41,$CC,$0E,$51,$D1,$0E,$03,$DA,$0E,$42,$DF,$0E;0DBDDA|        |
                       db $10,$E4,$0E,$10,$E8,$0E,$C2,$E8,$0E,$AB,$EA,$0E,$DD,$EE,$0E;0DBDEA|        |
                       db $73,$F4,$0E                       ;0DBDF9| Possibly 16-bit pointers |
                       db $D3,$FB,$0E                       ;0DBDFC| Ends at 0DBDFE |

; ===========================================================================
; DATA8_0DBDFF - Music/SFX Data Pointer Tables
; ===========================================================================
; 24-bit pointers (bank:address) to music and SFX pattern data.
; Format: [bank_byte, addr_low, addr_high] for each entry.
; Used by music loader to locate track data in ROM.

DATA8_0DBDFF:          db $01                               ;0DBDFF| Bank byte for entry 0 |
DATA8_0DBE00:          db $C2                               ;0DBE00| Address low byte |
DATA8_0DBE01:          db $0D,$21,$C8,$0D,$2E,$CC,$0D,$08,$E8,$0D,$FF,$F5,$0D,$5D,$FA,$0D;0DBE01| Music track pointers 0-5 |
                       db $FB,$00,$0E,$30,$0D,$0E,$16,$14,$0E,$4E,$14,$0E,$06,$22,$0E,$65;0DBE11| Music track pointers 6-11 |
                       db $31,$0E,$A2,$4D,$0E,$84,$55,$0E,$C4,$5C,$0E,$6E,$69,$0E,$4A,$77;0DBE21| Music track pointers 12-17 |
                       db $0E,$F3,$81,$0E                   ;0DBE31| Music track pointers 18-19 |

; ===========================================================================
; DATA8_0DBE35 - Track Length/Size Table
; ===========================================================================
; 16-bit size values for each music/SFX track (bytes to upload to SPC700).
; Used to calculate memory requirements and transfer sizes.

DATA8_0DBE35:          db $DF,$05,$0B,$04,$26,$0D,$36,$09,$D5,$03,$81,$06,$FE,$04,$C9,$06;0DBE35| Track sizes 0-7 |
                       db $1B,$00,$A8,$0C,$7D,$07,$1B,$00,$59,$07,$FF,$06,$21,$0C,$A9,$05;0DBE45| Track sizes 8-15 |
                       db $C1,$08,$18,$03                   ;0DBE55| Track sizes 16-17 |

; ===========================================================================
; DATA8_0DBE59 - Track Type/Flags Table
; ===========================================================================
; Configuration flags for each track (looping, priority, channel assignment).
; $00 = no loop, $80 = loop enabled, $CD = special behavior, $EF = extended.

DATA8_0DBE59:          db $EF,$00,$00,$00,$80,$00,$80,$00,$80,$00,$CD,$00,$00,$00,$CD,$00;0DBE59| Track flags 0-7 |
                       db $CD,$00,$00,$00,$00,$00,$E4,$00,$80,$00,$EF,$00,$00,$00,$00,$00;0DBE69| Track flags 8-15 |
                       db $80,$00,$00,$00                   ;0DBE79| Track flags 16-17 |

; ===========================================================================
; DATA8_0DBE7D - DSP ADSR Configuration Values
; ===========================================================================
; ADSR envelope bytes for different instrument types.
; Format: 2 bytes per instrument [ADSR1, ADSR2].
; Controls attack rate, decay rate, sustain level, release rate.

DATA8_0DBE7D:          db $FF,$CB,$FF,$DC,$FF,$E0,$FF,$E0,$9F,$40,$8F,$84,$FF,$18,$8F,$A4;0DBE7D| ADSR values 0-7 |
                       db $FF,$84,$CF,$68,$8F,$B8,$A7,$C0,$FF,$D4,$9F,$A4,$BF,$AC,$AF,$11;0DBE8D| ADSR values 8-15 |
                       db $FF,$B2,$FF,$E0                   ;0DBE9D| ADSR values 16-17 |

; ===========================================================================
; UNREACH_0DBEA1 - Channel Pattern Assignment Tables
; ===========================================================================
; Maps music patterns to 8 SPC700 hardware voices.
; Each row: 16 entries (one per virtual channel).
; Zero-padded entries = unused channels for this track.

UNREACH_0DBEA1:        db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBEA1| Pattern map 0 (empty) |
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBEB1| Pattern map 1 (empty) |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$11,$00,$10,$00,$0A,$00,$0E,$00;0DBEC1| Pattern map 2 (8 channels) |
                       db $04,$00,$01,$00,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBED1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$09,$00,$10,$00,$0A,$00,$0E,$00;0DBEE1| Pattern map 3 |
                       db $04,$00,$0F,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBEF1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$11,$00,$09,$00,$0A,$00,$0E,$00;0DBF01| Pattern map 4 |
                       db $04,$00,$0C,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBF11|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$02,$00,$02,$00,$0A,$00,$0E,$00;0DBF21| Pattern map 5 |
                       db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBF31|        |
                       db $09,$00,$0B,$00,$09,$00,$09,$00,$11,$00,$10,$00,$0A,$00,$03,$00;0DBF41| Pattern map 6 |
                       db $0E,$00,$0C,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBF51|        |
                       db $02,$00,$0B,$00,$07,$00,$09,$00,$11,$00,$10,$00,$0A,$00,$03,$00;0DBF61| Pattern map 7 |
                       db $06,$00,$08,$00,$0E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBF71|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DBF81| Pattern map 8 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBF91|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$11,$00,$10,$00,$0A,$00,$09,$00;0DBFA1| Pattern map 9 |
                       db $04,$00,$0C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBFB1|        |
                       db $09,$00,$0B,$00,$09,$00,$09,$00,$11,$00,$09,$00,$0A,$00,$03,$00;0DBFC1| Pattern map 10 |
                       db $08,$00,$0C,$00,$0E,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBFD1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DBFE1| Pattern map 11 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DBFF1|        |
                       db $09,$00,$0B,$00,$09,$00,$09,$00,$11,$00,$10,$00,$0A,$00,$05,$00;0DC001| Pattern map 12 |
                       db $0E,$00,$0C,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC011|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$09,$00,$10,$00,$0A,$00,$08,$00;0DC021| Pattern map 13 |
                       db $04,$00,$0C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC031|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC041| Pattern map 14 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC051|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC061| Pattern map 15 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC071|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC081| Pattern map 16 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC091|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC0A1| Pattern map 17 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC0B1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC0C1| Pattern map 18 |
                       db $03,$00,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC0D1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC0E1| Pattern map 19 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC0F1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$05,$00,$0A,$00,$03,$00;0DC101| Pattern map 20 |
                       db $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC111|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$09,$00,$10,$00,$0A,$00,$09,$00;0DC121| Pattern map 21 |
                       db $04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC131|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$11,$00,$10,$00,$0A,$00,$03,$00;0DC141| Pattern map 22 |
                       db $0E,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC151|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC161| Pattern map 23 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC171|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$11,$00,$10,$00,$05,$00,$09,$00;0DC181| Pattern map 24 |
                       db $0C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC191|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$11,$00,$09,$00,$05,$00,$08,$00;0DC1A1| Pattern map 25 |
                       db $09,$00,$0C,$00,$0E,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC1B1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$11,$00,$09,$00,$09,$00,$03,$00;0DC1C1| Pattern map 26 |
                       db $09,$00,$0C,$00,$08,$00,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC1D1|        |
                       db $02,$00,$0B,$00,$07,$00,$0D,$00,$10,$00,$12,$00,$0C,$00,$01,$00;0DC1E1| Pattern map 27 |
                       db $0F,$00,$06,$00,$08,$00,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00;0DC1F1| (Last map entry) |

; ===========================================================================
; FINAL MUSIC SEQUENCE DATA BLOCK
; ===========================================================================
; Last block of actual music track data before tables.
; Contains note sequences, timing, envelope commands for final tracks.

                       db $1E,$06,$02,$00,$00,$00,$00,$00,$00,$00,$00,$86,$E3,$52,$FC,$FE;0DC201| Final music data |
                       db $EF,$CC,$25,$BA,$96,$FE,$EE,$FD,$0F,$91,$0E,$0C,$F0,$96,$01,$CE;0DC211|        |
                       db $0F,$F1,$FF,$1D,$43,$F0,$96,$D3,$1F,$3E,$35,$F3,$41,$4D,$D4,$96;0DC221|        |
                       db $1E,$FE,$E2,$ED,$13,$E1,$5F,$EB,$96,$A2,$62,$12,$32,$02,$1E,$1E;0DC231|        |
                       db $E5,$9A,$DC,$35,$3C,$F0,$F2,$12,$5E,$E1,$9A,$33,$1D,$E5,$01,$B2;0DC241|        |
                       db $6D,$1E,$31,$96,$BD,$CF,$2B,$DC,$E2,$EA,$EE,$D0,$96,$CC,$F9,$BD;0DC251|        |
                       db $E0,$BE,$1F,$3F,$D2,$96,$00,$FD,$F1,$D0,$32,$2E,$FD,$0E,$AA,$D2;0DC261|        |
                       db $1E,$00,$10,$D0,$30,$FC,$F3,$9A,$E0,$6B,$02,$D2,$1F,$DE,$43,$E2;0DC271|        |
                       db $AA,$F1,$2F,$12,$FF,$10,$30,$00,$04,$96,$62,$42,$52,$E3,$FF,$FD;0DC281|        |
                       db $21,$DE,$96,$ED,$2F,$CE,$C0,$FB,$0F,$0F,$C1,$9A,$ED,$0E,$13,$CD;0DC291|        |
                       db $31,$2C,$C3,$1E,$96,$CE,$1D,$DD,$E4,$4E,$EF,$0F,$AC,$A6,$ED,$ED;0DC2A1|        |
                       db $E0,$CC,$00,$00,$FE,$E0,$96,$00,$31,$04,$45,$4E,$05,$32,$22,$9A;0DC2B1|        |
                       db $21,$31,$20,$B3,$43,$1C,$26,$00,$9A,$13,$4E,$05,$0F,$3F,$33,$F1;0DC2C1|        |
                       db $D3,$96,$21,$0C,$D1,$FD,$EE,$FF,$E0,$00,$9A,$EE,$21,$FC,$F6,$0D;0DC2D1|        |
                       db $2F,$F1,$DF,$96,$01,$FB,$A1,$1F,$0F,$00,$CE,$FB,$9A,$C2,$2E,$DE;0DC2E1|        |
                       db $C2,$3D,$EF,$CE,$0F,$9A,$2F,$CF,$32,$BE,$0E,$2F,$F1,$DF,$9A,$12;0DC2F1|        |
                       db $50,$B0,$24,$1B,$14,$F2,$11,$96,$43,$44,$34,$31,$11,$43,$DD,$01;0DC301|        |
                       db $9A,$1F,$12,$00,$F1,$20,$1F,$14,$DD,$96,$01,$0F,$CD,$FF,$00,$23;0DC311|        |
                       db $EE,$22,$9A,$0D,$E1,$3F,$F3,$0C,$02,$FE,$ED,$9A,$22,$EE,$DF,$20;0DC321|        |
                       db $0E,$FC,$C2,$2E,$8A,$DA,$24,$FE,$CC,$1E,$E4,$CB,$DE,$96,$46,$32;0DC331|        |
                       db $23,$32,$32,$22,$13,$32,$9A,$21,$03,$1E,$F2,$40,$EF,$13,$00,$8A;0DC341|        |
                       db $40,$12,$D2,$5E,$D2,$45,$FC,$11,$96,$22,$FF,$0E,$DF,$23,$2F,$04;0DC351|        |
                       db $40,$8A,$12,$D1,$41,$2F,$D2,$40,$9D,$E1,$9A,$3E,$DF,$F0,$11,$0D;0DC361|        |
                       db $DF,$0F,$0E,$96,$DF,$13,$21,$10,$02,$42,$DD,$02,$8A,$0F,$01,$0F;0DC371|        |
                       db $30,$F1,$00,$14,$0D,$8A,$36,$3F,$93,$70,$0F,$D3,$3E,$13,$8A,$2E;0DC381|        |
                       db $D3,$3F,$DE,$25,$2B,$E5,$1E,$96,$0F,$01,$EC,$14,$1F,$02,$33,$21;0DC391|        |
                       db $8A,$1E,$E5,$21,$0D,$35,$EB,$DF,$20,$9A,$10,$CE,$10,$3F,$DF,$F0;0DC3A1|        |
                       db $0E,$E0,$9A,$1F,$03,$FB,$F2,$20,$CE,$01,$11,$8A,$0F,$04,$0F,$31;0DC3B1|        |
                       db $F0,$14,$1B,$27,$8A,$33,$ED,$34,$2F,$F2,$0E,$24,$1F,$8A,$FF,$44;0DC3C1|        |
                       db $DB,$13,$01,$D0,$5E,$C2,$86,$31,$BA,$BF,$20,$E1,$23,$55,$42,$8A;0DC3D1|        |
                       db $D1,$31,$FD,$25,$F0,$EB,$F1,$22,$8A,$D9,$C1,$33,$0B,$B2,$1C,$EF;0DC3E1|        |
                       db $DD,$8A,$16,$1B,$B0,$52,$ED,$CE,$21,$12,$8A,$12,$FF,$54,$DE,$34;0DC3F1|        |
                       db $2F,$D1,$75,$8A,$0E,$23,$11,$30,$1F,$F1,$51,$D0,$8A,$24,$2C,$C3;0DC401|        |
                       db $4D,$E4,$1D,$E1,$41,$8A,$BC,$0F,$20,$F0,$F0,$02,$2E,$BF,$8A,$21;0DC411|        |
                       db $FE,$F0,$22,$1D,$AD,$21,$1F,$9A,$CD,$02,$0F,$FF,$FF,$00,$EC,$F2;0DC421|        |
                       db $8A,$30,$DC,$02,$11,$DC,$F0,$F1,$31,$8A,$F1,$33,$0F,$13,$41,$DF;0DC431|        |
                       db $44,$23,$86,$54,$53,$46,$52,$FE,$F1,$FA,$B1,$7A,$2C,$F3,$3E,$C5;0DC441| End final data |
