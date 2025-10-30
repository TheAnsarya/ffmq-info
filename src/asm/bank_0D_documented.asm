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

